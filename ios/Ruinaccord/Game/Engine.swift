import Foundation

enum Side: String, Codable, Hashable {
    case p, e
    var other: Side { self == .p ? .e : .p }
}

/// Identifies a hero (uid == nil) or a minion on the board.
struct EID: Hashable, Codable, CustomStringConvertible {
    let side: Side
    let uid: Int?
    var isHero: Bool { uid == nil }
    static func hero(_ s: Side) -> EID { EID(side: s, uid: nil) }
    var description: String { uid.map { "\(side.rawValue):m:\($0)" } ?? "\(side.rawValue):h" }
}

struct Minion: Codable, Hashable, Identifiable {
    var uid: Int
    var key: String
    var side: Side
    var atk: Int
    var hp: Int
    var max: Int
    var baseAtk: Int
    var baseHp: Int
    var hasGuard: Bool
    var ward: Bool
    var sleep: Bool
    var attacked: Bool
    /// Turns it still misses (Permafrost freezes for two).
    var frozen = 0
    var silenced = false     // lost its keywords and card effects
    var tmp = 0              // Attack that wears off when this turn ends
    var bled = false         // already got the Bloodied bonus
    var hits = 0             // attacks made this turn (Sylvara has three)
    var id: EID { EID(side: side, uid: uid) }
    var isFrozen: Bool { frozen > 0 }
    /// Card effects still active (a silenced minion has none).
    var gasp: String? { silenced ? nil : card.gasp }
    var spellDamage: Int { silenced ? 0 : card.sp }
    var onSpell: [Int]? { silenced ? nil : card.onSpell }
    var card: Card { GameData.shared.card(key)! }

    private enum CodingKeys: String, CodingKey { case uid, key, side, atk, hp, max, baseAtk, baseHp, hasGuard, ward, sleep, attacked, frozen, silenced, tmp, bled, hits }
    init(uid: Int, key: String, side: Side, atk: Int, hp: Int, max: Int, baseAtk: Int, baseHp: Int, hasGuard: Bool, ward: Bool, sleep: Bool, attacked: Bool) {
        self.uid = uid; self.key = key; self.side = side; self.atk = atk; self.hp = hp; self.max = max; self.baseAtk = baseAtk; self.baseHp = baseHp
        self.hasGuard = hasGuard; self.ward = ward; self.sleep = sleep; self.attacked = attacked
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uid = try c.decode(Int.self, forKey: .uid); key = try c.decode(String.self, forKey: .key); side = try c.decode(Side.self, forKey: .side)
        atk = try c.decode(Int.self, forKey: .atk); hp = try c.decode(Int.self, forKey: .hp); max = try c.decode(Int.self, forKey: .max)
        baseAtk = try c.decode(Int.self, forKey: .baseAtk); baseHp = try c.decode(Int.self, forKey: .baseHp)
        hasGuard = try c.decode(Bool.self, forKey: .hasGuard); ward = try c.decode(Bool.self, forKey: .ward)
        sleep = try c.decode(Bool.self, forKey: .sleep); attacked = try c.decode(Bool.self, forKey: .attacked)
        if let n = try? c.decodeIfPresent(Int.self, forKey: .frozen) { frozen = n } else if let b = try? c.decodeIfPresent(Bool.self, forKey: .frozen) { frozen = b ? 1 : 0 }
        silenced = try c.decodeIfPresent(Bool.self, forKey: .silenced) ?? false
        tmp = try c.decodeIfPresent(Int.self, forKey: .tmp) ?? 0
        bled = try c.decodeIfPresent(Bool.self, forKey: .bled) ?? false
        hits = try c.decodeIfPresent(Int.self, forKey: .hits) ?? 0
    }
}

/// A Prayer waiting on the altar.
struct AltarSlot: Codable, Hashable {
    var key: String
    var cd: Int
}

/// Talent counters that reset every turn.
struct TurnFlags: Codable, Hashable {
    var fire = false      // a Fire spell was cast (Kindle)
    var pain = false      // Agony fired
    var bm = false        // Blood Mana fired
    var tide = false      // Corpse Tide fired
    var bar = false       // Ice Ward fired
    var wh = false        // Whistle fired
    var sd = 0            // Sanctuary draws so far
    var sum = 0           // minions summoned
    var played = 0        // cards played
    var deaths = 0        // own minions that died
    var pw = false        // Rapid Fire's first hero power use
}

struct Hero: Codable, Hashable {
    var side: Side
    var hp: Int
    var max: Int
    var armor = 0
    var mana = 0
    var maxMana = 0
    /// Unspent mana banked for spells (up to 3, or 5 with Banked Heat).
    var spellMana = 0
    var deck: [String]
    var hand: [String] = []
    var board: [Minion] = []
    var fat = 0
    var powerUsed = false
    var power: Power
    /// Class of this side, nil for an Adventure foe.
    var cls: String?
    /// Prayers waiting to resolve.
    var altar: [AltarSlot] = []
    /// Keys of minions that died (for Revive), oldest first.
    var grave: [String] = []
    /// Chosen talents, and the card changes they make.
    var tal: [String] = []
    var ovr: [String: CardOverride] = [:]
    /// Spell Surge boosts per card in hand (kept in step with the hand); `castHb` is the boost of the spell being cast.
    var hb: [Int] = []
    var castHb = 0
    var tf = TurnFlags()
    /// Class resources: Rage (Warrior), Souls (Warlock), Light (Priest); Unity counters (Paladin talent).
    var rage = 0, soul = 0, light = 0, fero = 0, coopN = 0, coopB = 0
    /// Paladin Prestige.
    var pres = 0
    var firstSum = false
    /// Blood Rites cast this game, and the copies in hand that cost (0), per card.
    var rites = 0
    var free: [String: Int] = [:]
    var id: EID { .hero(side) }

    func has(_ talent: String) -> Bool { tal.contains(talent) }
    var hasTalents: Bool { !tal.isEmpty }

    private enum CodingKeys: String, CodingKey {
        case side, hp, max, armor, mana, maxMana, spellMana, deck, hand, board, fat, powerUsed, power, cls, altar, grave, tal, ovr, hb, castHb, tf, rage, soul, light, fero, coopN, coopB, firstSum, rites, free, pres
    }
    init(side: Side, hp: Int, max: Int, deck: [String], power: Power) {
        self.side = side; self.hp = hp; self.max = max; self.deck = deck; self.power = power
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        side = try c.decode(Side.self, forKey: .side); hp = try c.decode(Int.self, forKey: .hp); max = try c.decode(Int.self, forKey: .max)
        armor = try c.decode(Int.self, forKey: .armor); mana = try c.decode(Int.self, forKey: .mana); maxMana = try c.decode(Int.self, forKey: .maxMana)
        spellMana = try c.decodeIfPresent(Int.self, forKey: .spellMana) ?? 0
        deck = try c.decode([String].self, forKey: .deck); hand = try c.decode([String].self, forKey: .hand); board = try c.decode([Minion].self, forKey: .board)
        fat = try c.decode(Int.self, forKey: .fat); powerUsed = try c.decode(Bool.self, forKey: .powerUsed); power = try c.decode(Power.self, forKey: .power)
        cls = try c.decodeIfPresent(String.self, forKey: .cls)
        altar = try c.decodeIfPresent([AltarSlot].self, forKey: .altar) ?? []
        grave = try c.decodeIfPresent([String].self, forKey: .grave) ?? []
        tal = try c.decodeIfPresent([String].self, forKey: .tal) ?? []
        ovr = try c.decodeIfPresent([String: CardOverride].self, forKey: .ovr) ?? [:]
        hb = try c.decodeIfPresent([Int].self, forKey: .hb) ?? []
        castHb = try c.decodeIfPresent(Int.self, forKey: .castHb) ?? 0
        tf = try c.decodeIfPresent(TurnFlags.self, forKey: .tf) ?? TurnFlags()
        rage = try c.decodeIfPresent(Int.self, forKey: .rage) ?? 0; soul = try c.decodeIfPresent(Int.self, forKey: .soul) ?? 0
        light = try c.decodeIfPresent(Int.self, forKey: .light) ?? 0; fero = try c.decodeIfPresent(Int.self, forKey: .fero) ?? 0
        coopN = try c.decodeIfPresent(Int.self, forKey: .coopN) ?? 0; coopB = try c.decodeIfPresent(Int.self, forKey: .coopB) ?? 0
        firstSum = try c.decodeIfPresent(Bool.self, forKey: .firstSum) ?? false
        rites = try c.decodeIfPresent(Int.self, forKey: .rites) ?? 0
        pres = try c.decodeIfPresent(Int.self, forKey: .pres) ?? 0
        free = try c.decodeIfPresent([String: Int].self, forKey: .free) ?? [:]
    }
}

enum GameMode: String, Codable { case camp, quick, online }
enum GameResult: String, Codable { case win, lose, draw }

/// A name that can be resolved in any language at display time.
enum NameRef: Hashable {
    case hero(Side)
    case card(String)
}

/// Messages shown in the duel log, resolved by the view model in the current language.
enum LogEntry: Hashable {
    case rises, fatigue(Side, Int), handFull(String), summon(String), cast(String), castOn(String, NameRef)
    case attacks(NameRef, NameRef), burst(String), sinks, falls, noMana, boardFull, noTargets
    case ready(String), already(String), noAtk(String), nextTurn(String), guardWay, info(String, Int, Int)
    case eTurn, eSummon(String), eCast(String), eCastOn(String, NameRef), yourTurn, goFirst, goSecond
    case powerUse(Power, NameRef?), ePower(Power, NameRef?), cantPower
    case prayed(String), ePrayed(String), prayerDone(Side, String), altarFull
}

enum FloatKind: Hashable {
    case dmg(Int), armorAbsorb(Int), ward, heal(Int), armorGain(Int), atkUp(Int), hpUp(Int)
    case frozen, silenced, destroyed, stats(Int, Int)
    case answered, revived, rage, named(String), manaUp(Int), light(Int), soulPay, fero, rite(Int), ether, immune, mark, prestige(Int), prestigeGo
    var isHit: Bool { switch self { case .dmg, .armorAbsorb, .ward: return true; default: return false } }
}

enum GameEvent {
    case float(EID, FloatKind)
    case died(Minion)
    case log(LogEntry)
    case drew(Side)
}

/// Everything two players must agree on. Codable so an online match can be stored and compared.
struct DuelState: Codable {
    var mode: GameMode
    var pcls: String
    var ecls: String?
    var diff: Difficulty?
    var stage = 0
    var turn: Side = .p
    var over = false
    var opened = false
    /// Hands are dealt and players are choosing cards to replace; the first turn has not started.
    var mulligan = false
    var round = 0
    var nextUid = 0
    var p: Hero
    var e: Hero
    /// Death resolution order (host side first online, so token ids stay in step).
    var order: [Side] = [.p, .e]
    var result: GameResult?

    /// Transient UI events produced by rule functions; drained by the view model, never stored.
    var events: [GameEvent] = []
    /// The side whose effect is resolving (not saved): a Shadow Touch Priest's damage turns into Light.
    var fxSide: Side?

    private enum CodingKeys: String, CodingKey { case mode, pcls, ecls, diff, stage, turn, over, opened, mulligan, round, nextUid, p, e, order, result }

    static let boardMax = GameData.shared.boardMax
    static var gd: GameData { GameData.shared }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decode(GameMode.self, forKey: .mode)
        pcls = try c.decode(String.self, forKey: .pcls)
        ecls = try c.decodeIfPresent(String.self, forKey: .ecls)
        diff = try c.decodeIfPresent(Difficulty.self, forKey: .diff)
        stage = try c.decodeIfPresent(Int.self, forKey: .stage) ?? 0
        turn = try c.decode(Side.self, forKey: .turn)
        over = try c.decode(Bool.self, forKey: .over)
        opened = try c.decode(Bool.self, forKey: .opened)
        mulligan = try c.decodeIfPresent(Bool.self, forKey: .mulligan) ?? false
        round = try c.decode(Int.self, forKey: .round)
        nextUid = try c.decode(Int.self, forKey: .nextUid)
        p = try c.decode(Hero.self, forKey: .p)
        e = try c.decode(Hero.self, forKey: .e)
        order = try c.decodeIfPresent([Side].self, forKey: .order) ?? [.p, .e]
        result = try c.decodeIfPresent(GameResult.self, forKey: .result)
    }

    init(mode: GameMode, pcls: String, ecls: String? = nil, diff: Difficulty? = nil, stage: Int = 0, p: Hero, e: Hero) {
        self.mode = mode; self.pcls = pcls; self.ecls = ecls; self.diff = diff; self.stage = stage; self.p = p; self.e = e
        self.p.cls = pcls; self.e.cls = ecls
    }

    static func makeHero(_ side: Side, hp: Int, deck: [String], power: Power) -> Hero {
        Hero(side: side, hp: hp, max: hp, deck: deck, power: power)
    }

    subscript(_ s: Side) -> Hero {
        get { s == .p ? p : e }
        set { if s == .p { p = newValue } else { e = newValue } }
    }

    func minion(_ id: EID) -> Minion? {
        guard let uid = id.uid else { return nil }
        return self[id.side].board.first { $0.uid == uid }
    }
    func exists(_ id: EID) -> Bool { id.isHero || minion(id) != nil }
    func hp(_ id: EID) -> Int { id.isHero ? self[id.side].hp : (minion(id)?.hp ?? 0) }
    func atk(_ id: EID) -> Int { id.isHero ? 0 : (minion(id)?.atk ?? 0) }
    func maxHp(_ id: EID) -> Int { id.isHero ? self[id.side].max : (minion(id)?.max ?? 0) }
    func name(_ id: EID) -> NameRef { id.isHero ? .hero(id.side) : .card(minion(id)?.key ?? "") }

    mutating func log(_ l: LogEntry) { events.append(.log(l)) }
    private mutating func float(_ id: EID, _ k: FloatKind) { events.append(.float(id, k)) }
    /// A chosen target of a multi-target spell, shown with a star.
    mutating func mark(_ id: EID) { float(id, .mark) }

    // MARK: - Talents: setup and lookups

    func tal(_ side: Side, _ id: String) -> Bool { self[side].tal.contains(id) }

    /// Applies a talent list to a side: Health, hero power and card overrides.
    mutating func setupTalents(_ side: Side, cls: String?, _ sel: [String]) {
        let gd = Self.gd
        let ok = cls.map { gd.hasTalents($0) && gd.validTalents($0, sel) } ?? false
        self[side].tal = ok ? sel : []
        self[side].ovr = gd.overrides(for: self[side].tal)
        self[side].hb = []; self[side].castHb = 0; self[side].tf = TurnFlags()
        self[side].cls = cls
        if tal(side, "wl_flesh") { self[side].hp += 2; self[side].max += 2 }
        if tal(side, "fr_blood") { self[side].hp += 7; self[side].max += 7 }
        if tal(side, "wa_reckless") { self[side].hp -= 3; self[side].max -= 3 }
        if tal(side, "ho_devout") { self[side].hp += 6; self[side].max += 6 }
        var p = cls.flatMap { gd.cls($0)?.power } ?? self[side].power
        func mod(_ f: (inout Effect) -> Void) { var fx = p.fx; f(&fx); p = Power(cost: p.cost, tgt: p.tgt, fx: fx, names: p.names) }
        if tal(side, "fi_spark") { mod { $0.dmg = 2 } }
        if tal(side, "fr_spark") { mod { $0.freeze = true } }
        if tal(side, "sh_touch"), let n = gd.talentNode("sh_touch") { var fx = Effect(); fx.dmg = 2; p = Power(cost: p.cost, tgt: .minion, fx: fx, names: n.names) }
        if tal(side, "ho_pray") { mod { $0.hasten = 1 } }
        if tal(side, "wa_heavy") { mod { $0.armor += 1 } }
        if tal(side, "wa_roar"), let n = gd.talentNode("wa_roar") { var fx = Effect(); fx.tempAtk = 2; p = Power(cost: 2, tgt: .ally, fx: fx, names: n.names) }
        if tal(side, "pa_double") { var fx = p.fx; fx.summon = ["minnow", "minnow"]; p = Power(cost: 3, tgt: p.tgt, fx: fx, names: p.names) }
        if tal(side, "pa_lightcall") { mod { $0.wardSummon = true } }
        if tal(side, "hu_master"), let n = gd.talentNode("hu_master") { var fx = Effect(); fx.summon = ["phound"]; p = Power(cost: 2, tgt: nil, fx: fx, names: n.names) }
        if tal(side, "hu_pierce") {
            if p.fx.face > 0 { var fx = p.fx; fx.dmg = fx.face; fx.face = 0; p = Power(cost: p.cost, tgt: .enemy, fx: fx, names: p.names) }
            mod { $0.pierce = true }
        }
        if tal(side, "wl_tap") { mod { $0.selfDmg = 3; $0.draw = 2 } }
        self[side].power = p
    }

    /// Opening-hand talents, after the hands are dealt.
    mutating func talOpen(_ side: Side) {
        guard self[side].hasTalents else { return }
        if tal(side, "fi_bank") { self[side].spellMana = 1 }
        if tal(side, "wa_tough") { self[side].armor += 7 }
        if tal(side, "wa_reckless") { draw(side, 1) }
    }

    func override(_ side: Side, _ k: String) -> CardOverride? { self[side].ovr[k] }
    func cardFx(_ side: Side, _ k: String) -> Effect? { override(side, k)?.fx ?? Self.gd.card(k)?.fx }
    func cardBc(_ side: Side, _ k: String) -> Effect? { override(side, k)?.bc ?? Self.gd.card(k)?.bc }
    func cardPray(_ side: Side, _ k: String) -> Prayer? { override(side, k)?.pray ?? Self.gd.card(k)?.pray }
    func costOf(_ side: Side, _ k: String) -> Int {
        if self[side].free[k, default: 0] > 0 { return 0 }
        var c = override(side, k)?.cost ?? Self.gd.card(k)?.cost ?? 0
        if tal(side, "hu_combo") && self[side].tf.played >= 2 { c = Swift.max(0, c - 1) }
        return c
    }
    /// Hero power cost (Formation: 1 less with a full board).
    func pcost(_ side: Side) -> Int { Swift.max(0, self[side].power.cost - (tal(side, "pa_array") && self[side].board.count >= 5 ? 1 : 0)) }
    /// Hero power damage from Marksman minions.
    func powerBonus(_ side: Side) -> Int { self[side].board.reduce(0) { $0 + ($1.silenced ? 0 : $1.card.pw) } }
    func altarMax(_ side: Side) -> Int { tal(side, "ho_altar") ? 3 : 2 }
    /// Spell mana is a Mage thing: other classes bank nothing.
    func smCap(_ side: Side) -> Int { self[side].cls == "mage" ? (tal(side, "fi_bank") ? 5 : 3) : 0 }

    // Class resources. Warrior: Rage from using the hero power and from hero damage (cap 5); 3 at the start of
    // a turn (3 with Seething) burst into +2 Attack for the board. Warlock: Souls from friendly deaths (cap 7);
    // Blood Pact spends 2 instead of hurting, 5 at the end of a turn become a Bone Warrior. Priest: healing past
    // full becomes Light (cap 5); 2 Light take a turn off a Prayer as it goes on the altar.
    // Hunter: Ferocity at the start of a turn, one per Beast in hand (cap 5); the hero power spends 2 for +1
    // damage (up to +2), and a Beast played with 3 banked spends 3 to Charge. Paladin: Oaths are Prayers.
    static let rageCap = 5, rageNeed = 4, soulCap = 7, lightCap = 5, feroCap = 5, presCap = 5, presNeed = 3
    func isCls(_ side: Side, _ c: String) -> Bool { self[side].cls == c }
    mutating func addRage(_ side: Side, _ n: Int) { if isCls(side, "warrior") { self[side].rage = Swift.min(Self.rageCap, self[side].rage + n) } }
    /// Bulwark: when short on mana, every 3 Armor pays for 1.
    func armorMana(_ side: Side) -> Int { tal(side, "wa_bulwark") ? self[side].armor / 3 : 0 }

    /// Spell Surge boosts, one per card in hand.
    mutating func hbOf(_ side: Side) -> [Int] {
        let n = self[side].hand.count
        while self[side].hb.count < n { self[side].hb.append(0) }
        if self[side].hb.count > n { self[side].hb.removeLast(self[side].hb.count - n) }
        return self[side].hb
    }
    /// Removes card `i` from the hand to play it (keeps the boosts in step and counts the play).
    @discardableResult
    mutating func takeHand(_ side: Side, _ i: Int) -> String {
        _ = hbOf(side)
        self[side].castHb = self[side].hb[safe: i] ?? 0
        if self[side].hb.indices.contains(i) { self[side].hb.remove(at: i) }
        self[side].tf.played += 1
        let k = self[side].hand.remove(at: i)
        if self[side].free[k, default: 0] > 0 { self[side].free[k]! -= 1 }
        // Hunter Energy comes only from talents: Tamer for each Beast card played, Quiver for each Hunter attack spell.
        if isCls(side, "hunter"), let c = Self.gd.card(k), !c.token,
           (tal(side, "hu_tame") && c.race == "beast") || (tal(side, "hu_quiver") && !c.isMinion && c.cls == "hunter" && (c.fx?.dmg ?? 0) > 0) {
            self[side].fero = Swift.min(Self.feroCap, self[side].fero + 1); float(.hero(side), .light(1))
        }
        return k
    }

    mutating func afterPower(_ side: Side) {
        addRage(side, 1)
        // Rapid Fire: the first use of the turn leaves the power ready for a second.
        if tal(side, "hu_rapid") && !self[side].tf.pw { self[side].tf.pw = true; self[side].powerUsed = false }
        if tal(side, "fr_armor") { self[side].armor += 2; float(.hero(side), .armorGain(2)) }
    }

    /// Self-damage triggers (Agony, Blood Mana).
    mutating func selfHurt(_ side: Side) {
        if tal(side, "wl_pain") && !self[side].tf.pain { self[side].tf.pain = true; damage(.hero(side.other), 2) }
        if tal(side, "wl_bloodmana") && !self[side].tf.bm { self[side].tf.bm = true; self[side].mana += 1 }
    }

    /// Deaths of a side's minions (Souls, Corpse Tide, Soul Harvest).
    mutating func talDeaths(_ side: Side, _ n: Int) {
        if isCls(side, "warlock") { self[side].soul = Swift.min(Self.soulCap, self[side].soul + n) }
        guard self[side].hasTalents else { return }
        let d0 = self[side].tf.deaths
        self[side].tf.deaths = d0 + n
        if tal(side, "wl_tide") && !self[side].tf.tide { self[side].tf.tide = true; summon(side, "skeleton") }
        if tal(side, "wl_harvest") && d0 < 2 && d0 + n >= 2 { draw(side, 1) }
    }

    /// Per-minion talent changes when it enters (stat bonuses, Ward, counters).
    private mutating func talSummon(_ side: Side, _ m: inout Minion, _ c: Card) {
        func h(_ id: String) -> Bool { tal(side, id) }
        // The boosts a hand card already shows, then the situational ones.
        var (a, hp) = Self.gd.statBonus(c, tal: self[side].tal)
        let key = c.id
        if key == "knight" && h("pa_vshield") { m.ward = true }
        if !c.token && h("pa_first") && !self[side].firstSum { self[side].firstSum = true; m.ward = true }
        self[side].tf.sum += 1
        if self[side].tf.sum == 3 && h("pa_step") { a += 1; hp += 1 }
        if c.race == "beast" && h("hu_wild") && self[side].tf.played >= 2 { m.sleep = false }
        if c.token && h("pa_banner") && !self[side].board.isEmpty { self[side].board[0].atk += 1 }
        if !c.token && c.race == "beast" && h("hu_whistle") && !self[side].tf.wh && self[side].hand.count < 10 && Self.gd.card("whistle") != nil {
            self[side].tf.wh = true; self[side].hand.append("whistle")
        }
        m.atk += a; m.hp += hp; m.max += hp
    }

    // MARK: - Turn flow

    mutating func startTurn(_ side: Side) {
        // The side whose turn just ended banks its unspent mana as spell mana (Mage only), its frozen minions thaw
        // (Permafrost keeps one a turn longer) and temporary Attack wears off.
        let o = side.other
        self[o].spellMana = Swift.min(smCap(o), self[o].spellMana + Swift.max(0, self[o].mana))
        self[o].mana = 0
        for i in self[o].board.indices {
            self[o].board[i].frozen = Swift.max(0, self[o].board[i].frozen - 1)
            self[o].board[i].atk -= self[o].board[i].tmp
            self[o].board[i].tmp = 0
        }
        self[side].tf = TurnFlags(); self[o].tf = TurnFlags()
        // Paladin Prestige: the side whose turn ended gains 1 per buffed minion it still has, up to 2 a turn.
        if isCls(o, "paladin") {
            let n = Swift.min(2, self[o].board.filter { $0.atk > $0.baseAtk || $0.max > $0.baseHp }.count)
            if n > 0 { self[o].pres = Swift.min(Self.presCap, self[o].pres + n); float(.hero(o), .prestige(n)) }
        }
        if isCls(o, "warlock") && self[o].soul >= 5 {
            self[o].soul -= 5
            if let m = summon(o, "bonewarr") {
                if tal(o, "wl_soul"), let i = self[o].board.firstIndex(where: { $0.uid == m.uid }) {
                    self[o].board[i].atk = 3; self[o].board[i].hp = 3; self[o].board[i].max = 3; self[o].board[i].baseAtk = 3; self[o].board[i].baseHp = 3; self[o].board[i].sleep = false
                }
                float(m.id, .revived)
            }
        }
        let rageNeed = Self.rageNeed - (tal(side, "wa_fury") ? 1 : 0)
        if isCls(side, "warrior") && self[side].rage >= rageNeed {
            self[side].rage -= rageNeed
            for i in self[side].board.indices { self[side].board[i].atk += 2; self[side].board[i].tmp += 2 }
            if tal(side, "wa_fury") { self[side].armor += 3; float(.hero(side), .armorGain(3)) }
            float(.hero(side), .rage)
        }
        self[side].maxMana = Swift.min(10, self[side].maxMana + 1)
        self[side].mana = self[side].maxMana
        self[side].powerUsed = false
        for i in self[side].board.indices { self[side].board[i].sleep = false; self[side].board[i].attacked = self[side].board[i].isFrozen; self[side].board[i].hits = 0 }
        haunt(side)
        tickAltar(side, 1)
        // Whoever goes first skips the draw on the opening turn.
        if opened { draw(side, 1) } else { opened = true }
    }

    mutating func draw(_ side: Side, _ n: Int) {
        for _ in 0..<n {
            if self[side].deck.isEmpty {
                self[side].fat += 1
                let f = self[side].fat
                damage(.hero(side), f)
                log(.fatigue(side, f))
                continue
            }
            let k = self[side].deck.removeLast()
            if self[side].hand.count >= 10 {
                if side == .p { log(.handFull(k)) }
            } else {
                self[side].hand.append(k)
                events.append(.drew(side))
            }
        }
    }

    @discardableResult
    mutating func summon(_ side: Side, _ key: String) -> Minion? {
        guard self[side].board.count < Self.boardMax, let c = Self.gd.card(key) else { return nil }
        nextUid += 1
        var m = Minion(uid: nextUid, key: key, side: side, atk: c.atk ?? 0, hp: c.hp ?? 0, max: c.hp ?? 0,
                       baseAtk: c.atk ?? 0, baseHp: c.hp ?? 0, hasGuard: c.hasGuard, ward: c.ward, sleep: !c.surge, attacked: false)
        if self[side].hasTalents { talSummon(side, &m, c) }
        if isCls(side, "hunter") && c.race == "beast" && !c.token && m.sleep && self[side].fero >= 3 { self[side].fero -= 3; m.sleep = false; float(m.id, .fero) }
        self[side].board.append(m)
        return m
    }

    /// Ethereal minions (Wraith Ferryman) take no damage from attacks or hero powers (`phys`); spells and card effects hurt them.
    func isEther(_ id: EID) -> Bool { minion(id).map { $0.card.ether && !$0.silenced } ?? false }
    /// Spellproof minions (Ignaroth) take no damage from spells.
    func isSpellward(_ id: EID) -> Bool { minion(id).map { $0.card.spellward && !$0.silenced } ?? false }
    mutating func damage(_ id: EID, _ n: Int, pierce: Bool = false, phys: Bool = false, spell: Bool = false) {
        guard n > 0 else { return }
        if phys && isEther(id) { float(id, .ether); return }
        if spell && isSpellward(id) { float(id, .immune); return }
        var n = n
        let own = id.side
        if id.isHero { addRage(own, 1) }
        if id.isHero {
            var h = self[own]
            let a = pierce ? 0 : Swift.min(h.armor, n)
            h.armor -= a
            let rest = n - a
            h.hp -= rest
            self[own] = h
            float(id, rest > 0 ? .dmg(rest) : .armorAbsorb(a))
            shadowLight(own, rest)
        } else if let i = self[own].board.firstIndex(where: { $0.uid == id.uid }) {
            if self[own].board[i].ward && !pierce {
                self[own].board[i].ward = false
                float(id, .ward)
                if tal(own, "pa_echo") { heal(.hero(own), 2) }
                if tal(own, "pa_sanct") && self[own].tf.sd < 3 { self[own].tf.sd += 1; draw(own, 1); heal(.hero(own), 2) }
            } else {
                if self[own].board[i].isFrozen {
                    let fo = own.other
                    n += (tal(fo, "fr_deep") ? 2 : 0) + (tal(fo, "fr_perma") ? 1 : 0)
                }
                self[own].board[i].hp -= n
                float(id, .dmg(n))
                shadowLight(own, n)
                if !self[own].board[i].bled && tal(own, "wa_bloodied") { self[own].board[i].bled = true; self[own].board[i].atk += 1 }
            }
        }
    }

    /// Wraith Ferryman: at the start of its owner's turn, one minion of the grave returns to the hand. The pick is
    /// a hash of the state rather than a random draw so both copies of an online match agree.
    mutating func haunt(_ side: Side) {
        guard self[side].board.contains(where: { $0.card.haunt && !$0.silenced }) else { return }
        let s = self[side]
        let g = s.grave.indices.filter { Self.gd.card(s.grave[$0])?.token == false }
        guard !g.isEmpty, s.hand.count < 10 else { return }
        let i = g[(s.deck.count * 7 + s.hand.count * 13 + s.grave.count * 3 + s.hp + s.maxMana * 11) % g.count]
        let k = self[side].grave.remove(at: i)
        self[side].hand.append(k); self[side].hb.append(0)
        float(.hero(side), .named(k))
    }

    /// Shadow Touch: a Priest's spells and hero power bank the damage they deal to the other side as Light (instead of
    /// overhealing).
    private mutating func shadowLight(_ target: Side, _ dealt: Int) {
        guard dealt > 0, let src = fxSide, src != target, isCls(src, "priest"), tal(src, "sh_touch") else { return }
        let l = Swift.min(Self.lightCap - self[src].light, dealt)
        if l > 0 { self[src].light += l; float(.hero(src), .light(l)) }
    }

    /// Restores Health (never above the maximum), floating the amount actually healed.
    /// Graveyard Summoner: up to five random dead (non-token) minions are shown; `reclaimTake` brings the chosen back.
    func reclaimOffer(_ side: Side) -> [String] {
        var g = self[side].grave.filter { Self.gd.card($0)?.token == false }
        var out: [String] = []
        while out.count < 5, !g.isEmpty { out.append(g.remove(at: Int.random(in: 0..<g.count))) }
        return out
    }
    mutating func reclaimTake(_ side: Side, _ keys: [String]) {
        for k in keys {
            guard let i = self[side].grave.firstIndex(of: k), self[side].hand.count < 10 else { continue }
            self[side].grave.remove(at: i)
            self[side].hand.append(k); self[side].hb.append(0)
            float(.hero(side), .revived)
        }
    }
    /// The computer takes the dearest of the offer.
    @discardableResult
    mutating func aiReclaim(_ side: Side, _ n: Int) -> [String] {
        let ks = Array(reclaimOffer(side).sorted { (Self.gd.card($0)?.cost ?? 0) > (Self.gd.card($1)?.cost ?? 0) }.prefix(n))
        if !ks.isEmpty { reclaimTake(side, ks) }
        return ks
    }

    /// Blood Rite: the rest of the hand is sacrificed; one of three random Legendaries is copied into the hand and costs (0)
    /// this game (`free` counts the free copies per card). From the third Rite of a game on, two copies come.
    static let riteNeed = 3
    /// Three random Legendaries (fewer if the game has fewer), dearest last.
    func riteOffer() -> [String] { Array(Self.gd.collectible.filter(\.isLegendary).shuffled().prefix(3)).sorted { $0.cost < $1.cost }.map(\.id) }
    mutating func riteSacrifice(_ side: Side) {
        let n = self[side].hand.count
        self[side].hand = []; self[side].hb = []; self[side].free = [:]
        self[side].rites += 1
        if n > 0 { float(.hero(side), .rite(n)) }
    }
    mutating func ritePick(_ side: Side, _ k: String) {
        guard Self.gd.card(k) != nil else { return }
        let n = self[side].rites >= Self.riteNeed ? 2 : 1
        for _ in 0..<n where self[side].hand.count < 10 {
            self[side].hand.append(k); self[side].hb.append(0)
            self[side].free[k, default: 0] += 1
            float(.hero(side), .named(k))
        }
    }
    /// The computer takes a Legendary minion for the moment: healing when hurt, a sweep against a wide board, else the biggest.
    @discardableResult
    mutating func aiRitePick(_ side: Side) -> [String] {
        let o = riteOffer().filter { Self.gd.card($0)?.isMinion == true }
        guard !o.isEmpty else { return [] }
        let foes = self[side.other].board.count
        let k: String
        if self[side].hp <= 12, o.contains("elfqueen") { k = "elfqueen" }
        else if foes >= 3, o.contains("lich") { k = "lich" }
        else { k = o.max { a, b in Self.gd.card(a)!.atk! + Self.gd.card(a)!.hp! < Self.gd.card(b)!.atk! + Self.gd.card(b)!.hp! }! }
        ritePick(side, k)
        return [k]
    }

    /// Heals a hero or minion; a Priest banks the overflow as Light.
    mutating func heal(_ id: EID, _ n: Int) {
        var h = 0
        if id.isHero {
            h = Swift.min(n, self[id.side].max - self[id.side].hp)
            self[id.side].hp += h
            float(id, .heal(h))
        } else if let i = self[id.side].board.firstIndex(where: { $0.uid == id.uid }) {
            h = Swift.min(n, self[id.side].board[i].max - self[id.side].board[i].hp)
            self[id.side].board[i].hp += h
            float(id, .heal(h))
        } else { return }
        if isCls(id.side, "priest") && !tal(id.side, "sh_touch") && n > h {
            let l = Swift.min(Self.lightCap - self[id.side].light, n - h)
            if l > 0 { self[id.side].light += l; float(.hero(id.side), .light(l)) }
        }
    }

    /// Freezes a minion for `side`'s benefit (Permafrost lasts a turn longer; Ice Ward gives Armor once a turn).
    mutating func freezeM(_ side: Side, _ id: EID) {
        guard let i = self[id.side].board.firstIndex(where: { $0.uid == id.uid }) else { return }
        self[id.side].board[i].frozen = Swift.max(self[id.side].board[i].frozen, tal(side, "fr_perma") && id.side != side ? 2 : 1)
        float(id, .frozen)
        if id.side != side && tal(side, "fr_barrier") && !self[side].tf.bar { self[side].tf.bar = true; self[side].armor += 3; float(.hero(side), .armorGain(3)) }
    }

    func canAttack(_ m: Minion) -> Bool { turn == m.side && !m.sleep && !m.attacked && m.atk > 0 }

    func attackTargets(_ side: Side) -> [EID] {
        let op = self[side.other]
        let guards = op.board.filter { $0.hasGuard }
        return guards.isEmpty ? [op.id] + op.board.map(\.id) : guards.map(\.id)
    }

    func targetsFor(_ side: Side, _ tgt: Target, _ cond: String? = nil) -> [EID] {
        let me = self[side], op = self[side.other]
        let v: [EID]
        switch tgt {
        case .any: v = [e.id, p.id] + e.board.map(\.id) + p.board.map(\.id)
        case .minion: v = e.board.map(\.id) + p.board.map(\.id)
        case .ally: v = me.board.map(\.id)
        case .friend: v = [me.id] + me.board.map(\.id)
        case .enemy: v = [op.id] + op.board.map(\.id)
        case .foe: v = op.board.map(\.id)
        }
        guard let cond else { return v }
        return v.filter { id in
            guard let m = minion(id) else { return false }
            switch cond {
            case "damaged": return m.hp < m.max
            case "atk<=3": return m.atk <= 3
            case "atk<=4": return m.atk <= 4
            case "frozen": return m.isFrozen
            case "frozen<5": return m.isFrozen && m.hp < 5
            default: return m.atk >= 5
            }
        }
    }

    // MARK: - Prayers

    mutating func placePrayer(_ side: Side, _ k: String) {
        guard let pr = cardPray(side, k) else { return }
        var cd = Swift.max(1, pr.cd - (tal(side, "ho_altar") ? 1 : 0))
        while cd > 1 && isCls(side, "priest") && self[side].light >= 2 { self[side].light -= 2; cd -= 1 }
        self[side].altar.append(AltarSlot(key: k, cd: cd))
    }

    mutating func tickAltar(_ side: Side, _ n: Int) {
        guard !self[side].altar.isEmpty else { return }
        for i in self[side].altar.indices { self[side].altar[i].cd -= n }
        let done = self[side].altar.filter { $0.cd <= 0 }
        guard !done.isEmpty else { return }
        self[side].altar.removeAll { $0.cd <= 0 }
        for p in done {
            if let pr = cardPray(side, p.key) { applyFx(side, pr.fx, nil) }
            float(.hero(side), .answered)
            log(.prayerDone(side, p.key))
            if tal(side, "ho_grace") {
                heal(.hero(side), 3)
                if let t = self[side.other].board.filter({ $0.hp > 0 }).sorted(by: { $0.atk != $1.atk ? $0.atk > $1.atk : $0.uid < $1.uid }).first { damage(t.id, 1) }
            }
        }
    }

    // MARK: - Opening mulligan

    /// Replaced cards are swapped for new draws and then go to the bottom of the deck. No randomness, so both
    /// copies of an online game reach the same hands.
    mutating func applyMulligan(_ side: Side, _ idx: [Int]) {
        let hand = self[side].hand
        let pick = Array(Set(idx.filter { hand.indices.contains($0) })).sorted()
        let back = pick.map { hand[$0] }
        self[side].hand = hand.enumerated().filter { !pick.contains($0.offset) }.map(\.element)
        self[side].hb = []
        for _ in back where !self[side].deck.isEmpty {
            self[side].hand.append(self[side].deck.removeLast())
            events.append(.drew(side))
        }
        self[side].deck.insert(contentsOf: back, at: 0)
    }

    /// The computer swaps out expensive cards (4 mana or more).
    func aiMulliganPicks(_ side: Side) -> [Int] {
        self[side].hand.indices.filter { (Self.gd.card(self[side].hand[$0])?.cost ?? 0) >= 4 }
    }

    // MARK: - Spells

    /// Spell Damage from minions, plus Kindle on the first Fire spell of a turn, Spell Surge and Vengeance.
    func spellBonus(_ side: Side, _ k: String? = nil) -> Int {
        var n = self[side].board.reduce(0) { $0 + $1.spellDamage }
        if let k, let c = Self.gd.card(k) {
            if c.sc == "fire" && self[side].hasTalents {
                if tal(side, "fi_ignite") && !self[side].tf.fire { n += 1 }
                n += self[side].castHb
            }
            if tal(side, "wl_veng") && self[side].hp <= 15 { n += 1 }
        }
        return n
    }

    /// Spells may also spend banked spell mana (and Bulwark Armor); minions and hero powers use normal mana only.
    func canPay(_ side: Side, _ key: String) -> Bool {
        guard let c = Self.gd.card(key) else { return false }
        return costOf(side, key) <= self[side].mana + (c.isMinion ? 0 : self[side].spellMana) + armorMana(side)
    }

    mutating func pay(_ side: Side, _ key: String) {
        guard let c = Self.gd.card(key) else { return }
        var r = costOf(side, key)
        if !c.isMinion {
            let u = Swift.min(self[side].spellMana, r)
            self[side].spellMana -= u
            r -= u
        }
        if r > self[side].mana, armorMana(side) > 0 {
            let x = Swift.min(armorMana(side), r - Swift.max(0, self[side].mana))
            self[side].armor -= 3 * x
            r -= x
            float(.hero(side), .armorAbsorb(3 * x))
        }
        self[side].mana -= r
    }

    /// A spell: its effect (plus Spell Damage) or, for a Prayer, a place on the altar; then "whenever you cast
    /// a spell" minions react.
    /// `extra`: the further targets of a multi-target spell (Arcane Missiles); the effect lands once per target.
    mutating func castSpell(_ side: Side, _ key: String, _ t: EID?, extra: [EID] = []) {
        guard let c = Self.gd.card(key) else { return }
        let fire = c.sc == "fire"
        if c.isPrayer {
            placePrayer(side, key)
        } else if c.rite {
            riteSacrifice(side)
        } else if let fx = cardFx(side, key) {
            let bonus = spellBonus(side, key)
            let alive = self[side.other].board.filter { $0.hp > 0 }
            if fire { self[side].tf.fire = true }
            for tt in (fx.multi > 0 ? [t] + extra.map(Optional.some) : [t]) {
                applyFx(side, fx, tt, bonus: bonus, faceBonus: (fire && tal(side, "fi_burn") ? 1 : 0) + (tal(side, "hu_aim") ? 2 : 0), isSpell: true)
            }
            if self[side].hasTalents {
                let dead = alive.filter { m in (minion(m.id)?.hp ?? 0) <= 0 }
                if !dead.isEmpty {
                    if fire && tal(side, "fi_wildfire") { damage(.hero(side.other), 1) }
                    if tal(side, "sh_drain") { heal(.hero(side), 2 * dead.count) }
                    if c.sw && tal(side, "sh_echo") { damage(.hero(side.other), 2 * dead.count) }
                    if c.sw && tal(side, "sh_steal") {
                        for m in dead where !m.card.token && self[side].hand.count < 10 { self[side].hand.append(m.key); float(.hero(side), .named(m.key)) }
                        draw(side, 1)
                    }
                }
                if fire && tal(side, "fi_flamearmor") { self[side].armor += 1; float(.hero(side), .armorGain(1)) }
            }
        }
        self[side].castHb = 0
        if tal(side, "fi_boost") {
            _ = hbOf(side)
            for i in self[side].hand.indices {
                if let h = Self.gd.card(self[side].hand[i]), h.sc == "fire", !h.isMinion, self[side].hb[i] < 2 { self[side].hb[i] += 1 }
            }
        }
        for i in self[side].board.indices {
            guard let o = self[side].board[i].onSpell, self[side].board[i].hp > 0 else { continue }
            self[side].board[i].atk += o[0]
            self[side].board[i].hp += o[1]
            self[side].board[i].max += o[1]
            float(self[side].board[i].id, .atkUp(o[0]))
        }
    }

    /// Silence: the minion loses buffs, keywords and card effects for good.
    mutating func silence(_ id: EID) {
        guard let i = self[id.side].board.firstIndex(where: { $0.uid == id.uid }) else { return }
        var m = self[id.side].board[i]
        m.silenced = true; m.hasGuard = false; m.ward = false; m.frozen = 0; m.tmp = 0
        m.atk = m.baseAtk; m.max = m.baseHp; m.hp = Swift.min(m.hp, m.max)
        self[id.side].board[i] = m
        float(id, .silenced)
    }

    mutating func applyFx(_ side: Side, _ fx: Effect, _ t: EID?, bonus: Int = 0, faceBonus: Int = 0, isPower: Bool = false, isSpell: Bool = false) {
        let prevFx = fxSide; fxSide = side
        defer { fxSide = prevFx }
        let op = side.other
        let mt: EID? = (t?.isHero == false) ? t : nil
        var bonus = bonus
        // Paladin: the hero power spends 3 Prestige on a 2/2 Guard recruit (Unity: +1 Attack to the board when it does).
        let empower = isPower && isCls(side, "paladin") && !fx.summon.isEmpty && self[side].pres >= Self.presNeed
        if empower {
            self[side].pres -= Self.presNeed; float(.hero(side), .prestigeGo)
            if tal(side, "pa_coop") { for i in self[side].board.indices { self[side].board[i].atk += 1; float(self[side].board[i].id, .atkUp(1)) } }
        }
        if fx.prestige > 0 && isCls(side, "paladin") { self[side].pres = Swift.min(Self.presCap, self[side].pres + fx.prestige); float(.hero(side), .prestige(fx.prestige)) }
        if isPower && isCls(side, "hunter") && (fx.face > 0 || fx.dmg > 0) {
            let k = Swift.min(2, self[side].fero / 2)
            if k > 0 { self[side].fero -= 2 * k; bonus += k; float(.hero(side), .fero) }
        }
        if fx.selfDmg > 0 {
            if isPower && tal(side, "wl_veng") && self[side].hp <= 15 {}
            else if isPower && isCls(side, "warlock") && self[side].soul >= 2 { self[side].soul -= 2; float(.hero(side), .soulPay) }
            else { damage(.hero(side), fx.selfDmg); selfHurt(side) }
        }
        if fx.icelance > 0, let mt {
            if minion(mt)?.isFrozen == true { damage(mt, fx.icelance + bonus) } else { freezeM(side, mt) }
        }
        var dmg = fx.dmg
        if fx.dmgBeast > 0 && self[side].board.contains(where: { $0.card.race == "beast" }) { dmg = fx.dmgBeast }
        if fx.armorDmg { dmg = self[side].armor + fx.plus }
        if fx.dealsDamage, let t {
            damage(t, dmg + bonus + (t == .hero(op) ? faceBonus : 0), pierce: fx.pierce, phys: isPower, spell: isSpell)
            if fx.splash > 0, let mt { for m in self[op].board where m.id != mt { damage(m.id, fx.splash, phys: isPower, spell: isSpell) } }
            if fx.drawIfKill, let mt, (minion(mt)?.hp ?? 0) <= 0 { draw(side, 1) }
        }
        if let t = mt, let uid = t.uid, let i = self[t.side].board.firstIndex(where: { $0.uid == uid }) {
            if fx.destroy { self[t.side].board[i].hp = 0; float(t, .destroyed) }
            if fx.silence { silence(t); if tal(side, "sh_void") { damage(t, 2) } }
            if fx.setAtk > 0 {
                self[t.side].board[i].atk = fx.setAtk; self[t.side].board[i].tmp = 0
                float(t, .stats(fx.setAtk, self[t.side].board[i].hp))
            }
            if fx.setHp > 0 {
                self[t.side].board[i].hp = fx.setHp; self[t.side].board[i].max = fx.setHp
                float(t, .stats(self[t.side].board[i].atk, fx.setHp))
            }
            if fx.freeze && fx.icelance == 0 { freezeM(side, t) }
            if fx.rush { self[t.side].board[i].sleep = false }
            if fx.tempAtk > 0 {
                self[t.side].board[i].atk += fx.tempAtk; self[t.side].board[i].tmp += fx.tempAtk
                float(t, .atkUp(fx.tempAtk))
            }
            if let b = fx.buff {
                self[t.side].board[i].atk += b[0]
                self[t.side].board[i].hp += b[1]
                self[t.side].board[i].max += b[1]
                float(t, b[0] > 0 ? .atkUp(b[0]) : .hpUp(b[1]))
            }
            if fx.grantGuard { self[t.side].board[i].hasGuard = true }
            if fx.ward { self[t.side].board[i].ward = true; if fx.buff == nil { float(t, .ward) } }
            if fx.bounce {
                let m = self[t.side].board.remove(at: i)
                events.append(.died(m))
                if self[t.side].hand.count < 10 { self[t.side].hand.append(m.key) }
            }
        }
        if fx.aoe > 0 { for m in self[op].board { damage(m.id, fx.aoe + bonus, phys: isPower, spell: isSpell) } }
        if fx.face > 0 { damage(.hero(op), fx.face + bonus + faceBonus, pierce: fx.pierce) }
        if fx.sweep > 0 {
            for m in self[side].board + self[op].board { damage(m.id, fx.sweep + bonus + (m.side != side ? fx.foeExtra : 0), spell: isSpell) }
            if fx.heroes { damage(.hero(op), fx.sweep + bonus + faceBonus); if !fx.noSelf { damage(.hero(side), fx.sweep + bonus) } }
        }
        if fx.freezeAll { for m in self[op].board { freezeM(side, m.id) } }
        if fx.freezeBig, let m = self[op].board.max(by: { $0.atk < $1.atk }) { freezeM(side, m.id) }
        // Team buffs may be limited to a race (Malakar's Undead) and never take a minion below 1 Health; teamWard shields them all.
        if let tm = fx.team {
            for i in self[side].board.indices where fx.teamRace == nil || self[side].board[i].card.race == fx.teamRace {
                self[side].board[i].atk += tm[0]
                self[side].board[i].hp = Swift.max(1, self[side].board[i].hp + tm[1])
                self[side].board[i].max = Swift.max(1, self[side].board[i].max + tm[1])
                float(self[side].board[i].id, tm[0] > 0 ? .atkUp(tm[0]) : .hpUp(tm[1]))
            }
        }
        if fx.teamWard { for i in self[side].board.indices { self[side].board[i].ward = true; float(self[side].board[i].id, .ward) } }
        for k in fx.summon {
            guard let m = summon(side, k), let i = self[side].board.firstIndex(where: { $0.uid == m.uid }) else { continue }
            if fx.wardSummon { self[side].board[i].ward = true }
            if empower {
                self[side].board[i].atk += 1; self[side].board[i].hp += 1; self[side].board[i].max += 1
                self[side].board[i].baseAtk += 1; self[side].board[i].baseHp += 1; self[side].board[i].hasGuard = true
            }
        }
        if let k = fx.perFoe { for _ in 0..<self[op].board.count { summon(side, k) } }
        if fx.heal > 0 { heal(.hero(side), fx.heal) }
        if fx.healT > 0, let t { heal(t, fx.healT) }
        if fx.armor > 0 { self[side].armor += fx.armor; float(.hero(side), .armorGain(fx.armor)) }
        if fx.draw > 0 {
            draw(side, fx.draw)
            if isPower && tal(side, "wl_mutate") { self[side].armor += 5; float(.hero(side), .armorGain(5)) }
        }
        if fx.mana > 0 { self[side].mana += fx.mana }
        if fx.cull > 0 {
            for sd in [side, op] { for i in self[sd].board.indices where self[sd].board[i].hp < fx.cull { self[sd].board[i].hp = 0; float(self[sd].board[i].id, .destroyed) } }
        }
        if fx.purge > 0 {
            for sd in [side, op] { for i in self[sd].board.indices where self[sd].board[i].atk >= fx.purge { self[sd].board[i].hp = 0; float(self[sd].board[i].id, .destroyed) } }
        }
        for _ in 0..<fx.revive {
            guard let idx = self[side].grave.lastIndex(where: { Self.gd.card($0)?.token == false }), self[side].board.count < Self.boardMax else { break }
            let k = self[side].grave.remove(at: idx)
            if let m = summon(side, k) { float(m.id, .revived) }
        }
        if fx.hasten > 0 { tickAltar(side, fx.hasten) }
    }

    mutating func attack(_ attacker: EID, _ target: EID) {
        guard let m = minion(attacker) else { return }
        log(.attacks(name(attacker), name(target)))
        let norip = m.card.norip && !m.silenced
        let rip = target.isHero && self[target.side].armor > 0 && tal(target.side, "wa_counter")
        damage(target, m.atk, phys: true)
        if rip && !norip { damage(attacker, 1, phys: true) }
        if !target.isHero, !norip, let t = minion(target) { damage(attacker, t.atk, phys: true) }
        // Sylvara swings three times a turn: `hits` counts them, `attacked` is set once they are spent.
        if let i = self[attacker.side].board.firstIndex(where: { $0.uid == attacker.uid }) {
            self[attacker.side].board[i].hits += 1
            self[attacker.side].board[i].attacked = self[attacker.side].board[i].hits >= (m.silenced ? 1 : Swift.max(1, m.card.swings))
        }
    }

    /// Removes dead minions (triggering last breath) and decides the game. Returns true when the game just ended.
    @discardableResult
    mutating func cleanup() -> Bool {
        for sd in order {
            let dead = self[sd].board.filter { $0.hp <= 0 }
            if dead.isEmpty { continue }
            self[sd].board.removeAll { $0.hp <= 0 }
            for m in dead { self[sd].grave.append(m.key) }
            talDeaths(sd, dead.count)
            for m in dead {
                events.append(.died(m))
                if let g = m.gasp, summon(sd, g) != nil { log(.burst(m.key)) }
            }
        }
        if !over && (p.hp <= 0 || e.hp <= 0) {
            over = true
            let won = e.hp <= 0 && p.hp > 0
            result = p.hp <= 0 && e.hp <= 0 ? .draw : won ? .win : .lose
            log(won ? .sinks : .falls)
            return true
        }
        return false
    }

    // MARK: - Setup helpers

    static func shuffled(_ deck: [String]) -> [String] { deck.shuffled() }

    /// Fingerprint used online to confirm both copies agree (host side first).
    func hash(hostSide: Side) -> String {
        func sd(_ h: Hero) -> String {
            let b = h.board.map { "\($0.uid),\($0.key),\($0.atk),\($0.hp),\($0.max),\($0.hasGuard ? 1 : 0),\($0.ward ? 1 : 0),\($0.sleep ? 1 : 0),\($0.attacked ? 1 : 0),\($0.frozen),\($0.silenced ? 1 : 0),\($0.tmp)" }.joined(separator: ";")
            let a = h.altar.map { "\($0.key)\($0.cd)" }.joined(separator: ",")
            return "\(h.hp)|\(h.armor)|\(h.mana)|\(h.maxMana)|\(h.spellMana)|\(h.hand.joined(separator: ","))|\(h.deck.count)|\(h.fat)|\(h.powerUsed ? 1 : 0)|\(a)|\(h.grave.count)|\(b)|\(h.rage)|\(h.soul)|\(h.light)|\(h.fero)|\(h.pres)"
        }
        let s = sd(self[hostSide]) + "#" + sd(self[hostSide.other]) + "#" + (turn == hostSide ? "h" : "g")
        var x: Int32 = 0
        for u in s.utf8 { x = x &* 31 &+ Int32(u) }
        return String(x)
    }
}

// MARK: - Deck helpers

enum Decks {
    static var size: Int { GameData.shared.deckSize }
    static func copies(_ d: [String], _ k: String) -> Int { d.filter { $0 == k }.count }
    static func maxCopies(_ k: String) -> Int { GameData.shared.card(k)?.maxCopies ?? 2 }
    /// A deck holds at most one Legendary in all.
    static func legendaries(_ d: [String]) -> Int { d.filter { GameData.shared.card($0)?.isLegendary == true }.count }
    /// Whether card `k` may still go in deck `d` (its copy limit, and the one-Legendary rule).
    static func fits(_ d: [String], _ k: String) -> Bool {
        guard let c = GameData.shared.card(k) else { return false }
        return copies(d, k) < c.maxCopies && !(c.isLegendary && legendaries(d) >= 1)
    }

    static func isValid(_ d: [String], cls: String? = nil) -> Bool {
        d.count <= size && legendaries(d) <= 1 && d.allSatisfy { k in
            guard let c = GameData.shared.card(k), !c.token, c.allowed(for: cls) else { return false }
            return copies(d, k) <= c.maxCopies
        }
    }

    /// A saved deck under the current rules: cards its class may no longer use (or that no longer exist) are dropped,
    /// so the deck is kept and just needs refilling.
    static func sanitize(_ d: [String], cls: String) -> [String] {
        var out: [String] = []
        for k in d {
            guard let c = GameData.shared.card(k), !c.token, c.allowed(for: cls), fits(out, k), out.count < size else { continue }
            out.append(k)
        }
        return out
    }

    /// Fills the AI's class deck up to size with cards of the given rarities.
    static func pad(_ base: [String], rarities: [String], cls: String?) -> [String] {
        var d = base
        let pool = GameData.shared.collectible.filter { rarities.contains($0.rarity) && $0.allowed(for: cls) }.map(\.id)
        var g = 0
        while d.count < size && g < 600, let k = pool.randomElement() {
            g += 1
            if fits(d, k) { d.append(k) }
        }
        return d
    }

    /// Fills a player's deck with weighted random cards (commons most likely).
    static func autoFill(_ d: inout [String], cls: String?) {
        let w = ["c": 3, "r": 2, "e": 1, "l": 1]
        var pool: [String] = []
        for c in GameData.shared.collectible where c.allowed(for: cls) { for _ in 0..<(w[c.rarity] ?? 0) { pool.append(c.id) } }
        var g = 0
        while d.count < size && g < 2000, let k = pool.randomElement() {
            g += 1
            if fits(d, k) { d.append(k) }
        }
    }

    /// Three distinct reward cards after an adventure win; legendaries appear from the third foe on, and cards of
    /// the schools you have talents in come up three times as often. Cards the deck already holds the most
    /// copies of (a Legendary it has) are never offered.
    static func rollRewards(stage: Int, cls: String?, talents: [String] = [], deck: [String] = []) -> [String] {
        let gd = GameData.shared
        let w = ["c": 3, "r": 2, "e": 1, "l": stage >= 2 ? 1 : 0]
        let schools = Set(talents.compactMap { gd.talentPage(of: $0)?.sc })
        var pool: [String] = []
        for c in gd.collectible where c.allowed(for: cls) && fits(deck, c.id) {
            let boost = c.sc.map { schools.contains($0) } == true ? 3 : 1
            for _ in 0..<((w[c.rarity] ?? 0) * boost) { pool.append(c.id) }
        }
        var out: [String] = []
        while out.count < 3, let k = pool.randomElement() { if !out.contains(k) { out.append(k) } }
        return out
    }
}
