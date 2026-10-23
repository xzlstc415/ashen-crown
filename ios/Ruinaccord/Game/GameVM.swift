import SwiftUI
import Observation

enum Screen: Hashable {
    case intro, classPick, talents, duel, reward, lost, champ, decks, qclass, build, diff, qtalents, qresult, gallery, online, oresult
}

struct Run {
    var stage = 0
    var deck: [String] = []
    var cls: String?
    /// Talents chosen for this adventure (points come duel by duel).
    var tal: [String] = []
}

/// A choice of cards shown to the player: the dead on offer (Graveyard Summoner) or the Legendaries (Blood Rite).
struct Choice {
    var offer: [String]
    var n: Int
    var picks: Set<Int> = []
    var rite = false
}

struct Pending {
    enum Kind { case spell(idx: Int), battlecry(fx: Effect, src: EID, hist: UUID?), power }
    var kind: Kind
    var valid: [EID]
    var key: String?
    /// A multi-target spell: how many targets it takes and the ones chosen so far.
    var need = 1
    var picks: [EID] = []
}

struct HistItem: Identifiable, Hashable {
    let id = UUID()
    let side: Side
    let key: String
    var target: NameRef?
    let round: Int
}

/// A drag in progress. `over` is the valid target under the finger; `aboveLine` means the hand card has been
/// pulled up out of the hand far enough to count as playing it.
struct Drag {
    enum Source: Equatable { case hand(Int), minion(EID), power }
    var src: Source
    var pt: CGPoint
    var over: EID?
    var aboveLine = false
    /// Targets this drag may end on (a targeted spell, an attacker's reach, a targeted hero power).
    var valid: [EID] = []
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
    case shatter(id: UUID, at: CGPoint, foe: Bool)
    var id: UUID {
        switch self {
        case .orb(let id, _, _, _), .burst(let id, _, _), .spark(let id, _, _, _, _), .wave(let id, _), .fly(let id, _, _, _), .shatter(let id, _, _): return id
        }
    }
}

struct Builder {
    var cls: String?
    var deck: [String] = []
    var tal: [String] = []
    /// Builder tab: the card list or the talent pages.
    var showTalents = false
    /// Where the quick-play talent screen leads: the builder (a new deck) or the difficulty (a chosen deck).
    /// Where the quick-play talent screen goes back to: the deck builder (a deck being made or edited) or the deck list.
    var talNext: Screen = .diff
    var talFrom: Screen = .build
    var diff: Difficulty = .normal
    var typeFilter = "all"
    var costFilter = 0
    /// "all", "e" or "l": the rarity shown in the builder.
    var rarityFilter = "all"
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
    /// The lifted hand card: tapped once (tap it again to play) or held down to read it.
    var hsel: Int?
    /// While the hand is parked in the corner (enemy turn), a tap on it fans the cards out to read for a moment.
    var handPeek = false
    /// A finger dragging a hand card, a ready minion or the hero power.
    var drag: Drag?
    /// The battle log panel (every play of the game, by turn).
    var showLog = false
    /// The talents of both sides, listed.
    var showTalentPanel = false
    /// The painted place behind the current duel (see `Scenes`).
    var scene = "dawn"
    /// The rules panel over the menu.
    var showRules = false
    /// A board minion being held down: its card shows in the info panel.
    var infoKey: String?
    /// The card described in the top-left panel: the lifted hand card, else the held minion.
    var infoCard: Card? {
        if let i = hsel, let k = state?.p.hand[safe: i], let c = gd.card(k) { return c }
        return infoKey.flatMap(gd.card)
    }
    /// Single-player duels: first tap on Leave arms it; `abandoned` stops the game without a result screen.
    var quitArm = false
    var abandoned = false
    /// Opening mulligan: hand cards picked for replacement; `mullMine` is set once confirmed (online: until the foe confirms).
    var choice: Choice?
    var mullPicks: Set<Int> = []
    var mullMine: [Int]?
    private var mullCont: (() -> Void)?
    /// Changes with every new game, so an AI turn still waiting from an old game stops instead of acting in the new one.
    private(set) var gameToken = UUID()
    var zoomCard: String?
    var peekItem: HistItem?
    /// Heroes whose portrait is breaking apart at game over.
    var dying: Set<Side> = []
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
        // Heroes go by their own names (Rok Greytusk, ...); Adventure foes keep theirs.
        if side == .p { return tx.heroName(run.cls ?? "") }
        guard let s = state else { return "" }
        switch s.mode {
        case .quick: return tx.aiName(tx.heroName(s.ecls ?? ""))
        case .online: return tx.foeName(tx.heroName(s.ecls ?? ""))
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
        case .prayed(let k): return t.prayed(t.cardName(k))
        case .ePrayed(let k): return t.ePrayed(heroName(.e), t.cardName(k))
        case .prayerDone(let s, let k): return t.prayerDone(heroName(s), t.cardName(k))
        case .altarFull: return t.altarFull
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
        case .answered: return (tx.fPray, Color(hex: "#ffe9a0"))
        case .revived: return (tx.fRevive, Theme.ready)
        case .rage: return (tx.rageGo, Color(hex: "#e0563f"))
        case .named(let k): return (tx.cardName(k), Color(hex: "#c4b4ff"))
        case .manaUp(let n): return ("+\(n)", Theme.manaLight)
        case .light(let n): return ("✦+\(n)", Color(hex: "#ffe9a0"))
        case .soulPay: return (tx.fSoulPay, Color(hex: "#c4b4ff"))
        case .fero: return (tx.fFero, Color(hex: "#9ad48a"))
        case .prestige(let n): return (tx.presUp(n), Color(hex: "#ffd27a"))
        case .prestigeGo: return (tx.presGo, Color(hex: "#ffd27a"))
        case .rite(let n): return (tx.fRite(n), Theme.blood)
        case .ether: return (tx.fEther, Color(hex: "#c4b4ff"))
        case .immune: return (tx.fImmune, Color(hex: "#ffd27a"))
        case .mark: return ("✦", Color(hex: "#c4b4ff"))
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
            q.cls = d.cls; q.deck = d.cards; q.editId = d.id; q.name = d.name; q.dirty = false; q.tal = d.talents
        } else if let cls {
            q.cls = cls; q.deck = gd.cls(cls)?.deck ?? []; q.editId = nil; q.name = nextDefaultName(cls); q.dirty = true; q.tal = gd.talentPreset(cls, 0)
        }
        q.toast = ""; q.showTalents = false
        // A new deck picks its talents first, so the cards then show what the talents do to them; then cards, then the
        // difficulty. Every step can go back (and the builder's Talents tab is always there).
        if id == nil, !q.returnToOnline, gd.hasTalents(q.cls) { q.talNext = .build; q.talFrom = .classPick; go(.qtalents) } else { go(.build) }
    }

    // MARK: - Talents

    /// Where talent picks go: the deck being built, or the adventure run (with the points earned so far).
    var talentContext: (cls: String, sel: [String], budget: Int)? {
        if screen == .build || screen == .qtalents, let cls = q.cls { return (cls, q.tal, gd.talents.maxPts) }
        if let cls = run.cls { return (cls, run.tal, gd.advPoints(run.stage)) }
        return nil
    }
    private func setTalents(_ v: [String]) {
        if screen == .build || screen == .qtalents { q.tal = v; q.dirty = true; q.toast = "" } else { run.tal = v }
    }
    func talClick(_ id: String) {
        guard let c = talentContext, gd.talentNode(id) != nil else { return }
        let t = gd.talentTier(of: id)
        if c.sel.contains(id) { setTalents(gd.pruneTalents(c.sel.filter { $0 != id })) }
        else if c.sel.count < c.budget && gd.tierOpen(c.sel, t) && gd.tierPick(c.sel, t) == nil { setTalents(c.sel + [id]) }
    }
    /// Presets 0, 1, 2; nil clears.
    func talPreset(_ i: Int?) {
        guard let c = talentContext else { return }
        setTalents(i.map { Array(gd.talentPreset(c.cls, $0).prefix(c.budget)) } ?? [])
    }
    /// Adventure: the talent screen before each duel.
    func goStage() { if gd.hasTalents(run.cls) { go(.talents) } else { startDuel() } }
    /// Packs offered after the duel just won (talent classes), or nil for the three random cards.
    var advPacks: [TalentPack]? { run.cls.flatMap { gd.advPacks($0, stage: run.stage) } }
    func pickPack(_ i: Int) {
        guard let ps = advPacks, let p = ps[safe: i] else { return }
        // A pack never pushes a card past its copy limit (one of a Legendary).
        for k in p.cards where Decks.fits(run.deck, k) { run.deck.append(k) }
        run.stage += 1; goStage()
    }

    func addCard(_ k: String) {
        if q.deck.count >= Decks.size { q.toast = tx.deckFull }
        else if Decks.copies(q.deck, k) >= Decks.maxCopies(k) { q.toast = tx.limitHit }
        else if !Decks.fits(q.deck, k) { q.toast = tx.legLimit }
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
        d.tal = q.tal
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
        q.cls = d.cls; q.deck = d.cards; q.editId = d.id; q.name = d.name; q.dirty = false; q.tal = d.talents
        if gd.hasTalents(d.cls) { q.talNext = .diff; q.talFrom = .decks; go(.qtalents) } else { go(.diff) }
    }

    func toDifficulty() { if q.deck.count == Decks.size { go(.diff) } }
    /// The difficulty screen's back step: the cards.
    func backFromDifficulty() { go(.build) }
    /// Quick play: after the difficulty, classes with talents get the talent screen; the deck keeps the choice.
    func pickDifficulty(_ d: Difficulty) { q.diff = d; startQuick(d) }
    /// Leaves the quick-play talent screen: on to the cards of a new deck, or to the difficulty with a chosen deck.
    func talentsNext() {
        if q.talNext == .build { go(.build); return }
        if q.dirty, q.editId != nil { saveCurrent(asNew: false) }
        go(.diff)
    }

    // MARK: - Starting duels

    private func resetDuelUI() {
        log = nil; pending = nil; sel = nil; busy = false; hist = []; floats = []; hitTick = [:]; drewCount = 0
        reveal = nil; aimed = nil; lungeOffset = [:]; fx = []; dying = []; hiddenHand = nil; deaths = []; lastEnemyMinion = nil; choice = nil
        gameToken = UUID(); mullPicks = []; mullMine = nil; mullCont = nil; hsel = nil; handPeek = false; drag = nil; showLog = false; infoKey = nil
    }

    func startQuick(_ diff: Difficulty) {
        abandoned = false; quitArm = false
        guard let cls = q.cls else { return }
        q.diff = diff
        run = Run(stage: 0, deck: q.deck, cls: cls, tal: q.tal)
        scene = Scenes.random()
        let ecls = gd.classes.randomElement()!
        var s = DuelState(mode: .quick, pcls: cls, ecls: ecls.id, diff: diff,
                          p: DuelState.makeHero(.p, hp: 30, deck: q.deck.shuffled(), power: curPower),
                          e: DuelState.makeHero(.e, hp: 30, deck: Decks.pad(ecls.deck, rarities: diff.rarities, cls: ecls.id).shuffled(), power: ecls.power))
        s.setupTalents(.p, cls: cls, q.tal)
        s.setupTalents(.e, cls: ecls.id, gd.talentPreset(ecls.id, Int.random(in: 0..<3)))
        resetDuelUI()
        let first: Side = Bool.random() ? .p : .e
        s.draw(first, 5); s.draw(first.other, 5); s.talOpen(first); s.talOpen(first.other); s.turn = first; s.mulligan = true
        state = s; drain(); go(.duel)
        mullCont = { [self] in
            S[first.other].hand.append("coin")
            S.log(first == .p ? .goFirst : .goSecond)
            if first == .p { S.startTurn(.p); drain(); showBanner(tx.bannerYou, foe: false) }
            else { drain(); Task { await aiTurn() } }
        }
    }

    func pickClass(_ id: String) {
        run.cls = id; run.deck = gd.talents.adv[id]?.deck ?? gd.cls(id)?.deck ?? []; run.tal = []
        goStage()
    }

    func startDuel() {
        abandoned = false; quitArm = false
        let o = gd.opponents[run.stage]
        scene = Scenes.forStage(run.stage)
        // Talent classes: both sides open with 5 cards and the foe has 40% more Health.
        let tc = gd.hasTalents(run.cls), ehp = tc ? Int((Double(o.hp) * 1.4).rounded()) : o.hp
        var s = DuelState(mode: .camp, pcls: run.cls ?? "", stage: run.stage,
                          p: DuelState.makeHero(.p, hp: 30, deck: run.deck.shuffled(), power: curPower),
                          e: DuelState.makeHero(.e, hp: ehp, deck: o.deck.shuffled(), power: gd.fortify))
        s.setupTalents(.p, cls: run.cls, run.tal)
        resetDuelUI()
        s.log(.rises)
        s.draw(.p, tc ? 5 : 3); s.draw(.e, tc ? 5 : 4); s.talOpen(.p); s.mulligan = true
        state = s; drain()
        go(.duel)
        mullCont = { [self] in
            S.e.hand.append("coin"); S.startTurn(.p); drain()
            showBanner(tx.bannerYou, foe: false)
        }
    }

    func pickReward(_ i: Int) { run.deck.append(picks[i]); run.stage += 1; goStage() }
    func skipReward() { run.stage += 1; goStage() }

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
    /// Debug launches (`-shatter`): your portrait breaks apart without a game over.
    func debugShatter() { if let c = center(.hero(.p)) { shatter(at: c, foe: false); dying.insert(.p) } }
    /// The portrait breaks apart (game over): a flash, then shards of its frame colour fly out.
    func shatter(at p: CGPoint, foe: Bool) {
        guard !reduceMotion else { return }
        let id = UUID()
        fx.append(.shatter(id: id, at: p, foe: foe))
        Task { await wait(1100); fx.removeAll { $0.id == id } }
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

    var blocked: Bool { state == nil || S.turn != .p || busy || S.over || S.mulligan || choice != nil }

    func after() {
        let ended = S.cleanup()
        if sel != nil && !S.p.board.contains(where: { $0.uid == sel }) { sel = nil }
        drain()
        if ended { onGameOver() }
        netFlush()
    }

    private func onGameOver() {
        if abandoned { return }
        let won = S.result == .win
        // Every hero at 0 Health (both, in an online draw) flashes, bursts and shatters before the result shows.
        for l in [Side.p, .e] where S[l].hp <= 0 {
            if let c = center(.hero(l)) {
                burst(at: c, color: Color(hex: "#f3c97a")); sparks(at: c, n: 10)
                Task { await wait(150); burst(at: c, color: Theme.blood); shatter(at: c, foe: l == .e); dying.insert(l) }
            } else { dying.insert(l) }
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
            await wait(1700)
            guard let cur = state, let snap = snapshot, cur.over, cur.round == snap.round, cur.mode == snap.mode else { return }
            switch cur.mode {
            case .quick: go(.qresult)
            case .online: go(.oresult)
            case .camp:
                if !won { go(.lost) }
                else if run.stage == gd.opponents.count - 1 { go(.champ) }
                else { picks = Decks.rollRewards(stage: run.stage, cls: run.cls, talents: run.tal, deck: run.deck); go(.reward) }
            }
        }
    }

    /// Plays hand card `i`. A targeted spell dropped straight onto `target` resolves at once instead of asking.
    func playHand(_ i: Int, target: EID? = nil) {
        guard !blocked, pending == nil, i < S.p.hand.count, let c = gd.card(S.p.hand[i]) else { return }
        sel = nil; hsel = nil
        if !S.canPay(.p, c.id) { S.log(.noMana); drain(); return }
        Task { await playHandAsync(i, c, target: target) }
    }

    private func playHandAsync(_ i: Int, _ c: Card, target: EID? = nil) async {
        let k = c.id
        if c.isPrayer {
            if S.p.altar.count >= S.altarMax(.p) { S.log(.altarFull); drain(); return }
            busy = true
            await flyCard(i, to: center(.hero(.p)))
            S.pay(.p, k)
            S.takeHand(.p, i)
            S.castSpell(.p, k, nil)
            pushHist(.p, k, nil)
            S.log(.prayed(k))
            netAct(NetAct(n: 0, t: "cast", i: i, k: k))
            busy = false
            after()
            return
        }
        if c.isMinion {
            if S.p.board.count >= DuelState.boardMax { S.log(.boardFull); drain(); return }
            busy = true
            await flyCard(i, to: boardCenter(.p))
            S.pay(.p, k)
            S.takeHand(.p, i)
            let m = S.summon(.p, k)
            let h = pushHist(.p, k, nil)
            S.log(.summon(k))
            netAct(NetAct(n: 0, t: "play", i: i, k: k))
            if let bc = S.cardBc(.p, k), let m {
                if let tgt = bc.tgt {
                    let v = S.targetsFor(.p, tgt, bc.cond).filter { $0 != m.id }
                    if !v.isEmpty { pending = Pending(kind: .battlecry(fx: bc, src: m.id, hist: h), valid: v, key: k) }
                } else {
                    drain()
                    await wait(60)
                    await fxAnim(bc, from: center(m.id), target: nil, side: .p)
                    S.applyFx(.p, bc, nil)
                    if bc.reclaim > 0 {
                        let offer = S.reclaimOffer(.p)
                        if !offer.isEmpty { choice = Choice(offer: offer, n: Swift.min(bc.reclaim, offer.count)) }
                    }
                }
            }
            busy = false
            after()
            return
        }
        guard let fx = S.cardFx(.p, k) else { return }
        if let tgt = fx.tgt {
            let v = S.targetsFor(.p, tgt, fx.cond)
            if v.isEmpty { S.log(.noTargets); drain(); return }
            pending = Pending(kind: .spell(idx: i), valid: v, key: k, need: Swift.max(1, fx.multi))
            if let target, v.contains(target) { await resolvePending(target) }
            return
        }
        busy = true
        await flyCard(i, to: fx.aoe > 0 ? boardCenter(.e) : center(.hero(.p)))
        S.pay(.p, k)
        S.takeHand(.p, i)
        drain()
        await fxAnim(fx, from: center(.hero(.p)), target: nil, side: .p)
        S.castSpell(.p, k, nil)
        pushHist(.p, k, nil)
        S.log(.cast(k))
        netAct(NetAct(n: 0, t: "cast", i: i, k: k))
        if c.rite { choice = Choice(offer: S.riteOffer(), n: 1, rite: true) }
        busy = false
        after()
    }

    /// Your hero power as talents shaped it (the class power until a duel starts).
    var myPower: Power { state?.p.power ?? curPower }

    var powerBlocked: Bool {
        guard let s = state else { return true }
        let p = s.p.power
        if s.turn != .p || busy || s.over || s.mulligan || choice != nil || pending != nil || s.p.powerUsed || s.p.mana < s.pcost(.p) { return true }
        if !p.fx.summon.isEmpty && s.p.board.count >= DuelState.boardMax { return true }
        if let t = p.tgt, s.targetsFor(.p, t).isEmpty { return true }
        return false
    }

    func usePower() {
        if powerBlocked { if state != nil { S.log(.cantPower); drain() }; return }
        let p = S.p.power
        sel = nil
        if let t = p.tgt { pending = Pending(kind: .power, valid: S.targetsFor(.p, t), key: nil); return }
        Task {
            busy = true
            await fxAnim(p.fx, from: powerFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: nil, side: .p)
            S.p.mana -= S.pcost(.p); S.p.powerUsed = true
            S.applyFx(.p, p.fx, nil, bonus: S.powerBonus(.p), isPower: true); S.afterPower(.p)
            S.log(.powerUse(p, nil))
            netAct(NetAct(n: 0, t: "power"))
            busy = false
            after()
        }
    }

    func pendingLabel() -> String {
        let base = pending?.key.map(tx.cardName) ?? tx.powerName(myPower)
        if let p = pending, p.need > 1 { return "\(base) \(p.picks.count)/\(p.need)" }
        return base
    }
    /// Missiles fly one after another, a little apart, from the caster to each target.
    func missiles(from: CGPoint?, to targets: [EID]) async {
        await withTaskGroup(of: Void.self) { g in
            for (i, t) in targets.enumerated() { g.addTask { await self.wait(i * 140); await self.projectile(from: from, to: t, color: Color(hex: "#c4b4ff")) } }
        }
    }
    func cancelPending() { pending = nil }

    private func resolvePending(_ t: EID) async {
        guard let p = pending else { return }
        // A multi-target spell keeps asking until all its targets are chosen (the same one may be chosen again).
        if case .spell = p.kind, p.need > p.picks.count + 1 {
            var q = p; q.picks.append(t); pending = q
            S.mark(t); drain(); Haptics.tick()
            return
        }
        pending = nil
        busy = true
        switch p.kind {
        case .spell(let idx):
            guard idx < S.p.hand.count, let c = gd.card(S.p.hand[idx]), let fx = S.cardFx(.p, c.id) else { busy = false; return }
            let targets = p.picks + [t], t0 = targets[0], extra = Array(targets.dropFirst())
            await flyCard(idx, to: center(t0))
            S.pay(.p, c.id)
            S.takeHand(.p, idx)
            drain()
            if extra.isEmpty { await fxAnim(fx, from: center(.hero(.p)), target: t, side: .p) }
            else { await missiles(from: center(.hero(.p)), to: targets) }
            S.castSpell(.p, c.id, t0, extra: extra)
            pushHist(.p, c.id, S.name(t0))
            S.log(.castOn(c.id, S.name(t0)))
            netAct(NetAct(n: 0, t: "cast", i: idx, k: c.id, tgt: netRef(t0), ts: extra.isEmpty ? nil : extra.map { netRef($0)! }))
        case .battlecry(let fx, let src, let hid):
            if let hid, let i = hist.firstIndex(where: { $0.id == hid }) { hist[i].target = S.name(t) }
            await fxAnim(fx, from: center(src), target: t, side: .p)
            S.applyFx(.p, fx, t)
            netAct(NetAct(n: 0, t: "bc", tgt: netRef(t)))
        case .power:
            let pw = S.p.power
            await fxAnim(pw.fx, from: powerFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: t, side: .p)
            S.p.mana -= S.pcost(.p); S.p.powerUsed = true
            S.applyFx(.p, pw.fx, t, bonus: S.powerBonus(.p), isPower: true); S.afterPower(.p)
            S.log(.powerUse(pw, S.name(t)))
            netAct(NetAct(n: 0, t: "power", tgt: netRef(t)))
        }
        busy = false
        after()
    }

    /// A tap on a minion on the board: whatever a tap does (aim, select, attack), and unless it was used to aim or
    /// attack, its card opens in the info panel (a second tap closes it). Works on either turn.
    func tapMinion(_ id: EID, key: String) {
        let aiming = !blocked && (pending?.valid.contains(id) == true || (sel != nil && id.side == .e && S.attackTargets(.p).contains(id)))
        let was = infoKey
        tap(id)
        infoKey = aiming || was == key ? nil : key
    }

    func tap(_ id: EID) {
        hsel = nil
        infoKey = nil
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
        if let d = drag {
            if case .hand = d.src, !d.aboveLine { return false }
            return d.valid.contains(id)
        }
        if sel != nil && id.side == .e { return s.attackTargets(.p).contains(id) }
        return false
    }

    // MARK: - Drag and drop

    /// The hand is fanned out at the bottom during your turn and parked in the corner otherwise.
    var handActive: Bool { state.map { $0.turn == .p && !$0.over && !$0.mulligan } ?? false }

    /// The minion or hero whose tile is under `p` (a little slack around each tile for fingers).
    func entity(at p: CGPoint) -> EID? {
        guard let s = state else { return nil }
        var best: (EID, CGFloat)?
        for (id, f) in frames where s.exists(id) {
            let r = f.insetBy(dx: -6, dy: -6)
            guard r.contains(p) else { continue }
            let d = hypot(p.x - r.midX, p.y - r.midY)
            if best == nil || d < best!.1 { best = (id, d) }
        }
        return best?.0
    }

    /// Minion dropped on the board, or a spell pulled up past the hand: the own board glows.
    var dropGlow: Bool {
        guard let d = drag, case .hand(let i) = d.src, d.aboveLine, let s = state, let c = s.p.hand[safe: i].flatMap(gd.card) else { return false }
        return c.isMinion && s.p.board.count < DuelState.boardMax
    }

    /// Finger moved while holding hand card `i`; `line` is the screen y above which the card counts as played.
    /// A single-target spell is aimed instead of carried: it counts as "up" at once and the arrow from the card
    /// picks the target, like an attack.
    func dragHand(_ i: Int, to p: CGPoint, line: CGFloat) {
        guard handActive, let s = state, let c = s.p.hand[safe: i].flatMap(gd.card) else { drag = nil; return }
        hsel = nil
        var d = drag ?? Drag(src: .hand(i), pt: p)
        d.src = .hand(i); d.pt = p
        d.aboveLine = c.isTargetedSpell || p.y < line
        let playable = !blocked && pending == nil && s.canPay(.p, c.id)
        if playable, let fx = c.fx, let t = fx.tgt {
            d.valid = s.targetsFor(.p, t, fx.cond)
            let o = entity(at: p)
            let over = d.aboveLine ? o.flatMap { d.valid.contains($0) ? $0 : nil } : nil
            if over != d.over, over != nil { Haptics.tick() }
            d.over = over
        } else { d.valid = []; d.over = nil }
        drag = d
    }

    /// Finger lifted while dragging hand card `i`.
    func dropHand(_ i: Int) {
        guard let d = drag, case .hand = d.src else { drag = nil; return }
        withAnimation(.spring(duration: 0.4, bounce: 0.25)) { drag = nil }
        guard d.aboveLine, !blocked, pending == nil, let s = state, let c = s.p.hand[safe: i].flatMap(gd.card) else { return }
        if !s.canPay(.p, c.id) { S.log(.noMana); drain(); Haptics.fail(); return }
        if c.isMinion && s.p.board.count >= DuelState.boardMax { S.log(.boardFull); drain(); Haptics.fail(); return }
        if c.fx?.tgt != nil, d.over == nil, d.valid.isEmpty { S.log(.noTargets); drain(); Haptics.fail(); return }
        // An aimed spell let go away from any target is simply put back.
        if c.isTargetedSpell, d.over == nil { return }
        Haptics.drop()
        playHand(i, target: d.over)
    }

    /// Finger moved while holding one of your minions: aim an attack.
    func dragMinion(_ id: EID, to p: CGPoint) {
        infoKey = nil
        guard !blocked, pending == nil, let m = S.minion(id), m.side == .p, S.canAttack(m) else { drag = nil; return }
        hsel = nil
        if drag == nil { sel = m.uid; Haptics.lift() }
        var d = drag ?? Drag(src: .minion(id), pt: p)
        d.src = .minion(id); d.pt = p; d.aboveLine = true
        d.valid = S.attackTargets(.p)
        let over = entity(at: p).flatMap { d.valid.contains($0) ? $0 : nil }
        if over != d.over, over != nil { Haptics.tick() }
        d.over = over
        drag = d
    }

    func dropMinion() {
        guard let d = drag, case .minion = d.src else { drag = nil; return }
        drag = nil
        if let t = d.over { Haptics.drop(); tap(t) } else { sel = nil; log = nil }
    }

    /// Finger moved while holding the hero power button (only a targeted power drags).
    func dragPower(to p: CGPoint) {
        guard !powerBlocked, let t = S.p.power.tgt else { drag = nil; return }
        if drag == nil { Haptics.lift() }
        var d = drag ?? Drag(src: .power, pt: p)
        d.src = .power; d.pt = p; d.aboveLine = true
        d.valid = S.targetsFor(.p, t)
        let over = entity(at: p).flatMap { d.valid.contains($0) ? $0 : nil }
        if over != d.over, over != nil { Haptics.tick() }
        d.over = over
        drag = d
    }

    func dropPower() {
        guard let d = drag, case .power = d.src else { drag = nil; return }
        drag = nil
        guard let t = d.over, !powerBlocked else { return }
        Haptics.drop()
        pending = Pending(kind: .power, valid: d.valid, key: nil)
        Task { await resolvePending(t) }
    }

    /// Where a targeting arrow starts, if the current drag draws one.
    var arrowFrom: CGPoint? {
        guard let d = drag else { return nil }
        switch d.src {
        case .minion(let id): return center(id)
        case .power: return powerFrame.map { CGPoint(x: $0.midX, y: $0.midY) }
        case .hand(let i):
            guard let c = state?.p.hand[safe: i].flatMap(gd.card), c.isTargetedSpell else { return nil }
            return handFrames[i].map { CGPoint(x: $0.midX, y: $0.midY - 10) }
        }
    }

    /// Tap on the parked hand: fan it out for a moment to read.
    func peekHand() {
        guard !handActive else { return }
        withAnimation(.spring(duration: 0.45, bounce: 0.2)) { handPeek = true }
        let token = gameToken
        Task {
            await wait(3200)
            guard gameToken == token else { return }
            withAnimation(.spring(duration: 0.45)) { handPeek = false }
        }
    }

    func hasMoves() -> Bool {
        guard let s = state else { return false }
        let p = s.p
        return p.hand.contains { k in (gd.card(k).map { s.canPay(.p, k) && ($0.isPrayer ? p.altar.count < s.altarMax(.p) : (!$0.isMinion || p.board.count < DuelState.boardMax)) } ?? false) }
            || p.board.contains(where: s.canAttack) || !powerBlocked
    }

    func endTurn() {
        infoKey = nil
        guard !blocked else { return }
        pending = nil; sel = nil
        if S.mode == .online {
            netAct(NetAct(n: 0, t: "end"))
            S.turn = .e; S.round += 1
            S.startTurn(.e)
            S.log(.eTurn)
            let ended = S.cleanup()
            drain(); netFlush()
            if ended { onGameOver(); return }
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
        return h.id
    }

    // MARK: - Computer opponent

    func aiTurn() async {
        let token = gameToken
        busy = true
        S.round += 1
        S.startTurn(.e)
        S.log(.eTurn)
        S.cleanup(); drain()
        showBanner(tx.bannerFoe, foe: true)
        await wait(900)
        guard gameToken == token else { return }
        for _ in 0..<12 where !S.over {
            var did = false
            for o in S.aiPlayable() {
                S.e.castHb = S.hbOf(.e)[safe: o.index] ?? 0
                guard let plan = S.aiPlan(o.key), let c = gd.card(o.key) else { continue }
                var t = plan
                S.pay(.e, c.id)
                S.takeHand(.e, o.index)
                if c.isMinion {
                    let bc = S.cardBc(.e, c.id)
                    let shown: EID? = (bc?.tgt != nil) ? t : nil
                    S.log(.eSummon(c.id)); drain()
                    reveal = Reveal(side: .e, key: c.id, target: shown.map { S.name($0) })
                    await wait(1100)
                    guard gameToken == token else { return }
                    let m = S.summon(.e, c.id)
                    pushHist(.e, c.id, shown.map { S.name($0) })
                    drain()
                    if let bc, let m {
                        if bc.tgt == .ally && t == nil { t = m.id }
                        if bc.tgt != nil { await aimAt(t) }
                        guard gameToken == token else { return }
                        await fxAnim(bc, from: revealCenter, target: t, side: .e)
                        guard gameToken == token else { return }
                        S.applyFx(.e, bc, t)
                        if bc.reclaim > 0 { S.aiReclaim(.e, bc.reclaim) }
                    }
                    reveal = nil
                } else if let fx = S.cardFx(.e, c.id) {
                    S.log(c.isPrayer ? .ePrayed(c.id) : t.map { .eCastOn(c.id, S.name($0)) } ?? .eCast(c.id)); drain()
                    reveal = Reveal(side: .e, key: c.id, target: t.map { S.name($0) })
                    await wait(1400)
                    guard gameToken == token else { return }
                    pushHist(.e, c.id, t.map { S.name($0) })
                    await aimAt(t)
                    guard gameToken == token else { return }
                    let extra: [EID] = fx.multi > 1 ? Array(S.aiMultiTargets(fx, bonus: S.spellBonus(.e, c.id)).dropFirst()) : []
                    if let t, !extra.isEmpty { await missiles(from: revealCenter, to: [t] + extra) } else { await fxAnim(fx, from: revealCenter, target: t, side: .e) }
                    guard gameToken == token else { return }
                    S.castSpell(.e, c.id, t, extra: extra)
                    if c.rite { S.aiRitePick(.e) }
                    reveal = nil
                }
                did = true
                S.cleanup(); drain()
                await wait(500)
                guard gameToken == token else { return }
                break
            }
            if !did { break }
        }
        if !S.over { await aiPower() }
        guard gameToken == token else { return }
        // Up to three passes, so a minion with several attacks a turn (Sylvara) uses them all.
        for _ in 0..<3 {
            var any = false
            for m in S.e.board {
                if S.over { break }
                guard S.e.board.contains(where: { $0.uid == m.uid }), let cur = S.minion(m.id), S.canAttack(cur) else { continue }
                any = true
                let t = S.aiAttackTarget(cur)
                await lunge(m.id, t)
                guard gameToken == token else { return }
                S.attack(m.id, t)
                S.cleanup(); drain()
                await wait(420)
                guard gameToken == token else { return }
            }
            if !any || S.over { break }
        }
        if S.over { busy = false; onGameOver(); return }
        S.turn = .p
        S.startTurn(.p)
        busy = false
        S.log(.yourTurn)
        if S.cleanup() { drain(); onGameOver(); return }
        drain()
        showBanner(tx.bannerYou, foe: false)
    }

    private var revealCenter: CGPoint? { revealFrame.map { CGPoint(x: $0.midX, y: $0.midY) } }

    private func aiPower() async {
        let token = gameToken
        guard let plan = S.aiPowerPlan() else { return }
        let p = S.e.power
        S.e.mana -= S.pcost(.e); S.e.powerUsed = true
        if let t = plan { await aimAt(t) }
        guard gameToken == token else { return }
        await fxAnim(p.fx, from: epowFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: plan, side: .e)
        guard gameToken == token else { return }
        S.applyFx(.e, p.fx, plan, bonus: S.powerBonus(.e), isPower: true); S.afterPower(.e)
        S.log(.ePower(p, plan.map { S.name($0) }))
        S.cleanup(); drain()
        await wait(600)
        guard gameToken == token else { return }
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
        if S.mulligan { tryOnlineMulligan() }
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
        run = Run(stage: 0, deck: s.p.deck, cls: s.pcls, tal: s.p.tal)
        scene = Scenes.random()
        resetDuelUI()
        netOut = []; turnActs = []; netN = 0; appliedN = 0; seq = 0; netQueue = []
        o.lost = nil; o.conceded = false; o.concedeArm = false; o.again = false; o.foeAgain = false
        state = s
        drain()
        go(.duel)
        let first = s.turn
        mullCont = { [self] in
            S[first.other].hand.append("coin")
            S.startTurn(first)
            S.log(first == .p ? .goFirst : .goSecond); drain()
            showBanner(first == .p ? tx.bannerYou : tx.bannerFoe, foe: first != .p)
        }
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
            if S.cleanup() { drain(); onGameOver(); return }
            drain()
            showBanner(tx.bannerYou, foe: false)
            return
        }
        busy = true
        defer { busy = false }
        switch a.t {
        case "play", "cast":
            guard let i = a.i, i < S.e.hand.count, S.e.hand[i] == a.k, let c = gd.card(S.e.hand[i]) else { throw NetError.outOfStep }
            S.pay(.e, c.id)
            S.takeHand(.e, i)
            if c.isMinion {
                S.log(.eSummon(c.id)); drain()
                reveal = Reveal(side: .e, key: c.id)
                await wait(900)
                let m = S.summon(.e, c.id)
                let hid = pushHist(.e, c.id, nil)
                if let m { lastEnemyMinion = (m.uid, hid) }
                drain()
                if let bc = S.cardBc(.e, c.id), bc.tgt == nil, let m {
                    await fxAnim(bc, from: revealCenter, target: nil, side: .e); S.applyFx(.e, bc, nil); _ = m
                }
                reveal = nil
            } else if let fx = S.cardFx(.e, c.id) {
                let t = netDeref(a.tgt)
                if a.tgt != nil && t == nil { throw NetError.outOfStep }
                let extra = try (a.ts ?? []).map { r -> EID in guard let x = netDeref(r) else { throw NetError.outOfStep }; return x }
                S.log(c.isPrayer ? .ePrayed(c.id) : t.map { .eCastOn(c.id, S.name($0)) } ?? .eCast(c.id)); drain()
                reveal = Reveal(side: .e, key: c.id, target: t.map { S.name($0) })
                await wait(1100)
                pushHist(.e, c.id, t.map { S.name($0) })
                if t != nil { await aimAt(t) }
                if let t, !extra.isEmpty { await missiles(from: revealCenter, to: [t] + extra) } else { await fxAnim(fx, from: revealCenter, target: t, side: .e) }
                S.castSpell(.e, c.id, t, extra: extra)
                reveal = nil
            }
        case "pick":
            S.reclaimTake(.e, a.ks ?? [])
        case "rite":
            guard let k = a.ks?.first else { throw NetError.outOfStep }
            S.ritePick(.e, k)
        case "bc":
            guard let last = lastEnemyMinion, let m = S.minion(EID(side: .e, uid: last.uid)), let fx = S.cardBc(.e, m.key) else { throw NetError.outOfStep }
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
            S.e.mana -= S.pcost(.e); S.e.powerUsed = true
            if t != nil { await aimAt(t) }
            await fxAnim(p.fx, from: epowFrame.map { CGPoint(x: $0.midX, y: $0.midY) }, target: t, side: .e)
            S.applyFx(.e, p.fx, t, bonus: S.powerBonus(.e), isPower: true); S.afterPower(.e)
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
        o.slow = idle > 25 && screen == .duel && !S.over   // two missed heartbeats
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

    /// Adventure and AI matches: leave for the main menu after a second tap. The game is marked over (so an AI
    /// turn still running stops at its next check) and counts as neither a win nor a loss.
    func quitDuel() {
        guard state != nil, S.mode != .online else { return }
        if !quitArm {
            quitArm = true
            Task { await wait(3000); quitArm = false }
            return
        }
        quitArm = false
        abandoned = true
        S.over = true
        pending = nil; sel = nil; hsel = nil; reveal = nil; banner = nil; zoomCard = nil
        run = Run()
        go(.intro)
    }

    // MARK: - Opening mulligan

    func toggleChoice(_ i: Int) {
        guard var c = choice else { return }
        if c.picks.contains(i) { c.picks.remove(i) } else if c.picks.count < c.n { c.picks.insert(i) }
        choice = c
    }
    func confirmChoice() {
        guard let c = choice, c.picks.count == c.n else { return }
        choice = nil
        let ks = c.picks.sorted().map { c.offer[$0] }
        if c.rite, let k = ks.first {
            S.ritePick(.p, k)
            netAct(NetAct(n: 0, t: "rite", ks: ks))
        } else {
            S.reclaimTake(.p, ks)
            netAct(NetAct(n: 0, t: "pick", ks: ks))
        }
        after()
    }

    func toggleMulligan(_ i: Int) {
        guard state?.mulligan == true, mullMine == nil else { return }
        if mullPicks.contains(i) { mullPicks.remove(i) } else { mullPicks.insert(i) }
    }

    func confirmMulligan() {
        guard state?.mulligan == true, mullMine == nil else { return }
        let mine = mullPicks.sorted()
        mullMine = mine
        if S.mode == .online {
            let m = match
            Task { try? await m?.sendMulligan(mine) }
            tryOnlineMulligan()
            return
        }
        S.applyMulligan(.p, mine)
        S.applyMulligan(.e, S.aiMulliganPicks(.e))
        finishMulligan()
    }

    /// Online: both players' choices are in the match document; apply them in the same way on both phones.
    private func tryOnlineMulligan() {
        guard state?.mulligan == true, let mine = mullMine, let m = match, let foe = m.doc?.mull?[m.foeUid] else { return }
        S.applyMulligan(.p, mine)
        S.applyMulligan(.e, foe)
        finishMulligan()
    }

    private func finishMulligan() {
        S.mulligan = false
        mullPicks = []; mullMine = nil
        let c = mullCont; mullCont = nil
        drain()
        c?()
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
        let st = DuelState.onlineStart(hostCls: d.hc, hostDeck: d.hDeck, hostTal: d.hTal ?? [], guestCls: d.gc, guestDeck: d.gDeck, guestTal: d.gTal ?? [])
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
