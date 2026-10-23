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
        // -signin: the sign-in screen, for a look at its layout
        if args.contains("-signin") { (vm.backend as? LocalBackend)?.debugSignOut() }
        guard let s = value("-screen") else { return }
        Task { @MainActor in
            // Wait for the account to be ready (pass -local with Firebase configured).
            for _ in 0..<50 where vm.backend.auth.account == nil { try? await Task.sleep(for: .milliseconds(100)) }
            switch s {
            case "duel":
                vm.q.cls = "mage"; vm.q.deck = GameData.shared.cls("mage")!.deck; vm.q.tal = GameData.shared.talentPreset("mage", 0)
                Decks.autoFill(&vm.q.deck, cls: "mage")
                vm.startQuick(.normal)
            case "camp": vm.pickClass("paladin")
            case "classes": vm.goNewDeck()
            case "newdeck": vm.openBuilder(cls: "mage"); vm.autoFill(); vm.toDifficulty()
            case "build": vm.openBuilder(cls: "warrior"); vm.go(.build); if let r = value("-rar") { vm.q.rarityFilter = r }
            case "qtalents":
                vm.q.cls = "mage"; vm.q.deck = GameData.shared.cls("mage")!.deck; vm.q.tal = GameData.shared.talentPreset("mage", 0)
                Decks.autoFill(&vm.q.deck, cls: "mage")
                vm.q.talNext = .diff; vm.go(.qtalents)
            case "gallery": vm.openGallery()
            case "online": vm.goOnline()
            case "decks": vm.goDecks()
            default: break
            }
            // -card <key>: put a card in hand and on both boards; -zoom <key>: open its large view (art checks).
            // The opening mulligan is confirmed (keeping the hand) unless -mull asks to see it.
            if vm.state?.mulligan == true && !args.contains("-mull") { vm.confirmMulligan() }
            // -choice: the Graveyard Summoner's offer, for a look at the dialog
            if args.contains("-choice"), vm.state != nil { vm.choice = Choice(offer: ["goblin", "golem", "ogre", "treant", "eel"], n: 2) }
            // -missiles: aim Arcane Missiles (with -card missiles,...) and pick the enemy hero n times (-picks n)
            if args.contains("-missiles"), vm.state != nil {
                Task {
                    try? await Task.sleep(for: .milliseconds(1200))
                    if let i = vm.state?.p.hand.firstIndex(of: "missiles") { vm.state?.p.mana = 1; vm.peekHand(); vm.playHand(i) }
                    for _ in 0..<(value("-picks").flatMap(Int.init) ?? 1) { try? await Task.sleep(for: .milliseconds(500)); vm.tap(.hero(.e)) }
                }
            }
            // -tapfoe: tap the first enemy minion once (with -card ogre,...), for the info panel
            if args.contains("-tapfoe"), vm.state != nil { Task { try? await Task.sleep(for: .milliseconds(1500)); if let m = vm.state?.e.board.first { vm.tapMinion(m.id, key: m.key) } } }
            if args.contains("-shatter"), vm.state != nil { Task { try? await Task.sleep(for: .seconds(2)); vm.debugShatter() } }
            if args.contains("-rite"), vm.state != nil { vm.state?.p.rites = 3; vm.choice = Choice(offer: vm.state!.riteOffer(), n: 1, rite: true) }
            // -fatigue: your deck is empty and you are at 1 health, then the turn ends (the fatigue draw must end the game)
            if args.contains("-fatigue"), vm.state != nil {
                vm.state?.p.deck = []; vm.state?.p.hp = 1; vm.state?.turn = .p
                Task { try? await Task.sleep(for: .seconds(1)); vm.endTurn() }
            }
            // -card a,b,c: these cards go in your hand; minions among them also on both boards
            if let ks = value("-card"), vm.state != nil {
                try? await Task.sleep(for: .milliseconds(600))
                for k in ks.split(separator: ",").map(String.init) where GameData.shared.card(k) != nil {
                    vm.state?.p.hand.insert(k, at: 0)
                    if GameData.shared.card(k)?.isMinion == true { vm.state?.summon(.p, k); vm.state?.summon(.e, k) }
                }
                let extra = (vm.state?.p.hand.count ?? 0) - 10
                if extra > 0 { vm.state?.p.hand.removeLast(extra) }
            }
            if let k = value("-zoom"), GameData.shared.card(k) != nil { vm.zoomCard = k }
            // -sel <n>: lift that hand card
            if let n = value("-sel").flatMap(Int.init) { vm.hsel = n }
            // -dragtest (with -card frostbolt,goblin,berserker): drive the drag-and-drop calls the hand and board make.
            if args.contains("-dragtest"), vm.state != nil { await dragTest(vm) }
            // -log: open the battle log panel (after -autoplay it has entries)
            if args.contains("-log") { vm.showLog = true }
            // -quittest: end the turn, leave in the middle of the AI's turn, then start a new game
            if args.contains("-quittest") {
                for round in 0..<3 {
                    try? await Task.sleep(for: .milliseconds(900))
                    vm.endTurn()
                    try? await Task.sleep(for: .milliseconds(1200 + round * 500))
                    vm.quitDuel(); vm.quitDuel()
                    print("quittest \(round): screen \(vm.screen) over \(vm.state?.over ?? false)")
                    try? await Task.sleep(for: .milliseconds(3500))
                    vm.q.cls = "mage"; vm.q.deck = GameData.shared.cls("mage")!.deck; Decks.autoFill(&vm.q.deck, cls: "mage"); vm.startQuick(.normal)
                    vm.confirmMulligan()
                }
                print("quittest done: screen \(vm.screen)")
            }
            if args.contains("-autoplay") { await autoplay(vm) }
        }
    }

    /// Drops a minion on the board, a spell on the enemy hero, drags an attack and the hero power; prints what happened.
    @MainActor static func dragTest(_ vm: GameVM) async {
        func c(_ r: CGRect?) -> CGPoint { r.map { CGPoint(x: $0.midX, y: $0.midY) } ?? .zero }
        // The enemy may go first: wait for your turn.
        for _ in 0..<100 where !(vm.state?.turn == .p && !vm.busy) { try? await Task.sleep(for: .milliseconds(100)) }
        try? await Task.sleep(for: .seconds(1))
        vm.state?.p.mana = 10
        if let i = vm.state?.p.hand.firstIndex(of: "goblin") {
            let p = c(vm.boardFrames[.p])
            vm.dragHand(i, to: p, line: p.y + 60)
            print("dragtest minion: aboveLine \(vm.drag?.aboveLine ?? false) glow \(vm.dropGlow)")
            vm.dropHand(i)
            try? await Task.sleep(for: .seconds(1.3))
            print("dragtest minion: board \(vm.state?.p.board.count ?? -1) hand has goblin \(vm.state?.p.hand.contains("goblin") ?? true)")
        }
        if let i = vm.state?.p.hand.firstIndex(of: "frostbolt") {
            vm.state?.e.armor = 0; vm.state?.e.hp = 30      // talents may have changed both
            let p = c(vm.frames[.hero(.e)])
            vm.dragHand(i, to: p, line: p.y + 60)
            print("dragtest spell: over \(String(describing: vm.drag?.over)) valid \(vm.drag?.valid.count ?? 0)")
            vm.dropHand(i)
            try? await Task.sleep(for: .seconds(1.6))
            print("dragtest spell: enemy hp \(vm.state?.e.hp ?? -1) (expect 26) pending \(vm.pending != nil)")
        }
        if let m = vm.state?.p.board.first(where: { $0.key == "berserker" }), let t = vm.state?.e.board.first(where: { $0.key == "goblin" }) {
            vm.dragMinion(m.id, to: c(vm.frames[t.id]))
            print("dragtest attack: over \(String(describing: vm.drag?.over)) arrow \(vm.arrowFrom != nil)")
            print("dragtest attack: busy \(vm.busy) sel \(String(describing: vm.sel)) foe board \(vm.state?.e.board.map { "\($0.uid):\($0.key)" } ?? [])")
            vm.dropMinion()
            try? await Task.sleep(for: .seconds(1.2))
            print("dragtest attack: enemy goblin alive \(vm.state?.e.board.contains { $0.key == "goblin" } ?? true) attacked \(vm.state?.minion(m.id)?.attacked ?? false) log '\(vm.logText())' my board \(vm.state?.p.board.map { "\($0.uid):\($0.key)" } ?? [])")
        }
        if vm.curPower.tgt != nil {
            let hp = vm.state?.e.hp ?? 0
            vm.dragPower(to: c(vm.frames[.hero(.e)]))
            print("dragtest power: over \(String(describing: vm.drag?.over))")
            vm.dropPower()
            try? await Task.sleep(for: .seconds(1.2))
            print("dragtest power: enemy hp \(hp) -> \(vm.state?.e.hp ?? -1) used \(vm.state?.p.powerUsed ?? false)")
        }
        print("dragtest done")
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
