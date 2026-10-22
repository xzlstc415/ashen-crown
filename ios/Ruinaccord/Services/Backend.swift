import Foundation
import Observation

/// A deck saved to the player's account.
struct SavedDeck: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var cls: String
    var cards: [String]
    var t: Double           // last change, seconds since 1970 (sorts newest first)
    /// Chosen talents (missing on decks saved before talents existed).
    var tal: [String]? = nil

    var isComplete: Bool { cards.count == Decks.size && Decks.isValid(cards, cls: cls) }
    /// The talents this deck plays with: its own when valid, else the class's first preset.
    var talents: [String] {
        let gd = GameData.shared
        if let t = tal, gd.validTalents(cls, t) { return t }
        return gd.talentPreset(cls, 0)
    }
    static func newId() -> String { "d" + String(Int(Date().timeIntervalSince1970), radix: 36) + String(UInt32.random(in: 0...UInt32.max), radix: 36) }
}

/// Per-account preferences and lifetime record.
struct Profile: Codable, Hashable {
    var lang: String?
    var onlineDeck: String?
    var quickW = 0, quickL = 0
    var onlineW = 0, onlineL = 0
    var campClears = 0
}

struct AccountInfo: Hashable {
    let uid: String
    let isAnonymous: Bool
    let name: String?
}

enum AuthStatus: Hashable {
    case loading
    case signedOut
    case signedIn(AccountInfo)
    var account: AccountInfo? { if case .signedIn(let a) = self { return a }; return nil }
}

/// Result of the native Sign in with Apple sheet, handed to the backend.
struct AppleCredentialPayload {
    let idToken: String
    let rawNonce: String
    let authorizationCode: String?
    let fullName: PersonNameComponents?
}

enum BackendError: LocalizedError {
    case notSignedIn, noOnline, needsApple, requiresRecentLogin, roomNotFound, roomTaken, versionMismatch, invalidDeck, timeout, cancelled, server(String)
    var errorDescription: String? {
        switch self {
        case .server(let s): return s
        default: return "\(self)"
        }
    }
}

/// Everything the game needs from "the cloud". `FirebaseBackend` is the real one; `LocalBackend`
/// keeps the app usable (offline, single player) when no Firebase configuration is bundled.
@MainActor
protocol Backend: AnyObject {
    /// True when accounts and decks live in a remote database and online play is available.
    var isCloud: Bool { get }
    var auth: AuthStatus { get }
    var decks: [SavedDeck] { get }
    var profile: Profile { get }

    func start()
    func signInWithApple(_ payload: AppleCredentialPayload) async throws
    func signInAsGuest() async throws
    func signOut() throws
    /// Deletes the account and its data. May throw `requiresRecentLogin`; the caller then re-authenticates and retries.
    func deleteAccount(reauth: AppleCredentialPayload?) async throws

    func save(_ deck: SavedDeck) async throws
    func deleteDeck(id: String) async throws
    func update(_ change: (inout Profile) -> Void)

    /// Online play; nil when not available.
    var matches: MatchService? { get }
}

/// Online match lifecycle. Implemented on Firestore.
@MainActor
protocol MatchService: AnyObject {
    /// Joins the random-opponent queue and returns once paired. Cancel the task to leave the queue.
    func findMatch(deck: SavedDeck) async throws -> OnlineMatch
    /// Creates a room; `onCode` fires as soon as the code is reserved, the call returns when a friend joins.
    func createRoom(deck: SavedDeck, onCode: @escaping @MainActor (String) -> Void) async throws -> OnlineMatch
    func joinRoom(code: String, deck: SavedDeck) async throws -> OnlineMatch
}

// MARK: - Online match wire format

/// One move, mirrored to the opponent. Sides are relative to the sender ("me"/"you").
struct NetRef: Codable, Hashable {
    var s: String   // "me" | "you"
    var u: Int?     // minion uid, nil for the hero
}

struct NetAct: Codable, Hashable {
    var n: Int                  // global move number
    var t: String               // play cast bc power atk end concede
    var i: Int?                 // hand index
    var k: String?              // card key
    var a: Int?                 // attacker uid
    var tgt: NetRef?
}

/// The shared match document. `state` is always stored from the host's point of view (p = host, e = guest).
struct MatchDoc: Codable {
    var players: [String]
    var h: String
    var g: String
    var hc: String
    var gc: String
    var hDeck: [String]
    var gDeck: [String]
    var hTal: [String]? = nil
    var gTal: [String]? = nil
    var v: String
    var game: Int
    var state: DuelState?
    var seq: Int
    var acts: [NetAct]
    var actsBy: String?
    var again: [String: Bool]
    var left: String?
    var beat: [String: Double]      // epoch seconds, written by each client
    var mull: [String: [Int]]? = nil   // opening mulligan: hand indices each player replaces
    var createdAt: Double
    var updatedAt: Double
}

/// A live connection to one match document. The game view model drives it; it never touches the UI.
@MainActor
@Observable
final class OnlineMatch {
    enum Role { case host, guest }
    let id: String
    let role: Role
    let myUid: String
    let foeUid: String
    var doc: MatchDoc?
    var lostConnection = false

    let _send: (_ state: DuelState, _ acts: [NetAct], _ seq: Int, _ turnHost: Bool) async throws -> Void
    let _reset: (_ state: DuelState) async throws -> Void
    let _again: () async throws -> Void
    let _leave: (Bool) async -> Void
    let _drop: (String) async -> Void
    let _beat: () async -> Void
    let _mull: ([Int]) async throws -> Void
    var onUpdate: ((MatchDoc) -> Void)?
    private var beatTask: Task<Void, Never>?

    init(id: String, role: Role, myUid: String, foeUid: String,
         send: @escaping (DuelState, [NetAct], Int, Bool) async throws -> Void,
         reset: @escaping (DuelState) async throws -> Void,
         again: @escaping () async throws -> Void,
         leave: @escaping (Bool) async -> Void,
         drop: @escaping (String) async -> Void,
         beat: @escaping () async -> Void,
         mull: @escaping ([Int]) async throws -> Void) {
        self.id = id; self.role = role; self.myUid = myUid; self.foeUid = foeUid
        _send = send; _reset = reset; _again = again; _leave = leave; _drop = drop; _beat = beat; _mull = mull
        beatTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?._beat()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    var isHost: Bool { role == .host }
    /// When this phone last saw the opponent do something (a heartbeat or a move), by this phone's clock.
    private var foeSeenAt = Date()
    func receive(_ d: MatchDoc) {
        let old = doc
        if old == nil || d.beat[foeUid] != old?.beat[foeUid] || (d.actsBy == foeUid && d.seq != old?.seq) || d.mull?[foeUid] != old?.mull?[foeUid] {
            foeSeenAt = Date()
        }
        doc = d
        onUpdate?(d)
    }
    func send(state: DuelState, acts: [NetAct], seq: Int, turnHost: Bool) async throws { try await _send(state, acts, seq, turnHost) }
    func resetGame(state: DuelState) async throws { try await _reset(state) }
    func askRematch() async throws { try await _again() }
    func sendMulligan(_ idx: [Int]) async throws { try await _mull(idx) }
    /// Stops listening; `announce` also tells the opponent we left (they win if the game is still on).
    func leave(announce: Bool = true) async { beatTask?.cancel(); await _leave(announce) }
    /// Records that the opponent timed out (they lose when they come back).
    func dropFoe() async { await _drop(foeUid) }
    /// Seconds since the opponent was last seen (heartbeats come every 10 s).
    var foeIdle: TimeInterval { Date().timeIntervalSince(foeSeenAt) }
}
