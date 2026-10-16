import Foundation
import Observation

/// Fallback used when the app is built without a Firebase configuration (GoogleService-Info.plist):
/// a single local account whose decks are kept in Application Support. No online play.
@MainActor
@Observable
final class LocalBackend: Backend {
    let isCloud = false
    private(set) var auth: AuthStatus = .loading
    private(set) var decks: [SavedDeck] = []
    private(set) var profile = Profile()
    var matches: MatchService? { nil }

    private struct Store: Codable { var decks: [SavedDeck] = []; var profile = Profile() }
    private var file: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("ruinaccord-local.json")
    }

    func start() {
        if let data = try? Data(contentsOf: file), let s = try? JSONDecoder().decode(Store.self, from: data) {
            decks = s.decks.filter { GameData.shared.cls($0.cls) != nil }
                .map { d -> SavedDeck in var d = d; d.cards = Decks.sanitize(d.cards, cls: d.cls); return d }
                .sorted { $0.t > $1.t }
            profile = s.profile
        }
        auth = .signedIn(AccountInfo(uid: "local", isAnonymous: true, name: nil))
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(Store(decks: decks, profile: profile)) { try? data.write(to: file, options: .atomic) }
    }

    func signInWithApple(_ payload: AppleCredentialPayload) async throws { throw BackendError.noOnline }
    func signInAsGuest() async throws { auth = .signedIn(AccountInfo(uid: "local", isAnonymous: true, name: nil)) }
    func signOut() throws {}
    func deleteAccount(reauth: AppleCredentialPayload?) async throws {
        decks = []; profile = Profile(); persist()
    }

    func save(_ deck: SavedDeck) async throws {
        decks.removeAll { $0.id == deck.id }
        decks.insert(deck, at: 0)
        persist()
    }
    func deleteDeck(id: String) async throws { decks.removeAll { $0.id == id }; persist() }
    func update(_ change: (inout Profile) -> Void) { change(&profile); persist() }
}
