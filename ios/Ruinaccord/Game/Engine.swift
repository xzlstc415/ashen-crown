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
    var id: EID { EID(side: side, uid: uid) }
    var card: Card { GameData.shared.card(key)! }
}

struct Hero: Codable, Hashable {
    var side: Side
    var hp: Int
    var max: Int
    var armor = 0
    var mana = 0
    var maxMana = 0
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
        self[side].maxMana = min(10, self[side].maxMana + 1)
        self[side].mana = self[side].maxMana
        self[side].powerUsed = false
        for i in self[side].board.indices { self[side].board[i].sleep = false; self[side].board[i].attacked = false }
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

    func targetsFor(_ side: Side, _ tgt: Target) -> [EID] {
        let me = self[side], op = self[side.other]
        switch tgt {
        case .any: return [e.id, p.id] + e.board.map(\.id) + p.board.map(\.id)
        case .minion: return e.board.map(\.id) + p.board.map(\.id)
        case .ally: return me.board.map(\.id)
        case .friend: return [me.id] + me.board.map(\.id)
        case .enemy: return [op.id] + op.board.map(\.id)
        }
    }

    mutating func applyFx(_ side: Side, _ fx: Effect, _ t: EID?) {
        let op = side.other
        if fx.selfDmg > 0 { damage(.hero(side), fx.selfDmg) }
        if fx.dmg > 0, let t { damage(t, fx.dmg) }
        if let b = fx.buff, let t, let uid = t.uid, let i = self[t.side].board.firstIndex(where: { $0.uid == uid }) {
            self[t.side].board[i].atk += b[0]
            self[t.side].board[i].hp += b[1]
            self[t.side].board[i].max += b[1]
            if fx.grantGuard { self[t.side].board[i].hasGuard = true }
            if fx.ward { self[t.side].board[i].ward = true }
            float(t, b[0] > 0 ? .atkUp(b[0]) : .hpUp(b[1]))
        }
        if fx.aoe > 0 { for m in self[op].board { damage(m.id, fx.aoe) } }
        if fx.face > 0 { damage(.hero(op), fx.face) }
        if let tm = fx.team {
            for i in self[side].board.indices {
                self[side].board[i].atk += tm[0]
                self[side].board[i].hp += tm[1]
                self[side].board[i].max += tm[1]
                float(self[side].board[i].id, tm[0] > 0 ? .atkUp(tm[0]) : .hpUp(tm[1]))
            }
        }
        for k in fx.summon { summon(side, k) }
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
                if let g = m.card.gasp, summon(sd, g) != nil { log(.burst(m.key)) }
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
            let b = h.board.map { "\($0.uid),\($0.key),\($0.atk),\($0.hp),\($0.max),\($0.hasGuard ? 1 : 0),\($0.ward ? 1 : 0),\($0.sleep ? 1 : 0),\($0.attacked ? 1 : 0)" }.joined(separator: ";")
            return "\(h.hp)|\(h.armor)|\(h.mana)|\(h.maxMana)|\(h.hand.joined(separator: ","))|\(h.deck.count)|\(h.fat)|\(h.powerUsed ? 1 : 0)|\(b)"
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

    static func isValid(_ d: [String]) -> Bool {
        d.count <= size && d.allSatisfy { k in
            guard let c = GameData.shared.card(k), !c.token else { return false }
            return copies(d, k) <= c.maxCopies
        }
    }

    /// Fills the AI's class deck up to size with cards of the given rarities.
    static func pad(_ base: [String], rarities: [String]) -> [String] {
        var d = base
        let pool = GameData.shared.collectible.filter { rarities.contains($0.rarity) }.map(\.id)
        var g = 0
        while d.count < size && g < 600, let k = pool.randomElement() {
            g += 1
            if copies(d, k) < maxCopies(k) { d.append(k) }
        }
        return d
    }

    /// Fills a player's deck with weighted random cards (commons most likely).
    static func autoFill(_ d: inout [String]) {
        let w = ["c": 3, "r": 2, "e": 1, "l": 1]
        var pool: [String] = []
        for c in GameData.shared.collectible { for _ in 0..<(w[c.rarity] ?? 0) { pool.append(c.id) } }
        var g = 0
        while d.count < size && g < 2000, let k = pool.randomElement() {
            g += 1
            if copies(d, k) < maxCopies(k) { d.append(k) }
        }
    }

    /// Three distinct reward cards after an adventure win; legendaries appear from the third foe on.
    static func rollRewards(stage: Int) -> [String] {
        let w = ["c": 3, "r": 2, "e": 1, "l": stage >= 2 ? 1 : 0]
        var pool: [String] = []
        for c in GameData.shared.collectible { for _ in 0..<(w[c.rarity] ?? 0) { pool.append(c.id) } }
        var out: [String] = []
        while out.count < 3, let k = pool.randomElement() { if !out.contains(k) { out.append(k) } }
        return out
    }
}
