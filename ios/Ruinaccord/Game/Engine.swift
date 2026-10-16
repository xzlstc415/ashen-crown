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
    var frozen = false       // misses its owner's next turn
    var silenced = false     // lost its keywords and card effects
    var tmp = 0              // Attack that wears off when this turn ends
    var id: EID { EID(side: side, uid: uid) }
    /// Card effects still active (a silenced minion has none).
    var gasp: String? { silenced ? nil : card.gasp }
    var spellDamage: Int { silenced ? 0 : card.sp }
    var onSpell: [Int]? { silenced ? nil : card.onSpell }
    var card: Card { GameData.shared.card(key)! }
}

struct Hero: Codable, Hashable {
    var side: Side
    var hp: Int
    var max: Int
    var armor = 0
    var mana = 0
    var maxMana = 0
    /// Unspent mana banked for spells (up to 3).
    var spellMana = 0
    var deck: [String]
    var hand: [String] = []
    var board: [Minion] = []
    var fat = 0
    var powerUsed = false
    var power: Power
    var id: EID { .hero(side) }
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
}

enum FloatKind: Hashable {
    case dmg(Int), armorAbsorb(Int), ward, heal(Int), armorGain(Int), atkUp(Int), hpUp(Int)
    case frozen, silenced, destroyed, stats(Int, Int)
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
    var round = 0
    var nextUid = 0
    var p: Hero
    var e: Hero
    /// Death resolution order (host side first online, so token ids stay in step).
    var order: [Side] = [.p, .e]
    var result: GameResult?

    /// Transient UI events produced by rule functions; drained by the view model, never stored.
    var events: [GameEvent] = []

    private enum CodingKeys: String, CodingKey { case mode, pcls, ecls, diff, stage, turn, over, opened, round, nextUid, p, e, order, result }

    static let boardMax = GameData.shared.boardMax

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

    // MARK: - Turn flow

    mutating func startTurn(_ side: Side) {
        // The side whose turn just ended banks its unspent mana as spell mana (up to 3), its frozen minions
        // thaw and temporary Attack wears off. Minions frozen during the other turn sit this turn out.
        let o = side.other
        self[o].spellMana = min(3, self[o].spellMana + max(0, self[o].mana))
        self[o].mana = 0
        for i in self[o].board.indices {
            self[o].board[i].frozen = false
            self[o].board[i].atk -= self[o].board[i].tmp
            self[o].board[i].tmp = 0
        }
        self[side].maxMana = min(10, self[side].maxMana + 1)
        self[side].mana = self[side].maxMana
        self[side].powerUsed = false
        for i in self[side].board.indices { self[side].board[i].sleep = false; self[side].board[i].attacked = self[side].board[i].frozen }
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
        guard self[side].board.count < Self.boardMax, let c = GameData.shared.card(key) else { return nil }
        nextUid += 1
        let m = Minion(uid: nextUid, key: key, side: side, atk: c.atk ?? 0, hp: c.hp ?? 0, max: c.hp ?? 0,
                       baseAtk: c.atk ?? 0, baseHp: c.hp ?? 0, hasGuard: c.hasGuard, ward: c.ward, sleep: !c.surge, attacked: false)
        self[side].board.append(m)
        return m
    }

    mutating func damage(_ id: EID, _ n: Int) {
        guard n > 0 else { return }
        if id.isHero {
            var h = self[id.side]
            let a = min(h.armor, n)
            h.armor -= a
            let rest = n - a
            h.hp -= rest
            self[id.side] = h
            float(id, rest > 0 ? .dmg(rest) : .armorAbsorb(a))
        } else if let i = self[id.side].board.firstIndex(where: { $0.uid == id.uid }) {
            if self[id.side].board[i].ward {
                self[id.side].board[i].ward = false
                float(id, .ward)
            } else {
                self[id.side].board[i].hp -= n
                float(id, .dmg(n))
            }
        }
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
            default: return m.atk >= 5
            }
        }
    }

    // MARK: - Spells

    func spellBonus(_ side: Side) -> Int { self[side].board.reduce(0) { $0 + $1.spellDamage } }

    /// Spells may also spend banked spell mana; minions and hero powers use normal mana only.
    func canPay(_ side: Side, _ key: String) -> Bool {
        guard let c = GameData.shared.card(key) else { return false }
        return c.cost <= self[side].mana + (c.isMinion ? 0 : self[side].spellMana)
    }

    mutating func pay(_ side: Side, _ key: String) {
        guard let c = GameData.shared.card(key) else { return }
        if c.isMinion { self[side].mana -= c.cost; return }
        let use = min(self[side].spellMana, c.cost)
        self[side].spellMana -= use
        self[side].mana -= c.cost - use
    }

    /// A spell: its effect (plus Spell Damage), then "whenever you cast a spell" minions react.
    mutating func castSpell(_ side: Side, _ key: String, _ t: EID?) {
        guard let fx = GameData.shared.card(key)?.fx else { return }
        applyFx(side, fx, t, bonus: spellBonus(side))
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
        m.silenced = true; m.hasGuard = false; m.ward = false; m.frozen = false; m.tmp = 0
        m.atk = m.baseAtk; m.max = m.baseHp; m.hp = min(m.hp, m.max)
        self[id.side].board[i] = m
        float(id, .silenced)
    }

    mutating func applyFx(_ side: Side, _ fx: Effect, _ t: EID?, bonus: Int = 0) {
        let op = side.other
        if fx.selfDmg > 0 { damage(.hero(side), fx.selfDmg) }
        if fx.dealsDamage, let t {
            var n = fx.dmg
            if fx.dmgBeast > 0 && self[side].board.contains(where: { $0.card.race == "beast" }) { n = fx.dmgBeast }
            if fx.armorDmg { n = self[side].armor }
            damage(t, n + bonus)
            if fx.drawIfKill, let m = minion(t), m.hp <= 0 { draw(side, 1) }
        }
        if let t, let uid = t.uid, let i = self[t.side].board.firstIndex(where: { $0.uid == uid }) {
            if fx.destroy { self[t.side].board[i].hp = 0; float(t, .destroyed) }
            if fx.silence { silence(t) }
            if fx.setAtk > 0 {
                self[t.side].board[i].atk = fx.setAtk; self[t.side].board[i].tmp = 0
                float(t, .stats(fx.setAtk, self[t.side].board[i].hp))
            }
            if fx.setHp > 0 {
                self[t.side].board[i].hp = fx.setHp; self[t.side].board[i].max = fx.setHp
                float(t, .stats(self[t.side].board[i].atk, fx.setHp))
            }
            if fx.freeze { self[t.side].board[i].frozen = true; float(t, .frozen) }
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
        if fx.aoe > 0 { for m in self[op].board { damage(m.id, fx.aoe + bonus) } }
        if fx.face > 0 { damage(.hero(op), fx.face + bonus) }
        if fx.sweep > 0 {
            for m in self[side].board + self[op].board { damage(m.id, fx.sweep + bonus) }
            if fx.heroes { damage(.hero(op), fx.sweep + bonus); damage(.hero(side), fx.sweep + bonus) }
        }
        if fx.freezeAll { for i in self[op].board.indices { self[op].board[i].frozen = true; float(self[op].board[i].id, .frozen) } }
        if let tm = fx.team {
            for i in self[side].board.indices {
                self[side].board[i].atk += tm[0]
                self[side].board[i].hp += tm[1]
                self[side].board[i].max += tm[1]
                float(self[side].board[i].id, tm[0] > 0 ? .atkUp(tm[0]) : .hpUp(tm[1]))
            }
        }
        for k in fx.summon { summon(side, k) }
        if let k = fx.perFoe { for _ in 0..<self[op].board.count { summon(side, k) } }
        if fx.heal > 0 {
            let h = min(fx.heal, self[side].max - self[side].hp)
            self[side].hp += h
            float(.hero(side), .heal(h))
        }
        if fx.healT > 0, let t {
            if t.isHero {
                let h = min(fx.healT, self[t.side].max - self[t.side].hp)
                self[t.side].hp += h
                float(t, .heal(h))
            } else if let i = self[t.side].board.firstIndex(where: { $0.uid == t.uid }) {
                let h = min(fx.healT, self[t.side].board[i].max - self[t.side].board[i].hp)
                self[t.side].board[i].hp += h
                float(t, .heal(h))
            }
        }
        if fx.armor > 0 { self[side].armor += fx.armor; float(.hero(side), .armorGain(fx.armor)) }
        if fx.draw > 0 { draw(side, fx.draw) }
        if fx.mana > 0 { self[side].mana += fx.mana }
    }

    mutating func attack(_ attacker: EID, _ target: EID) {
        guard let m = minion(attacker) else { return }
        log(.attacks(name(attacker), name(target)))
        damage(target, m.atk)
        if !target.isHero, let t = minion(target) { damage(attacker, t.atk) }
        if let i = self[attacker.side].board.firstIndex(where: { $0.uid == attacker.uid }) { self[attacker.side].board[i].attacked = true }
    }

    /// Removes dead minions (triggering last breath) and decides the game. Returns true when the game just ended.
    @discardableResult
    mutating func cleanup() -> Bool {
        for sd in order {
            let dead = self[sd].board.filter { $0.hp <= 0 }
            if dead.isEmpty { continue }
            self[sd].board.removeAll { $0.hp <= 0 }
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
            let b = h.board.map { "\($0.uid),\($0.key),\($0.atk),\($0.hp),\($0.max),\($0.hasGuard ? 1 : 0),\($0.ward ? 1 : 0),\($0.sleep ? 1 : 0),\($0.attacked ? 1 : 0),\($0.frozen ? 1 : 0),\($0.silenced ? 1 : 0),\($0.tmp)" }.joined(separator: ";")
            return "\(h.hp)|\(h.armor)|\(h.mana)|\(h.maxMana)|\(h.spellMana)|\(h.hand.joined(separator: ","))|\(h.deck.count)|\(h.fat)|\(h.powerUsed ? 1 : 0)|\(b)"
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

    static func isValid(_ d: [String], cls: String? = nil) -> Bool {
        d.count <= size && d.allSatisfy { k in
            guard let c = GameData.shared.card(k), !c.token, c.allowed(for: cls) else { return false }
            return copies(d, k) <= c.maxCopies
        }
    }

    /// A saved deck under the current rules: cards its class may no longer use (or that no longer exist) are dropped,
    /// so the deck is kept and just needs refilling.
    static func sanitize(_ d: [String], cls: String) -> [String] {
        var out: [String] = []
        for k in d {
            guard let c = GameData.shared.card(k), !c.token, c.allowed(for: cls), copies(out, k) < c.maxCopies, out.count < size else { continue }
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
            if copies(d, k) < maxCopies(k) { d.append(k) }
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
            if copies(d, k) < maxCopies(k) { d.append(k) }
        }
    }

    /// Three distinct reward cards after an adventure win; legendaries appear from the third foe on.
    static func rollRewards(stage: Int, cls: String?) -> [String] {
        let w = ["c": 3, "r": 2, "e": 1, "l": stage >= 2 ? 1 : 0]
        var pool: [String] = []
        for c in GameData.shared.collectible where c.allowed(for: cls) { for _ in 0..<(w[c.rarity] ?? 0) { pool.append(c.id) } }
        var out: [String] = []
        while out.count < 3, let k = pool.randomElement() { if !out.contains(k) { out.append(k) } }
        return out
    }
}
