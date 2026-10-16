import Foundation

/// Who an effect or hero power may target.
enum Target: String, Codable {
    case any, minion, ally, friend, enemy
    case foe          // enemy minions only
}

/// One card effect or hero power. Zero / nil means "not part of this effect".
struct Effect: Codable, Hashable {
    var dmg = 0, aoe = 0, face = 0, healT = 0, heal = 0, armor = 0, draw = 0, mana = 0, selfDmg = 0
    var grantGuard = false, ward = false
    var buff: [Int]?      // [+atk, +hp] for one friendly minion
    var team: [Int]?      // [+atk, +hp] for all friendly minions
    var summon: [String] = []
    var tgt: Target?
    /// Extra condition on a minion target: "damaged", "atk<=3" or "atk>=5".
    var cond: String?
    var destroy = false, silence = false, freeze = false, freezeAll = false
    var setAtk = 0, setHp = 0
    var sweep = 0              // damage to ALL minions (and both heroes when `heroes`)
    var heroes = false
    var armorDmg = false       // damage equal to your Armor
    var dmgBeast = 0           // damage instead of `dmg` while you control a Beast
    var drawIfKill = false
    var tempAtk = 0            // +Attack until the end of this turn
    var bounce = false         // return the minion to its owner's hand
    var perFoe: String?        // summon this card once per enemy minion
    private enum CodingKeys: String, CodingKey {
        case dmg, aoe, face, healT, heal, armor, draw, mana, selfDmg, grantGuard = "guard", ward, buff, team, summon, tgt
        case cond, destroy, silence, freeze, freezeAll, setAtk, setHp, sweep, heroes, armorDmg, dmgBeast, drawIfKill, tempAtk, bounce, perFoe
    }
    var dealsDamage: Bool { dmg > 0 || armorDmg }
}

struct Power: Codable, Hashable {
    let cost: Int
    let tgt: Target?
    let fx: Effect
    let names: [String]
}

enum CardType: String, Codable { case minion = "m", spell = "s" }

struct Card: Codable, Identifiable, Hashable {
    let id: String
    let cost: Int
    let type: CardType
    let atk: Int?
    let hp: Int?
    let rarity: String          // c r e l t
    let race: String?
    let hasGuard: Bool
    let ward: Bool
    let surge: Bool
    let gasp: String?           // card summoned on death
    let token: Bool
    let bc: Effect?             // on play
    let fx: Effect?             // spell effect
    let names: [String]
    let flavor: [String]
    let cls: String?            // class card: only this class may use it
    let text: [String]?         // rules text written per language (otherwise generated from the effect)
    let sp: Int                 // Spell Damage
    let onSpell: [Int]?         // [+atk, +hp] whenever its owner casts a spell

    var isMinion: Bool { type == .minion }
    var isLegendary: Bool { rarity == "l" }
    var maxCopies: Int { isLegendary ? 1 : 2 }
    var artName: String { "art_\(id)" }
    private enum CodingKeys: String, CodingKey { case id, cost, type, atk, hp, rarity, race, hasGuard = "guard", ward, surge, gasp, token, bc, fx, names, flavor, cls, text, sp, onSpell }
    func allowed(for cls: String?) -> Bool { self.cls == nil || cls == nil || self.cls == cls }
}

struct HeroClass: Codable, Identifiable, Hashable {
    let id: String
    let color: String
    let names: [String]
    let tags: [String]
    let deck: [String]
    let power: Power
    var artName: String { "class_\(id)" }
}

struct Opponent: Codable, Hashable {
    let names: [String]
    let initials: [String]
    let hp: Int
    let deck: [String]
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy, normal, hard
    var id: String { rawValue }
    var rarities: [String] { self == .easy ? ["c"] : self == .normal ? ["r", "e"] : ["e", "l"] }
    var colorHex: String { self == .easy ? "#6aa57e" : self == .normal ? "#5a8ae0" : "#cf4a3f" }
}

/// Card, class and opponent tables, generated from the web game by ios/tools/gen_data.mjs.
final class GameData: Decodable {
    static let shared: GameData = {
        guard let url = Bundle.main.url(forResource: "GameData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let gd = try? JSONDecoder().decode(GameData.self, from: data) else {
            fatalError("GameData.json missing or invalid")
        }
        return gd
    }()

    let cards: [Card]
    let classes: [HeroClass]
    let opponents: [Opponent]
    let boardMax: Int
    let deckSize: Int
    let fortify: Power

    private(set) lazy var byId: [String: Card] = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
    private(set) lazy var classById: [String: HeroClass] = Dictionary(uniqueKeysWithValues: classes.map { ($0.id, $0) })
    /// Collectible cards (no tokens), in definition order.
    private(set) lazy var collectible: [Card] = cards.filter { !$0.token }

    func card(_ id: String) -> Card? { byId[id] }
    func cls(_ id: String) -> HeroClass? { classById[id] }

    /// Fingerprint of everything two online players must agree on.
    private(set) lazy var rulesVersion: String = {
        var h: Int32 = 0
        func mix(_ s: String) { for u in s.utf8 { h = h &* 31 &+ Int32(u) } }
        for c in cards { mix("\(c.id)|\(c.cls ?? "")|\(c.sp)|\(c.onSpell ?? [])|\(c.cost)|\(c.atk ?? -1)|\(c.hp ?? -1)|\(c.hasGuard)|\(c.ward)|\(c.surge)|\(c.gasp ?? "")|\(c.bc.map { "\($0)" } ?? "")|\(c.fx.map { "\($0)" } ?? "")") }
        for k in classes { mix("\(k.id)|\(k.power.cost)|\(k.power.tgt?.rawValue ?? "")|\(k.power.fx)") }
        return "v3-\(String(UInt32(bitPattern: h), radix: 36))"
    }()

    private enum CodingKeys: String, CodingKey { case cards, classes, opponents, boardMax, deckSize, fortify }
}
