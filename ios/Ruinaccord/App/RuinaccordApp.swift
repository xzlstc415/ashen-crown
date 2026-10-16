import SwiftUI

@main
struct RuinaccordApp: App {
    @State private var vm: GameVM

    init() {
        // Firebase when a real GoogleService-Info.plist is bundled, otherwise an on-device fallback (no online play).
        // `-local` forces the on-device backend (unsigned simulator builds have no keychain access for Firebase).
        let local = ProcessInfo.processInfo.arguments.contains("-local")
        let backend: Backend = FirebaseBackend.isConfigured && !local ? FirebaseBackend() : LocalBackend()
        backend.start()
        let vm = GameVM(backend: backend)
        DebugLaunch.apply(to: vm)
        _vm = State(initialValue: vm)
    }

    var body: some Scene {
        WindowGroup {
            RootView().environment(vm)
        }
    }
}

/// Launch arguments used by the UI smoke tests / screenshots:  -screen duel|build|gallery|online  -lang zh  -local  -autoplay
enum DebugLaunch {
    @MainActor static func apply(to vm: GameVM) {
        let args = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> String? { args.firstIndex(of: flag).flatMap { args[safe: $0 + 1] } }
        if let l = value("-lang").flatMap(Lang.init(rawValue:)) { vm.lang = l }
        guard let s = value("-screen") else { return }
        Task { @MainActor in
            // Wait for the account to be ready (pass -local with Firebase configured).
            for _ in 0..<50 where vm.backend.auth.account == nil { try? await Task.sleep(for: .milliseconds(100)) }
            switch s {
            case "duel":
                vm.q.cls = "mage"; vm.q.deck = GameData.shared.cls("mage")!.deck
                Decks.autoFill(&vm.q.deck, cls: "mage")
                vm.startQuick(.normal)
            case "camp": vm.pickClass("paladin")
            case "build": vm.openBuilder(cls: "warrior")
            case "gallery": vm.openGallery()
            case "online": vm.goOnline()
            case "decks": vm.goDecks()
            default: break
            }
            if args.contains("-autoplay") { await autoplay(vm) }
        }
    }

    /// Plays the player's side with simple choices through the same calls the UI makes (debug builds only).
    @MainActor static func autoplay(_ vm: GameVM) async {
        for _ in 0..<60 where vm.state == nil { try? await Task.sleep(for: .milliseconds(100)) }
        while let s = vm.state, !s.over {
            try? await Task.sleep(for: .milliseconds(700))
            guard let s = vm.state, s.turn == .p, !vm.busy, !s.over else { continue }
            if let p = vm.pending { if let t = p.valid.randomElement() { vm.tap(t) }; continue }
            let hand = s.p.hand
            if let i = hand.indices.first(where: { i in
                guard let c = GameData.shared.card(hand[i]) else { return false }
                return s.canPay(.p, c.id) && (!c.isMinion || s.p.board.count < DuelState.boardMax) && (c.fx?.tgt == nil || !s.targetsFor(.p, c.fx!.tgt!, c.fx!.cond).isEmpty)
            }) { vm.playHand(i); continue }
            if let m = s.p.board.first(where: s.canAttack) {
                vm.tap(m.id)
                try? await Task.sleep(for: .milliseconds(150))
                if let t = s.attackTargets(.p).randomElement() { vm.tap(t) }
                continue
            }
            if !vm.powerBlocked { vm.usePower(); continue }
            vm.endTurn()
        }
    }
}
