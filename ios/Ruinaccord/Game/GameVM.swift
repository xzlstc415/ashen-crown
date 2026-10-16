import SwiftUI
import Observation

enum Screen: Hashable {
    case intro, classPick, duel, reward, lost, champ, decks, qclass, build, diff, qresult, gallery, online, oresult
}

struct Run {
    var stage = 0
    var deck: [String] = []
    var cls: String?
}

struct Pending {
    enum Kind { case spell(idx: Int), battlecry(fx: Effect, src: EID, hist: UUID?), power }
    var kind: Kind
    var valid: [EID]
    var key: String?
}

struct HistItem: Identifiable, Hashable {
    let id = UUID()
    let side: Side
    let key: String
    var target: NameRef?
    let round: Int
}

struct FloatFX: Identifiable { let id = UUID(); let eid: EID; let kind: FloatKind }
struct Banner: Equatable { let text: String; let foe: Bool }
struct Reveal: Identifiable { let id = UUID(); let side: Side; let key: String; var target: NameRef? }

enum FXItem: Identifiable {
    case orb(id: UUID, from: CGPoint, to: CGPoint, color: Color)
    case burst(id: UUID, at: CGPoint, color: Color)
    case spark(id: UUID, at: CGPoint, dx: CGFloat, dy: CGFloat, size: CGFloat)
    case wave(id: UUID, rect: CGRect)
    case fly(id: UUID, key: String, from: CGRect, to: CGPoint)
    var id: UUID {
        switch self {
        case .orb(let id, _, _, _), .burst(let id, _, _), .spark(let id, _, _, _, _), .wave(let id, _), .fly(let id, _, _, _): return id
        }
    }
}

struct Builder {
    var cls: String?
    var deck: [String] = []
    var diff: Difficulty = .normal
    var typeFilter = "all"
    var costFilter = 0
    var w = 0, l = 0
    var toast = ""
    var editId: String?
    var name = ""
    var dirty = false
    var delArm: String?
    var libToast = ""
    var returnToOnline = false
}

struct Online {
    enum Net: Equatable { case idle, searching(Int), hosting(String?), joining, live }
    var sel: String?
    var code = ""
    var err = ""
    var toast = ""
    var net: Net = .idle
    var concedeArm = false
    var w = 0, l = 0
    var lost: String?          // message key shown on the result screen
    var conceded = false
    var foeAgain = false
    var again = false
    var slow = false
}

/// Drives the whole game: screens, the duel loop with animations, the computer opponent and online sync.
@MainActor
@Observable
final class GameVM {
    let backend: Backend
    var lang: Lang
    var tx: Tx { Tx(lang: lang) }
    var reduceMotion = false

    var screen: Screen = .intro
    private var prevScreen: Screen = .intro
    var run = Run()
    var state: DuelState?
    var picks: [String] = []
    var q = Builder()
    var o = Online()
    var showSettings = false

    // Duel UI
    var log: LogEntry?
    var pending: Pending?
    var sel: Int?
    var busy = false
    var hist: [HistItem] = []
    var floats: [FloatFX] = []
    var hitTick: [EID: Int] = [:]
    var drewCount = 0
    var banner: Banner?
    var reveal: Reveal?
    var aimed: EID?
    var lungeOffset: [EID: CGSize] = [:]
    var fx: [FXItem] = []
    var hiddenHand: Int?
    var zoomCard: String?
    var peekItem: HistItem?
    var deaths: Set<EID> = []
    var lastEnemyMinion: (uid: Int, hist: UUID)?

    // Layout (reported by views)
    var frames: [EID: CGRect] = [:]
    var handFrames: [Int: CGRect] = [:]
    var boardFrames: [Side: CGRect] = [:]
    var powerFrame: CGRect?
    var epowFrame: CGRect?
    var revealFrame: CGRect?

    // Online
    var match: OnlineMatch?
    private var netOut: [NetAct] = []
    private var turnActs: [NetAct] = []
    private var netN = 0
    private var appliedN = 0
    private var seq = 0
    private var game = 0
    private var netQueue: [NetAct] = []
    private var pumping = false
    private var pendingDoc: MatchDoc?
    private var findTask: Task<Void, Never>?
    private var watchTask: Task<Void, Never>?

    init(backend: Backend) {
        self.backend = backend
        let saved = UserDefaults.standard.string(forKey: "lang").flatMap(Lang.init(rawValue:))
        lang = saved ?? Lang.system
    }

    // MARK: - Helpers

    var S: DuelState { get { state! } set { state = newValue } }
    var gd: GameData { GameData.shared }
    var decks: [SavedDeck] { backend.decks }
    var curPower: Power { gd.cls(run.cls ?? "")?.power ?? gd.fortify }
    var curClass: HeroClass? { gd.cls(run.cls ?? "") }
    var enemyClass: HeroClass? { state?.ecls.flatMap { gd.cls($0) } }

    func wait(_ ms: Int) async { try? await Task.sleep(for: .milliseconds(ms)) }

    func heroName(_ side: Side) -> String {
        if side == .p { return tx.className(run.cls ?? "") }
        guard let s = state else { return "" }
        switch s.mode {
        case .quick: return tx.aiName(tx.className(s.ecls ?? ""))
        case .online: return tx.foeName(tx.className(s.ecls ?? ""))
        case .camp: return tx.oppName(run.stage)
        }
    }
    func name(_ r: NameRef) -> String {
        switch r {
        case .hero(let s): return heroName(s)
        case .card(let k): return tx.cardName(k)
        }
    }
    func name(_ id: EID) -> String { state.map { name($0.name(id)) } ?? "" }

    func logText() -> String {
        guard let l = log else { return "" }
        let t = tx
        switch l {
        case .rises: return t.rises(heroName(.e))
        case .fatigue(let s, let n): return t.fatigue(heroName(s), n)
        case .handFull(let k): return t.handFull(t.cardName(k))
        case .summon(let k): return t.summon(t.cardName(k))
        case .cast(let k): return t.cast(t.cardName(k))
        case .castOn(let k, let r): return t.castOn(t.cardName(k), name(r))
        case .attacks(let a, let b): return t.attacks(name(a), name(b))
        case .burst(let k): return t.burst(t.cardName(k))
        case .sinks: return t.sinks(heroName(.e))
        case .falls: return t.falls
        case .noMana: return t.noMana
        case .boardFull: return t.boardFull
        case .noTargets: return t.noTargets
        case .ready(let k): return t.ready(t.cardName(k))
        case .already(let k): return t.already(t.cardName(k))
        case .noAtk(let k): return t.noAtk(t.cardName(k))
        case .nextTurn(let k): return t.nextTurn(t.cardName(k))
        case .guardWay: return t.guardWay
        case .info(let k, let a, let h): return t.info(t.cardName(k), a, h, gd.card(k).map(t.cardText) ?? "")
        case .eTurn: return t.eTurn(heroName(.e))
        case .eSummon(let k): return t.eSummon(heroName(.e), t.cardName(k))
        case .eCast(let k): return t.eCast(heroName(.e), t.cardName(k))
        case .eCastOn(let k, let r): return t.eCastOn(heroName(.e), t.cardName(k), name(r))
        case .yourTurn: return t.yourTurnLog
        case .goFirst: return t.goFirst
        case .goSecond: return t.goSecond
        case .powerUse(let p, let r): return t.powerUse(t.powerName(p), r.map(name))
        case .ePower(let p, let r): return t.ePower(heroName(.e), t.powerName(p), r.map(name))
        case .cantPower: return t.cantPower
        }
    }

    func floatText(_ k: FloatKind) -> (String, Color) {
        switch k {
        case .dmg(let n): return ("-\(n)", Theme.blood)
        case .armorAbsorb(let n): return (tx.fArmor(n), Color(white: 0.7))
        case .ward: return (tx.fWard, Theme.foam)
        case .heal(let n): return ("+\(n)", Theme.ready)
        case .armorGain(let n): return (tx.armorN(n), Color(hex: "#cfd8dc"))
        case .atkUp(let n): return (tx.fAtk(n), Theme.ready)
        case .hpUp(let n): return (tx.fHp(n), Theme.ready)
        case .frozen: return (tx.fFreeze, Theme.foam)
        case .silenced: return (tx.fSilence, Color(white: 0.7))
        case .destroyed: return (tx.fDestroy, Theme.blood)
        case .stats(let a, let h): return ("\(a)/\(h)", Color(hex: "#cfd8dc"))
        }
    }

    /// Moves rule events into UI state (log line, floating numbers, hit shakes, death fades).
    func drain() {
        guard state != nil else { return }
        let evs = S.events
        S.events = []
        for ev in evs {
            switch ev {
            case .log(let l): log = l
            case .drew(let s): if s == .p { drewCount += 1 }
            case .float(let id, let k):
                floats.append(FloatFX(eid: id, kind: k))
                if k.isHit && !reduceMotion { hitTick[id, default: 0] += 1 }
                let fid = floats.last!.id
                Task { await wait(900); floats.removeAll { $0.id == fid } }
            case .died(let m):
                if let f = frames[m.id] { sparks(at: CGPoint(x: f.midX, y: f.midY), n: 6) }
            }
        }
    }

    // MARK: - Navigation

    func setLang(_ l: Lang) {
        lang = l
        UserDefaults.standard.set(l.rawValue, forKey: "lang")
        backend.update { $0.lang = l.rawValue }
    }

    func go(_ s: Screen) { withAnimation(.easeOut(duration: 0.25)) { screen = s } }
    func newRun() { run = Run(); state = nil; pending = nil; sel = nil; hist = []; go(.intro) }
    func goMenu() { Task { await netClose() }; newRun() }
    func openGallery() { if screen != .gallery { prevScreen = screen; go(.gallery) } }
    func closeGallery() { go(prevScreen) }
    func goClass() { go(.classPick) }
    func goDecks() { q.delArm = nil; q.returnToOnline = false; q.libToast = ""; go(.decks) }
    func goNewDeck() { q.libToast = ""; go(.qclass) }

    // MARK: - Deck builder

    func nextDefaultName(_ cls: String) -> String { tx.defaultName(tx.className(cls), decks.filter { $0.cls == cls }.count + 1) }

    func openBuilder(cls: String?, id: String? = nil) {
        if let id, let d = decks.first(where: { $0.id == id }) {
            q.cls = d.cls; q.deck = d.cards; q.editId = d.id; q.name = d.name; q.dirty = false
        } else if let cls {
            q.cls = cls; q.deck = gd.cls(cls)?.deck ?? []; q.editId = nil; q.name = nextDefaultName(cls); q.dirty = true
        }
        q.toast = ""
        go(.build)
    }

    func addCard(_ k: String) {
        if q.deck.count >= Decks.size { q.toast = tx.deckFull }
        else if Decks.copies(q.deck, k) >= Decks.maxCopies(k) { q.toast = tx.limitHit }
        else { q.deck.append(k); q.toast = ""; q.dirty = true }
    }
    func removeCard(_ k: String) {
        if let i = q.deck.lastIndex(of: k) { q.deck.remove(at: i); q.dirty = true }
        q.toast = ""
    }
    func autoFill() { Decks.autoFill(&q.deck, cls: q.cls); q.toast = ""; q.dirty = true }
    func resetDeck() { q.deck = gd.cls(q.cls ?? "")?.deck ?? []; q.toast = ""; q.dirty = true }
    func clearDeck() { q.deck = []; q.toast = ""; q.dirty = true }

    func saveCurrent(asNew: Bool) {
        guard let cls = q.cls else { return }
        let name = q.name.trimmingCharacters(in: .whitespaces).isEmpty ? nextDefaultName(cls) : q.name.trimmingCharacters(in: .whitespaces)
        q.name = name
        var d: SavedDeck
        if !asNew, let id = q.editId, let ex = decks.first(where: { $0.id == id }) {
            d = ex; d.name = name; d.cards = q.deck; d.t = Date().timeIntervalSince1970
        } else {
            d = SavedDeck(id: SavedDeck.newId(), name: name, cls: cls, cards: q.deck, t: Date().timeIntervalSince1970)
            q.editId = d.id
        }
        q.dirty = false
        q.toast = tx.saved(name)
        Task { try? await backend.save(d) }
    }
    func saveAsNew() { q.name = q.name.trimmingCharacters(in: .whitespaces) + tx.copySuffix; saveCurrent(asNew: true) }

    func deleteDeck(_ id: String) {
        if q.delArm == id {
            let d = decks.first { $0.id == id }
            q.delArm = nil
            q.libToast = d.map { tx.deleted($0.name) } ?? ""
            if q.editId == id { q.editId = nil }
            Task { try? await backend.deleteDeck(id: id) }
        } else {
            q.delArm = id; q.libToast = ""
        }
    }

    func playSaved(_ id: String) {
        guard let d = decks.first(where: { $0.id == id }), d.cards.count == Decks.size else { return }
        q.cls = d.cls; q.deck = d.cards; q.editId = d.id; q.name = d.name; q.dirty = false
        go(.diff)
    }

    func toDifficulty() { if q.deck.count == Decks.size { go(.diff) } }

    // MARK: - Starting duels

    private func resetDuelUI() {
        log = nil; pending = nil; sel = nil; busy = false; hist = []; floats = []; hitTick = [:]; drewCount = 0
        reveal = nil; aimed = nil; lungeOffset = [:]; fx = []; hiddenHand = nil; deaths = []; lastEnemyMinion = nil
    }

    func startQuick(_ diff: Difficulty) {
        guard let cls = q.cls else { return }
        q.diff = diff
        run = Run(stage: 0, deck: q.deck, cls: cls)
        let ecls = gd.classes.randomElement()!
        var s = DuelState(mode: .quick, pcls: cls, ecls: ecls.id, diff: diff,
                          p: DuelState.makeHero(.p, hp: 30, deck: q.deck.shuffled(), power: curPower),
                          e: DuelState.makeHero(.e, hp: 30, deck: Decks.pad(ecls.deck, rarities: diff.rarities, cls: ecls.id).shuffled(), power: ecls.power))
        resetDuelUI()
        let pFirst = Bool.random()
        if pFirst {
            s.draw(.p, 3); s.draw(.e, 4); s.e.hand.append("coin"); s.log(.goFirst); s.startTurn(.p)
            state = s; drain(); go(.duel); showBanner(tx.bannerYou, foe: false)
        } else {
            s.draw(.e, 3); s.draw(.p, 4); s.p.hand.append("coin"); s.log(.goSecond); s.turn = .e
            state = s; drain(); go(.duel)
            Task { await aiTurn() }
        }
    }

    func pickClass(_ id: String) { run.cls = id; run.deck = gd.cls(id)?.deck ?? []; startDuel() }

    func startDuel() {
        let o = gd.opponents[run.stage]
        var s = DuelState(mode: .camp, pcls: run.cls ?? "", stage: run.stage,
                          p: DuelState.makeHero(.p, hp: 30, deck: run.deck.shuffled(), power: curPower),
                          e: DuelState.makeHero(.e, hp: o.hp, deck: o.deck.shuffled(), power: gd.fortify))
        resetDuelUI()
        s.log(.rises)
        s.draw(.p, 3); s.draw(.e, 4); s.e.hand.append("coin")
        s.startTurn(.p)
        state = s; drain()
        go(.duel)
        showBanner(tx.bannerYou, foe: false)
    }

    func pickReward(_ i: Int) { run.deck.append(picks[i]); run.stage += 1; startDuel() }
    func skipReward() { run.stage += 1; startDuel() }

    func showBanner(_ text: String, foe: Bool) {
        guard !reduceMotion else { return }
        let b = Banner(text: text, foe: foe)
        withAnimation(.easeOut(duration: 0.25)) { banner = b }
        Task { await wait(1100); if banner == b { withAnimation(.easeIn(duration: 0.3)) { banner = nil } } }
    }

    // MARK: - Visual effects

    private func center(_ id: EID) -> CGPoint? { frames[id].map { CGPoint(x: $0.midX, y: $0.midY) } }

    func burst(at p: CGPoint, color: Color) {
        guard !reduceMotion else { return }
        let id = UUID()
        fx.append(.burst(id: id, at: p, color: color))
        Task { await wait(450); fx.removeAll { $0.id == id } }
    }
    func sparks(at p: CGPoint, n: Int = 5) {
        guard !reduceMotion else { return }
        var ids: [UUID] = []
        for _ in 0..<n {
            let id = UUID(); ids.append(id)
            fx.append(.spark(id: id, at: CGPoint(x: p.x + .random(in: -15...15), y: p.y), dx: .random(in: -15...15), dy: -40 - .random(in: 0...40), size: 3 + .random(in: 0...4)))
        }
        Task { await wait(1100); fx.removeAll { ids.contains($0.id) } }
    }
    func lunge(_ a: EID, _ t: EID) async {
        guard !reduceMotion, let fa = frames[a], let ft = frames[t] else { return }
        let off = CGSize(width: (ft.midX - fa.midX) * 0.78, height: (ft.midY - fa.midY) * 0.78)
        withAnimation(.easeIn(duration: 0.24)) { lungeOffset[a] = off }
        await wait(245)
        burst(at: CGPoint(x: ft.midX, y: ft.midY), color: Color(hex: "#f0a097"))
        withAnimation(.easeOut(duration: 0.2)) { lungeOffset[a] = .zero }
        await wait(160)
        lungeOffset[a] = nil
    }
    func projectile(from: CGPoint?, to t: EID, color: Color) async {
        guard !reduceMotion, let from, let to = center(t) else { return }
        let id = UUID()
        fx.append(.orb(id: id, from: from, to: to, color: color))
        await wait(420)
        fx.removeAll { $0.id == id }
        burst(at: to, color: color)
    }
    func wave(_ side: Side) async {
        guard !reduceMotion, let r = boardFrames[side] else { return }
        let id = UUID()
        fx.append(.wave(id: id, rect: r))
        await wait(620)
        fx.removeAll { $0.id == id }
    }
    func flyCard(_ i: Int, to: CGPoint?) async {
        guard !reduceMotion, let fr = handFrames[i], let k = state?.p.hand[safe: i] else { return }
        let dest = to ?? CGPoint(x: fr.midX, y: fr.minY - 140)
        let id = UUID()
        fx.append(.fly(id: id, key: k, from: fr, to: dest))
        hiddenHand = i
        await wait(340)
        fx.removeAll { $0.id == id }
        hiddenHand = nil
    }
    func aimAt(_ t: EID?) async {
        guard let t else { return }
        aimed = t
        await wait(650)
        aimed = nil
    }
    func boardCenter(_ s: Side) -> CGPoint? { boardFrames[s].map { CGPoint(x: $0.midX, y: $0.midY) } }

    /// Visual for an effect, played before the state change.
    func fxAnim(_ fx: Effect, from: CGPoint?, target t: EID?, side: Side) async {
        if fx.dealsDamage, let t { await projectile(from: from, to: t, color: fx.freeze ? Theme.foam : Theme.ember2) }
        else if fx.destroy || fx.silence || fx.setAtk > 0 || fx.setHp > 0, let t { await projectile(from: from, to: t, color: Color(hex: "#c4b4ff")) }
        else if (fx.buff != nil || fx.healT > 0 || fx.tempAtk > 0 || fx.ward || fx.bounce), let t { await projectile(from: from, to: t, color: Theme.ready) }
        else if fx.sweep > 0 { Task { await wave(side) }; await wave(side.other) }
        else if fx.freezeAll { await wave(side.other) }
        else if fx.face > 0 && fx.aoe == 0 { await projectile(from: from, to: .hero(side.other), color: Theme.ember2) }
        else if fx.aoe > 0 {
            if fx.face > 0, let c = center(.hero(side.other)) { burst(at: c, color: Theme.ember2) }
            await wave(side.other)
        } else if fx.heal > 0 || fx.armor > 0 || fx.team != nil || fx.selfDmg > 0 {
            if let c = center(.hero(side)) { burst(at: c, color: fx.armor > 0 ? Color(hex: "#cfd8dc") : Theme.ready); sparks(at: c, n: 4) }
        }
    }

    // MARK: - Player actions

    var blocked: Bool { state == nil || S.turn != .p || busy || S.over }

    func after() {
        let ended = S.cleanup()
        if sel != nil && !S.p.board.contains(where: { $0.uid == sel }) { sel = nil }
        drain()
        if ended { onGameOver() }
        netFlush()
    }

    private func onGameOver() {
        let won = S.result == .win
        if let c = center(won ? .hero(.e) : .hero(.p)) {
            burst(at: c, color: Color(hex: "#f3c97a")); sparks(at: c, n: 10)
            Task { await wait(150); burst(at: c, color: Theme.blood) }
        }
        switch S.mode {
        case .quick:
            if won { q.w += 1 } else { q.l += 1 }
            backend.update { if won { $0.quickW += 1 } else { $0.quickL += 1 } }
        case .online:
            if S.result == .win { o.w += 1 } else if S.result == .lose { o.l += 1 }
            o.concedeArm = false
            backend.update { if won { $0.onlineW += 1 } else if self.S.result == .lose { $0.onlineL += 1 } }
        case .camp:
            if won && run.stage == gd.opponents.count - 1 { backend.update { $0.campClears += 1 } }
        }
        let snapshot = state
        Task {
            await wait(1300)
            guard let cur = state, let snap = snapshot, cur.over, cur.round == snap.round, cur.mode == snap.mode else { return }
            switch cur.mode {
            case .quick: go(.qresult)
            case .online: go(.oresult)
            case .camp:
                if !won { go(.lost) }
                else if run.stage == gd.opponents.count - 1 { go(.champ) }
                else { picks = Decks.rollRewards(stage: run.stage, cls: run.cls); go(.reward) }
            }
        }
    }

    func playHand(_ i: Int) {
        guard !blocked, pending == nil, i < S.p.hand.count, let c = gd.card(S.p.hand[i]) else { return }
        sel = nil
        if !S.canPay(.p, c.id) { S.log(.noMana); drain(); return }
        Task { await playHandAsync(i, c) }
    }

    private func playHandAsync(_ i: Int, _ c: Card) async {
        let k = c.id
        if c.isMinion {
            if S.p.board.count >= DuelState.boardMax { S.log(.boardFull); drain(); return }
            busy = true
            await flyCard(i, to: boardCenter(.p))
            S.pay(.p, k)
            S.p.hand.remove(at: i)
            let m = S.summon(.p, k)
            let h = pushHist(.p, k, nil)
            S.log(.summon(k))
            netAct(NetAct(n: 0, t: "play", i: i, k: k))
            if let bc = c.bc, let m {
                if let tgt = bc.tgt {
                    let v = S.targetsFor(.p, tgt, bc.cond).filter { $0 != m.id }
                    if !v.isEmpty { pending = Pending(kind: .battlecry(fx: bc, src: m.id, hist: h), valid: v, key: k) }
                } else {
                    drain()
                    await wait(60)
                    await fxAnim(bc, from: center(m.id), target: nil, side: .p)
                    S.applyFx(.p, bc, nil)
                }
            }
            busy = false
            after()
            return
        }
        guard let fx = c.fx else { return }
        if let tgt = fx.tgt {
            let v = S.targetsFor(.p, tgt, fx.cond)
            if v.isEmpty { S.log(.noTargets); drain(); return }
            pending = Pending(kind: .spell(idx: i), valid: v, key: k)
            return
        }
        busy = true
        await flyCard(i, to: fx.aoe > 0 ? boardCenter(.e) : center(.hero(.p)))
        S.pay(.p, k)
        S.p.hand.remove(at: i)
        drain()
        await fxAnim(fx, from: center(.hero(.p)), target: nil, side: .p)
        S.castSpell(.p, k, nil)
        pushHist(.p, k, nil)
        S.log(.cast(k))
        netAct(NetAct(n: 0, t: "cast", i: i, k: k))
        busy = false
        after()
    }

    var powerBlocked: Bool {
        guard let s = state else { return true }
        let p = curPower
        if s.turn != .p || busy || s.over || pending != nil || s.p.powerUsed || s.p.mana < p.cost { return true }
        if !p.fx.summon.isEmpty && s.p.board.count >= DuelState.boardMax { return true }
        if let t = p.tgt, s.targetsFor(.p, t).isEmpty { return true }
        return false
    }

    func usePower() {
        if powerBlocked { if state != nil { S.log(.cantPower); drain() }; return }
        let p = curPower
        sel = nil
        if let t = p.tgt { pending = Pending(kind: .power, valid: S.targetsFor(.p, t), key: nil); return }
        Task {
            busy = true
            await fxAnim(p.fx, from: powerFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: nil, side: .p)
            S.p.mana -= p.cost; S.p.powerUsed = true
            S.applyFx(.p, p.fx, nil)
            S.log(.powerUse(p, nil))
            netAct(NetAct(n: 0, t: "power"))
            busy = false
            after()
        }
    }

    func pendingLabel() -> String { pending?.key.map(tx.cardName) ?? tx.powerName(curPower) }
    func cancelPending() { pending = nil }

    private func resolvePending(_ t: EID) async {
        guard let p = pending else { return }
        pending = nil
        busy = true
        switch p.kind {
        case .spell(let idx):
            guard idx < S.p.hand.count, let c = gd.card(S.p.hand[idx]), let fx = c.fx else { busy = false; return }
            await flyCard(idx, to: center(t))
            S.pay(.p, c.id)
            S.p.hand.remove(at: idx)
            drain()
            await fxAnim(fx, from: center(.hero(.p)), target: t, side: .p)
            S.castSpell(.p, c.id, t)
            pushHist(.p, c.id, S.name(t))
            S.log(.castOn(c.id, S.name(t)))
            netAct(NetAct(n: 0, t: "cast", i: idx, k: c.id, tgt: netRef(t)))
        case .battlecry(let fx, let src, let hid):
            if let hid, let i = hist.firstIndex(where: { $0.id == hid }) { hist[i].target = S.name(t) }
            await fxAnim(fx, from: center(src), target: t, side: .p)
            S.applyFx(.p, fx, t)
            netAct(NetAct(n: 0, t: "bc", tgt: netRef(t)))
        case .power:
            let pw = curPower
            await fxAnim(pw.fx, from: powerFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: t, side: .p)
            S.p.mana -= pw.cost; S.p.powerUsed = true
            S.applyFx(.p, pw.fx, t)
            S.log(.powerUse(pw, S.name(t)))
            netAct(NetAct(n: 0, t: "power", tgt: netRef(t)))
        }
        busy = false
        after()
    }

    func tap(_ id: EID) {
        guard !blocked, S.exists(id) else { return }
        if let p = pending {
            if p.valid.contains(id) { Task { await resolvePending(id) } }
            return
        }
        if let s = sel, let m = S.p.board.first(where: { $0.uid == s }) {
            if S.attackTargets(.p).contains(id) {
                sel = nil
                Task {
                    busy = true
                    await lunge(m.id, id)
                    S.attack(m.id, id)
                    netAct(NetAct(n: 0, t: "atk", a: m.uid, tgt: netRef(id)))
                    busy = false
                    after()
                }
                return
            }
            if id.side == .e { S.log(.guardWay); drain(); return }
        }
        if id.side == .p, let m = S.minion(id) {
            if S.canAttack(m) {
                sel = sel == m.uid ? nil : m.uid
                if sel != nil { S.log(.ready(m.key)) } else { log = nil }
            } else {
                S.log(m.attacked ? .already(m.key) : m.atk <= 0 ? .noAtk(m.key) : .nextTurn(m.key))
            }
            drain(); return
        }
        if id.side == .e, let m = S.minion(id) { S.log(.info(m.key, m.atk, m.hp)); drain(); return }
        sel = nil
    }

    func isValidTarget(_ id: EID) -> Bool {
        guard let s = state else { return false }
        if let p = pending { return p.valid.contains(id) }
        if sel != nil && id.side == .e { return s.attackTargets(.p).contains(id) }
        return false
    }

    func hasMoves() -> Bool {
        guard let s = state else { return false }
        let p = s.p
        return p.hand.contains { k in (gd.card(k).map { s.canPay(.p, k) && (!$0.isMinion || p.board.count < DuelState.boardMax) } ?? false) }
            || p.board.contains(where: s.canAttack) || !powerBlocked
    }

    func endTurn() {
        guard !blocked else { return }
        pending = nil; sel = nil
        if S.mode == .online {
            netAct(NetAct(n: 0, t: "end"))
            S.turn = .e; S.round += 1
            S.startTurn(.e)
            S.log(.eTurn)
            S.cleanup(); drain(); netFlush()
            showBanner(tx.bannerFoe, foe: true)
            return
        }
        S.turn = .e
        Task { await aiTurn() }
    }

    @discardableResult
    func pushHist(_ side: Side, _ key: String, _ t: NameRef?) -> UUID {
        let h = HistItem(side: side, key: key, target: t, round: S.round)
        hist.append(h)
        if hist.count > 8 { hist.removeFirst() }
        return h.id
    }

    // MARK: - Computer opponent

    func aiTurn() async {
        busy = true
        S.round += 1
        S.startTurn(.e)
        S.log(.eTurn)
        S.cleanup(); drain()
        showBanner(tx.bannerFoe, foe: true)
        await wait(900)
        for _ in 0..<12 where !S.over {
            var did = false
            for o in S.aiPlayable() {
                guard let plan = S.aiPlan(o.key), let c = gd.card(o.key) else { continue }
                var t = plan
                S.pay(.e, c.id)
                S.e.hand.remove(at: o.index)
                if c.isMinion {
                    let shown: EID? = (c.bc?.tgt != nil) ? t : nil
                    S.log(.eSummon(c.id)); drain()
                    reveal = Reveal(side: .e, key: c.id, target: shown.map { S.name($0) })
                    await wait(1100)
                    let m = S.summon(.e, c.id)
                    pushHist(.e, c.id, shown.map { S.name($0) })
                    drain()
                    if let bc = c.bc, let m {
                        if bc.tgt == .ally && t == nil { t = m.id }
                        if bc.tgt != nil { await aimAt(t) }
                        await fxAnim(bc, from: revealCenter, target: t, side: .e)
                        S.applyFx(.e, bc, t)
                    }
                    reveal = nil
                } else if let fx = c.fx {
                    S.log(t.map { .eCastOn(c.id, S.name($0)) } ?? .eCast(c.id)); drain()
                    reveal = Reveal(side: .e, key: c.id, target: t.map { S.name($0) })
                    await wait(1400)
                    pushHist(.e, c.id, t.map { S.name($0) })
                    await aimAt(t)
                    await fxAnim(fx, from: revealCenter, target: t, side: .e)
                    S.castSpell(.e, c.id, t)
                    reveal = nil
                }
                did = true
                S.cleanup(); drain()
                await wait(500)
                break
            }
            if !did { break }
        }
        if !S.over { await aiPower() }
        for m in S.e.board {
            if S.over { break }
            guard S.e.board.contains(where: { $0.uid == m.uid }), let cur = S.minion(m.id), S.canAttack(cur) else { continue }
            let t = S.aiAttackTarget(cur)
            await lunge(m.id, t)
            S.attack(m.id, t)
            S.cleanup(); drain()
            await wait(420)
        }
        if S.over { busy = false; onGameOver(); return }
        S.turn = .p
        S.startTurn(.p)
        busy = false
        S.log(.yourTurn)
        S.cleanup(); drain()
        showBanner(tx.bannerYou, foe: false)
    }

    private var revealCenter: CGPoint? { revealFrame.map { CGPoint(x: $0.midX, y: $0.midY) } }

    private func aiPower() async {
        guard let plan = S.aiPowerPlan() else { return }
        let p = S.e.power
        S.e.mana -= p.cost
        if let t = plan { await aimAt(t) }
        await fxAnim(p.fx, from: epowFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: plan, side: .e)
        S.applyFx(.e, p.fx, plan)
        S.log(.ePower(p, plan.map { S.name($0) }))
        S.cleanup(); drain()
        await wait(600)
    }

    // MARK: - Online

    var onlineDecks: [SavedDeck] { decks.filter { $0.isComplete } }
    var curOnlineDeck: SavedDeck? { onlineDecks.first { $0.id == o.sel } ?? onlineDecks.first }

    func goOnline() {
        if o.sel == nil { o.sel = backend.profile.onlineDeck }
        o.err = ""; o.toast = ""
        go(.online)
    }
    func selectOnlineDeck(_ id: String) { o.sel = id; o.err = ""; backend.update { $0.onlineDeck = id } }

    private func onlineError(_ e: Error) -> String {
        if let b = e as? BackendError {
            switch b {
            case .needsApple, .notSignedIn: return tx.errSignIn
            case .noOnline: return tx.errNoBackend
            case .roomNotFound, .roomTaken: return tx.errNoRoom
            case .versionMismatch: return tx.errVersion
            case .invalidDeck: return tx.errDeck
            case .timeout: return tx.errTimeout
            case .cancelled: return ""
            case .requiresRecentLogin: return tx.reauthNeeded
            case .server(let s): return s.isEmpty ? tx.errServer : s
            }
        }
        if e is CancellationError { return "" }
        return tx.errServer
    }

    private func beginNet(_ work: @escaping () async throws -> OnlineMatch) {
        guard let deck = curOnlineDeck else { return }
        guard let svc = backend.matches else { o.err = tx.errNoBackend; return }
        _ = svc
        o.err = ""; o.toast = ""
        o.sel = deck.id
        backend.update { $0.onlineDeck = deck.id }
        findTask?.cancel()
        findTask = Task {
            do {
                let m = try await work()
                guard !Task.isCancelled else { await m.leave(); return }
                attach(m)
            } catch {
                guard !Task.isCancelled else { return }
                o.net = .idle
                o.err = onlineError(error)
            }
        }
    }

    func findMatch() {
        guard backend.matches != nil else { o.err = tx.errNoBackend; return }
        guard let deck = curOnlineDeck else { return }
        o.net = .searching(0)
        let started = Date()
        let ticker = Task { while !Task.isCancelled { await wait(1000); if case .searching = o.net { o.net = .searching(Int(Date().timeIntervalSince(started))) } } }
        beginNet { [self] in
            defer { ticker.cancel() }
            return try await backend.matches!.findMatch(deck: deck)
        }
    }

    func createRoom() {
        guard backend.matches != nil else { o.err = tx.errNoBackend; return }
        guard let deck = curOnlineDeck else { return }
        o.net = .hosting(nil)
        beginNet { [self] in
            try await backend.matches!.createRoom(deck: deck) { code in self.o.net = .hosting(code) }
        }
    }

    func joinTyped() {
        guard backend.matches != nil else { o.err = tx.errNoBackend; return }
        let code = o.code.filter(\.isNumber)
        o.code = code
        guard code.count == 6 else { o.err = tx.errCode; return }
        guard let deck = curOnlineDeck else { return }
        o.net = .joining
        beginNet { [self] in try await backend.matches!.joinRoom(code: code, deck: deck) }
    }

    func cancelNet() {
        findTask?.cancel(); findTask = nil
        o.net = .idle; o.toast = ""
    }

    var roomCodeForShare: String? { if case .hosting(let c?) = o.net { return c }; return nil }

    private func attach(_ m: OnlineMatch) {
        match = m
        o.net = .live
        o.lost = nil; o.conceded = false; o.concedeArm = false; o.again = false; o.foeAgain = false
        game = 0
        m.onUpdate = { [weak self] doc in self?.onDoc(doc) }
        if let d = m.doc { onDoc(d) }
        watchTask?.cancel()
        watchTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.wait(4000)
                self?.netWatch()
            }
        }
    }

    private func onDoc(_ d: MatchDoc) {
        guard let m = match else { return }
        if d.game != game, let st = d.state {
            game = d.game
            startOnline(st, isHost: m.isHost)
        }
        guard state != nil, S.mode == .online else { return }
        if let left = d.left {
            if left == m.foeUid { netLost(message: "oLeft"); return }
            if left == m.myUid && !S.over { droppedOut(); return }
        }
        o.foeAgain = d.again[m.foeUid] == true
        o.again = d.again[m.myUid] == true
        if o.foeAgain && o.again && m.isHost && S.over { Task { await netDeal() } }
        if d.actsBy == m.foeUid {
            let fresh = d.acts.filter { $0.n > appliedN }
            if !fresh.isEmpty {
                for a in fresh where !netQueue.contains(where: { $0.n == a.n }) { netQueue.append(a) }
                pendingDoc = d
                Task { await pump() }
            } else if d.seq > seq, !pumping {
                seq = d.seq
                verify(against: d)
            }
        }
    }

    private func startOnline(_ hostState: DuelState, isHost: Bool) {
        var s = isHost ? hostState : hostState.flipped()
        s.events = []
        run = Run(stage: 0, deck: s.p.deck, cls: s.pcls)
        resetDuelUI()
        netOut = []; turnActs = []; netN = 0; appliedN = 0; seq = 0; netQueue = []
        o.lost = nil; o.conceded = false; o.concedeArm = false; o.again = false; o.foeAgain = false
        state = s
        S.log(s.turn == .p ? .goFirst : .goSecond); drain()
        go(.duel)
        showBanner(s.turn == .p ? tx.bannerYou : tx.bannerFoe, foe: s.turn != .p)
    }

    private func netRef(_ id: EID?) -> NetRef? { id.map { NetRef(s: $0.side == .p ? "me" : "you", u: $0.uid) } }
    /// The sender's "me" is our enemy.
    private func netDeref(_ r: NetRef?) -> EID? {
        guard let r else { return nil }
        let id = EID(side: r.s == "me" ? .e : .p, uid: r.u)
        return S.exists(id) ? id : nil
    }

    func netAct(_ a: NetAct) {
        guard state != nil, S.mode == .online, match != nil else { return }
        netN += 1
        var x = a; x.n = netN
        netOut.append(x)
    }

    func netFlush() {
        guard let m = match, state != nil, S.mode == .online, !netOut.isEmpty else { return }
        turnActs.append(contentsOf: netOut)
        netOut = []
        seq += 1
        let hostState = m.isHost ? S : S.flipped()
        let acts = turnActs, sq = seq, turnHost = (S.turn == .p) == m.isHost
        Task { try? await m.send(state: hostState, acts: acts, seq: sq, turnHost: turnHost) }
    }

    private func verify(against d: MatchDoc) {
        guard let m = match, let st = d.state, state != nil, S.mode == .online else { return }
        let mine = m.isHost ? S : S.flipped()
        if mine.hash(hostSide: .p) != st.hash(hostSide: .p) {
            var s = m.isHost ? st : st.flipped()
            s.events = []
            state = s
            pending = nil; sel = nil; busy = false
            S.cleanup(); drain()
        }
    }

    private func pump() async {
        guard !pumping else { return }
        pumping = true
        while !netQueue.isEmpty, state != nil, S.mode == .online {
            netQueue.sort { $0.n < $1.n }
            let a = netQueue.removeFirst()
            if a.n <= appliedN { continue }
            appliedN = a.n
            netN = max(netN, a.n)
            do { try await remoteAct(a) } catch {
                // Out of step: adopt the opponent's copy of the game.
                if let d = pendingDoc { seq = d.seq; verify(against: d) }
                netQueue = []
            }
            if S.over { netQueue = []; break }
        }
        pumping = false
        if let d = pendingDoc, d.seq >= seq { seq = d.seq; verify(against: d) }
    }

    private enum NetError: Error { case outOfStep }

    private func remoteAct(_ a: NetAct) async throws {
        if a.t == "concede" { o.conceded = true; S.e.hp = 0; let ended = S.cleanup(); drain(); if ended { onGameOver() }; return }
        if a.t == "end" {
            turnActs = []
            S.turn = .p; S.round += 1
            S.startTurn(.p)
            busy = false
            S.log(.yourTurn)
            S.cleanup(); drain()
            showBanner(tx.bannerYou, foe: false)
            return
        }
        busy = true
        defer { busy = false }
        switch a.t {
        case "play", "cast":
            guard let i = a.i, i < S.e.hand.count, S.e.hand[i] == a.k, let c = gd.card(S.e.hand[i]) else { throw NetError.outOfStep }
            S.pay(.e, c.id)
            S.e.hand.remove(at: i)
            if c.isMinion {
                S.log(.eSummon(c.id)); drain()
                reveal = Reveal(side: .e, key: c.id)
                await wait(900)
                let m = S.summon(.e, c.id)
                let hid = pushHist(.e, c.id, nil)
                if let m { lastEnemyMinion = (m.uid, hid) }
                drain()
                if let bc = c.bc, bc.tgt == nil, let m {
                    await fxAnim(bc, from: revealCenter, target: nil, side: .e); S.applyFx(.e, bc, nil); _ = m
                }
                reveal = nil
            } else if let fx = c.fx {
                let t = netDeref(a.tgt)
                if a.tgt != nil && t == nil { throw NetError.outOfStep }
                S.log(t.map { .eCastOn(c.id, S.name($0)) } ?? .eCast(c.id)); drain()
                reveal = Reveal(side: .e, key: c.id, target: t.map { S.name($0) })
                await wait(1100)
                pushHist(.e, c.id, t.map { S.name($0) })
                if t != nil { await aimAt(t) }
                await fxAnim(fx, from: revealCenter, target: t, side: .e)
                S.castSpell(.e, c.id, t)
                reveal = nil
            }
        case "bc":
            guard let last = lastEnemyMinion, let m = S.minion(EID(side: .e, uid: last.uid)), let fx = m.card.bc else { throw NetError.outOfStep }
            let t = netDeref(a.tgt)
            if a.tgt != nil && t == nil { throw NetError.outOfStep }
            if let t {
                if let i = hist.firstIndex(where: { $0.id == last.hist }) { hist[i].target = S.name(t) }
                await aimAt(t)
            }
            await fxAnim(fx, from: center(m.id), target: t, side: .e)
            S.applyFx(.e, fx, t)
        case "power":
            let p = S.e.power
            let t = netDeref(a.tgt)
            if a.tgt != nil && t == nil { throw NetError.outOfStep }
            S.e.mana -= p.cost; S.e.powerUsed = true
            if t != nil { await aimAt(t) }
            await fxAnim(p.fx, from: epowFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: t, side: .e)
            S.applyFx(.e, p.fx, t)
            S.log(.ePower(p, t.map { S.name($0) }))
        case "atk":
            guard let uid = a.a, let m = S.minion(EID(side: .e, uid: uid)), let t = netDeref(a.tgt) else { throw NetError.outOfStep }
            S.log(.attacks(.card(m.key), S.name(t))); drain()
            await lunge(m.id, t)
            S.attack(m.id, t)
        default: break
        }
        let ended = S.cleanup(); drain()
        if ended { onGameOver() }
        await wait(350)
    }

    private func netWatch() {
        guard let m = match, state != nil, S.mode == .online else { return }
        let idle = m.foeIdle
        if idle > 60 && !S.over { netLost(message: "oLeft", writeLeft: true); return }
        o.slow = idle > 12 && screen == .duel && !S.over
    }

    /// Opponent gone. Mid-game that is a win; afterwards it only ends the rematch option.
    private func netLost(message: String, writeLeft: Bool = false) {
        guard let m = match else { return }
        o.lost = message
        if state != nil, S.mode == .online, !S.over {
            S.over = true; S.result = .win; o.w += 1
            busy = false; pending = nil
            backend.update { $0.onlineW += 1 }
            go(.oresult)
        }
        Task { if writeLeft { await m.dropFoe() }; await m.leave(announce: !writeLeft) }
        match = nil
        watchTask?.cancel()
        o.net = .idle; o.slow = false
    }

    private func droppedOut() {
        o.lost = "errTimeout"
        S.over = true; S.result = .lose; o.l += 1
        busy = false; pending = nil
        backend.update { $0.onlineL += 1 }
        go(.oresult)
        Task { await match?.leave() }
        match = nil; watchTask?.cancel(); o.net = .idle
    }

    func concede() {
        guard state != nil, S.mode == .online, !S.over else { return }
        if !o.concedeArm {
            o.concedeArm = true
            Task { await wait(3000); o.concedeArm = false }
            return
        }
        o.concedeArm = false; pending = nil; sel = nil
        netAct(NetAct(n: 0, t: "concede"))
        S.p.hp = 0
        after()
    }

    func askRematch() {
        guard let m = match else { return }
        o.again = true
        Task { try? await m.askRematch() }
    }

    private func netDeal() async {
        guard let m = match, m.isHost, let d = m.doc else { return }
        let st = DuelState.onlineStart(hostCls: d.hc, hostDeck: d.hDeck, guestCls: d.gc, guestDeck: d.gDeck)
        try? await m.resetGame(state: st)
    }

    func netClose() async {
        findTask?.cancel(); findTask = nil
        watchTask?.cancel()
        if let m = match { match = nil; await m.leave() }
        o.net = .idle; o.slow = false
    }

    func leaveOnline() { Task { await netClose() }; o.lost = nil; newRun() }

    var oResultWhy: String? {
        if let l = o.lost { return l == "oLeft" ? tx.oLeft : tx.errTimeout }
        if o.conceded { return tx.oConceded }
        return nil
    }

    // MARK: - Builder → online

    func useDeckOnline() {
        guard q.deck.count == Decks.size else { return }
        if q.dirty || q.editId == nil { saveCurrent(asNew: false) }
        o.sel = q.editId
        backend.update { $0.onlineDeck = self.q.editId }
        q.returnToOnline = false
        goOnline()
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
