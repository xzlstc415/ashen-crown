import Foundation

/// Talents: two pages per class, four tiers of 3/3/2/1 nodes. A tier opens once the page has 0/2/4/6 points in
/// the tiers below it; 12 points in all. Quick and online duels spend them in the deck builder; Adventure hands
/// them out duel by duel. Generated from the web game by ios/tools/gen_data.mjs.
struct TalentNode: Codable, Hashable, Identifiable {
    let id: String
    let names: [String]
    let desc: [String]
}

struct TalentPage: Codable, Hashable, Identifiable {
    let id: String
    let sc: String
    let color: String
    let names: [String]
    let tiers: [[TalentNode]]
}

/// What a talent changes on one card for its owner (nil fields are unchanged).
struct CardOverride: Codable, Hashable {
    var cost: Int?
    var fx: Effect?
    var bc: Effect?
    var pray: Prayer?
    var text: [String]?
    /// Later overrides win field by field.
    mutating func merge(_ o: CardOverride) {
        if let c = o.cost { cost = c }
        if let f = o.fx { fx = f }
        if let b = o.bc { bc = b }
        if let p = o.pray { pray = p }
        if let t = o.text { text = t }
    }
}

/// One of the two packs offered after an Adventure duel: cards for the deck and the talents they go with.
struct TalentPack: Codable, Hashable {
    let cards: [String]
    let hint: [String]
}

/// Adventure for a class: its neutral starting deck and the packs per stage (one per talent page).
struct AdvClass: Codable, Hashable {
    let deck: [String]
    let packs: [[TalentPack]]
}

struct Talents: Codable {
    let maxPts: Int
    let pages: [String: [TalentPage]]
    let overrides: [String: [String: CardOverride]]
    let presets: [String: [[String]]]
    let adv: [String: AdvClass]

    private(set) lazy var nodes: [String: TalentNode] = {
        var d: [String: TalentNode] = [:]
        for pgs in pages.values { for pg in pgs { for row in pg.tiers { for n in row { d[n.id] = n } } } }
        return d
    }()
    private(set) lazy var pageOf: [String: TalentPage] = {
        var d: [String: TalentPage] = [:]
        for pgs in pages.values { for pg in pgs { for row in pg.tiers { for n in row { d[n.id] = pg } } } }
        return d
    }()
    private(set) lazy var tierOf: [String: Int] = {
        var d: [String: Int] = [:]
        for pgs in pages.values { for pg in pgs { for (t, row) in pg.tiers.enumerated() { for n in row { d[n.id] = t } } } }
        return d
    }()
}

extension GameData {
    func hasTalents(_ cls: String?) -> Bool { cls.map { talents.pages[$0] != nil } ?? false }
    func talentPages(_ cls: String) -> [TalentPage] { talents.pages[cls] ?? [] }
    func talentNode(_ id: String) -> TalentNode? { var t = talents; return t.nodes[id] }
    func talentPage(of id: String) -> TalentPage? { var t = talents; return t.pageOf[id] }
    func talentTier(of id: String) -> Int { var t = talents; return t.tierOf[id] ?? 0 }

    /// The pick in tier `t` of `page`, if any: one talent per tier.
    func tierPick(_ sel: [String], _ page: TalentPage, _ t: Int) -> String? {
        sel.first { talentPage(of: $0)?.id == page.id && talentTier(of: $0) == t }
    }
    /// Tier 1 is always open; a later tier opens once the tier above it in the same page has its pick.
    func tierOpen(_ sel: [String], _ page: TalentPage, _ t: Int) -> Bool { t == 0 || tierPick(sel, page, t - 1) != nil }

    func validTalents(_ cls: String, _ sel: [String]) -> Bool {
        if sel.isEmpty { return true }
        guard let pages = talents.pages[cls], sel.count <= talents.maxPts, Set(sel).count == sel.count else { return false }
        return sel.allSatisfy { id in
            guard let pg = talentPage(of: id), pages.contains(where: { $0.id == pg.id }) else { return false }
            let t = talentTier(of: id)
            return tierOpen(sel, pg, t) && sel.filter { talentPage(of: $0)?.id == pg.id && talentTier(of: $0) == t }.count == 1
        }
    }

    /// Drops nodes whose tier is no longer open (after the pick above was removed).
    func pruneTalents(_ sel: [String]) -> [String] {
        var a = sel
        while true {
            let b = a.filter { id in
                guard let pg = talentPage(of: id) else { return false }
                return tierOpen(a, pg, talentTier(of: id))
            }
            if b.count == a.count { return a }
            a = b
        }
    }

    /// Presets 0-2: both pages climbed to the top, taking the first, second or third talent of each tier.
    func talentPreset(_ cls: String, _ i: Int) -> [String] { talents.presets[cls]?[safe: i] ?? [] }

    /// Adventure: one point a duel, so `stage` (0-based) plays with stage + 1 points, 8 at the final duel.
    func advPoints(_ stage: Int) -> Int { min(talents.maxPts, stage + 1) }

    /// The card changes a talent selection makes for its owner.
    func overrides(for sel: [String]) -> [String: CardOverride] {
        var out: [String: CardOverride] = [:]
        for id in sel {
            guard let byCard = talents.overrides[id] else { continue }
            for (k, o) in byCard where card(k) != nil { out[k, default: CardOverride()].merge(o) }
        }
        return out
    }

    /// Adventure packs offered after winning `stage`, or nil for classes without talents.
    func advPacks(_ cls: String, stage: Int) -> [TalentPack]? { talents.adv[cls]?.packs[safe: stage] }
}
