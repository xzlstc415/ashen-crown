import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Accounts (Sign in with Apple / guest) in Firebase Auth, decks and profile in Firestore.
///   users/{uid}              Profile
///   users/{uid}/decks/{id}   SavedDeck
@MainActor
@Observable
final class FirebaseBackend: Backend {
    let isCloud = true
    private(set) var auth: AuthStatus = .loading
    private(set) var decks: [SavedDeck] = []
    private(set) var profile = Profile()
    private(set) var matches: MatchService?

    private let db: Firestore
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var deckListener: ListenerRegistration?
    private var profileListener: ListenerRegistration?

    /// True when a real GoogleService-Info.plist is bundled (the .example file is excluded from the build).
    static var isConfigured: Bool {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url), let pid = dict["PROJECT_ID"] as? String else { return false }
        return !pid.isEmpty && !pid.contains("your-project")
    }

    init() {
        FirebaseApp.configure()
        db = Firestore.firestore()
        matches = FirebaseMatchService(db: db, backend: self)
    }

    func start() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let info = user.map { AccountInfo(uid: $0.uid, isAnonymous: $0.isAnonymous, name: $0.displayName) }
            Task { @MainActor in self?.userChanged(info) }
        }
    }

    private func users(_ uid: String) -> DocumentReference { db.collection("users").document(uid) }

    private func userChanged(_ info: AccountInfo?) {
        deckListener?.remove(); profileListener?.remove()
        decks = []; profile = Profile()
        guard let info else { auth = .signedOut; return }
        auth = .signedIn(info)
        deckListener = users(info.uid).collection("decks").addSnapshotListener { [weak self] snap, _ in
            guard let snap else { return }
            let list = snap.documents.compactMap { try? $0.data(as: SavedDeck.self) }
                .filter { GameData.shared.cls($0.cls) != nil && Decks.isValid($0.cards, cls: $0.cls) }
                .sorted { $0.t > $1.t }
            Task { @MainActor in self?.decks = list }
        }
        profileListener = users(info.uid).addSnapshotListener { [weak self] snap, _ in
            guard let snap, snap.exists, let p = try? snap.data(as: Profile.self) else { return }
            Task { @MainActor in self?.profile = p }
        }
    }

    // MARK: Auth

    func signInWithApple(_ p: AppleCredentialPayload) async throws {
        let cred = OAuthProvider.appleCredential(withIDToken: p.idToken, rawNonce: p.rawNonce, fullName: p.fullName)
        if let user = Auth.auth().currentUser, user.isAnonymous {
            // Upgrade the guest account so its decks come along.
            let guestDecks = decks, guestProfile = profile
            do {
                _ = try await user.link(with: cred)
                return
            } catch let e as NSError where e.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                // This Apple ID already has an account: sign in to it and copy the guest decks over.
                let useCred = (e.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential) ?? cred
                let result = try await Auth.auth().signIn(with: useCred)
                for d in guestDecks { try? users(result.user.uid).collection("decks").document(d.id).setData(from: d) }
                if guestProfile != Profile() { try? users(result.user.uid).setData(from: guestProfile, merge: true) }
                return
            }
        }
        _ = try await Auth.auth().signIn(with: cred)
    }

    func signInAsGuest() async throws { _ = try await Auth.auth().signInAnonymously() }

    func signOut() throws { try Auth.auth().signOut() }

    func deleteAccount(reauth: AppleCredentialPayload?) async throws {
        guard let user = Auth.auth().currentUser else { throw BackendError.notSignedIn }
        if let r = reauth {
            let cred = OAuthProvider.appleCredential(withIDToken: r.idToken, rawNonce: r.rawNonce, fullName: r.fullName)
            _ = try await user.reauthenticate(with: cred)
            // Apple requires the sign-in token to be revoked when an account is deleted.
            if let code = r.authorizationCode { try? await Auth.auth().revokeToken(withAuthorizationCode: code) }
        } else if !user.isAnonymous, let last = user.metadata.lastSignInDate, Date().timeIntervalSince(last) > 240 {
            throw BackendError.requiresRecentLogin
        }
        let uid = user.uid
        let snap = try await users(uid).collection("decks").getDocuments()
        let batch = db.batch()
        snap.documents.forEach { batch.deleteDocument($0.reference) }
        batch.deleteDocument(users(uid))
        batch.deleteDocument(db.collection("queue").document(uid))
        try await batch.commit()
        do {
            try await user.delete()
        } catch let e as NSError where e.code == AuthErrorCode.requiresRecentLogin.rawValue {
            throw BackendError.requiresRecentLogin
        }
    }

    // MARK: Decks & profile

    func save(_ deck: SavedDeck) async throws {
        guard let uid = auth.account?.uid else { throw BackendError.notSignedIn }
        decks.removeAll { $0.id == deck.id }
        decks.insert(deck, at: 0)
        try users(uid).collection("decks").document(deck.id).setData(from: deck)
    }

    func deleteDeck(id: String) async throws {
        guard let uid = auth.account?.uid else { throw BackendError.notSignedIn }
        decks.removeAll { $0.id == id }
        try await users(uid).collection("decks").document(id).delete()
    }

    func update(_ change: (inout Profile) -> Void) {
        change(&profile)
        guard let uid = auth.account?.uid else { return }
        try? users(uid).setData(from: profile, merge: true)
    }
}

// MARK: - Online matches

/// Random matchmaking and room codes on Firestore, no server needed:
///   queue/{uid}     a waiting player (cls, deck, v, state, createdAt/updatedAt epoch seconds)
///   rooms/{code}    an open friend room
///   matches/{id}    the shared game (MatchDoc)
/// Pairing happens in a transaction so two players cannot both claim the same ticket.
@MainActor
final class FirebaseMatchService: MatchService {
    private let db: Firestore
    private unowned let backend: FirebaseBackend
    private var version: String { GameData.shared.rulesVersion }
    private var now: Double { Date().timeIntervalSince1970 }

    init(db: Firestore, backend: FirebaseBackend) { self.db = db; self.backend = backend }

    private func me() throws -> String {
        guard let a = backend.auth.account else { throw BackendError.notSignedIn }
        guard !a.isAnonymous else { throw BackendError.needsApple }
        return a.uid
    }

    // MARK: Random opponent

    func findMatch(deck: SavedDeck) async throws -> OnlineMatch {
        let uid = try me()
        let ticket = db.collection("queue").document(uid)
        try await ticket.setData(["uid": uid, "cls": deck.cls, "deck": deck.cards, "v": version, "state": "waiting",
                                  "createdAt": now, "updatedAt": now])
        var lastRefresh = now
        do {
            while true {
                try Task.checkCancellation()
                // Did somebody pair with us?
                let mine = try await ticket.getDocument(source: .server)
                if mine.get("state") as? String == "matched", let id = mine.get("matchId") as? String {
                    try? await ticket.delete()
                    return try await open(id: id, uid: uid)
                }
                if !mine.exists { throw BackendError.cancelled }
                // Otherwise look for someone to pair with.
                let q = try await db.collection("queue")
                    .whereField("state", isEqualTo: "waiting").whereField("v", isEqualTo: version).limit(to: 10).getDocuments(source: .server)
                let cands = q.documents
                    .filter { $0.documentID != uid && ((($0.get("updatedAt") as? Double) ?? 0) > now - 90) }
                    .sorted { (($0.get("createdAt") as? Double) ?? 0) < (($1.get("createdAt") as? Double) ?? 0) }
                for cand in cands {
                    if let id = try await pair(myUid: uid, myDeck: deck, their: cand.reference) {
                        return try await open(id: id, uid: uid)
                    }
                }
                if now - lastRefresh > 20 { try? await ticket.updateData(["updatedAt": now]); lastRefresh = now }
                try await Task.sleep(for: .seconds(3))
            }
        } catch {
            try? await ticket.delete()
            throw error
        }
    }

    /// Tries to claim `their` ticket. Returns the match id when this client created the match, or when
    /// the other side already paired with us meanwhile; nil when the ticket was gone.
    private func pair(myUid: String, myDeck: SavedDeck, their: DocumentReference) async throws -> String? {
        let mine = db.collection("queue").document(myUid)
        let matchRef = db.collection("matches").document()
        let result = try await db.runTransaction { tx, err -> Any? in
            do {
                let m = try tx.getDocument(mine)
                if m.get("state") as? String == "matched", let id = m.get("matchId") as? String { return id }
                let t = try tx.getDocument(their)
                guard t.exists, t.get("state") as? String == "waiting",
                      let cls = t.get("cls") as? String, let cards = t.get("deck") as? [String],
                      GameData.shared.cls(cls) != nil, cards.count == Decks.size, Decks.isValid(cards, cls: cls) else { return nil }
                let theirUid = their.documentID
                let doc = self.initialDoc(h: myUid, hc: myDeck.cls, hDeck: myDeck.cards, g: theirUid, gc: cls, gDeck: cards)
                tx.setData(try Firestore.Encoder().encode(doc), forDocument: matchRef)
                tx.updateData(["state": "matched", "matchId": matchRef.documentID], forDocument: their)
                tx.deleteDocument(mine)
                return matchRef.documentID
            } catch let e {
                err?.pointee = e as NSError
                return nil
            }
        }
        return result as? String
    }

    // MARK: Friend rooms

    func createRoom(deck: SavedDeck, onCode: @escaping @MainActor (String) -> Void) async throws -> OnlineMatch {
        let uid = try me()
        var code = ""
        for _ in 0..<8 {
            let c = String(Int.random(in: 100000...999999))
            let ref = db.collection("rooms").document(c)
            let snap = try await ref.getDocument(source: .server)
            let fresh = snap.exists && snap.get("state") as? String == "open" && (((snap.get("updatedAt") as? Double) ?? 0) > now - 180)
            if fresh { continue }
            try await ref.setData(["host": uid, "cls": deck.cls, "deck": deck.cards, "v": version, "state": "open",
                                   "createdAt": now, "updatedAt": now])
            code = c
            break
        }
        guard !code.isEmpty else { throw BackendError.server("no room code available") }
        onCode(code)
        let ref = db.collection("rooms").document(code)
        var lastRefresh = now
        do {
            while true {
                try Task.checkCancellation()
                let snap = try await ref.getDocument(source: .server)
                guard snap.exists else { throw BackendError.cancelled }
                if snap.get("state") as? String == "matched", let id = snap.get("matchId") as? String {
                    try? await ref.delete()
                    return try await open(id: id, uid: uid)
                }
                if now - lastRefresh > 20 { try? await ref.updateData(["updatedAt": now]); lastRefresh = now }
                try await Task.sleep(for: .seconds(2))
            }
        } catch {
            try? await ref.delete()
            throw error
        }
    }

    func joinRoom(code: String, deck: SavedDeck) async throws -> OnlineMatch {
        let uid = try me()
        let room = db.collection("rooms").document(code)
        let matchRef = db.collection("matches").document()
        let result = try await db.runTransaction { tx, err -> Any? in
            do {
                let r = try tx.getDocument(room)
                guard r.exists, r.get("state") as? String == "open", let host = r.get("host") as? String,
                      let cls = r.get("cls") as? String, let cards = r.get("deck") as? [String] else { return "notfound" }
                if host == uid { return "notfound" }
                if r.get("v") as? String != self.version { return "version" }
                guard GameData.shared.cls(cls) != nil, cards.count == Decks.size, Decks.isValid(cards, cls: cls) else { return "deck" }
                let doc = self.initialDoc(h: uid, hc: deck.cls, hDeck: deck.cards, g: host, gc: cls, gDeck: cards)
                tx.setData(try Firestore.Encoder().encode(doc), forDocument: matchRef)
                tx.updateData(["state": "matched", "matchId": matchRef.documentID, "updatedAt": self.now], forDocument: room)
                return matchRef.documentID
            } catch let e {
                err?.pointee = e as NSError
                return nil
            }
        }
        switch result as? String {
        case "notfound", nil: throw BackendError.roomNotFound
        case "version": throw BackendError.versionMismatch
        case "deck": throw BackendError.invalidDeck
        case let id?: return try await open(id: id, uid: uid)
        }
    }

    // MARK: Match documents

    private func initialDoc(h: String, hc: String, hDeck: [String], g: String, gc: String, gDeck: [String]) -> MatchDoc {
        MatchDoc(players: [h, g], h: h, g: g, hc: hc, gc: gc, hDeck: hDeck, gDeck: gDeck, v: version, game: 1,
                 state: DuelState.onlineStart(hostCls: hc, hostDeck: hDeck, guestCls: gc, guestDeck: gDeck),
                 seq: 0, acts: [], actsBy: nil, again: [:], left: nil, beat: [h: now, g: now], createdAt: now, updatedAt: now)
    }

    private func open(id: String, uid: String) async throws -> OnlineMatch {
        let ref = db.collection("matches").document(id)
        let first = try await ref.getDocument(source: .server)
        guard let doc = try? first.data(as: MatchDoc.self) else { throw BackendError.server("match unreadable") }
        let role: OnlineMatch.Role = doc.h == uid ? .host : .guest
        let foe = role == .host ? doc.g : doc.h
        var listener: ListenerRegistration?
        let match = OnlineMatch(id: id, role: role, myUid: uid, foeUid: foe,
            send: { state, acts, seq, turnHost in
                try await ref.updateData(["state": try Firestore.Encoder().encode(state), "acts": try Firestore.Encoder().encode(acts),
                                          "actsBy": uid, "seq": seq, "turnHost": turnHost, "updatedAt": Date().timeIntervalSince1970])
            },
            reset: { state in
                try await ref.updateData(["state": try Firestore.Encoder().encode(state), "acts": [], "actsBy": FieldValue.delete(), "seq": 0,
                                          "game": FieldValue.increment(Int64(1)), "again": [:], "left": FieldValue.delete(),
                                          "updatedAt": Date().timeIntervalSince1970])
            },
            again: { try await ref.updateData(["again.\(uid)": true]) },
            leave: { announce in
                listener?.remove()
                if announce { try? await ref.updateData(["left": uid, "updatedAt": Date().timeIntervalSince1970]) }
            },
            drop: { who in try? await ref.updateData(["left": who, "updatedAt": Date().timeIntervalSince1970]) },
            beat: { try? await ref.updateData(["beat.\(uid)": Date().timeIntervalSince1970]) })
        match.receive(doc)
        listener = ref.addSnapshotListener { snap, error in
            guard let snap else { Task { @MainActor in match.lostConnection = true }; return }
            if snap.metadata.hasPendingWrites { return }   // only the server's view
            guard let d = try? snap.data(as: MatchDoc.self) else { return }
            Task { @MainActor in match.receive(d) }
        }
        return match
    }
}
