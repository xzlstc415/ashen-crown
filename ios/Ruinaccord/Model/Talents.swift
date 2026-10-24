import Foundation

/// Talents: two pages per class, four tiers of 3/3/2/1 nodes (the Hunter: three tiers of 3/3/2, all from one page).
/// A tier opens once the tier above it has its pick. Quick and online duels spend them in the deck builder; Adventure hands
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
    /// Attack and Health the minion gets from talents when played (shown on the card in hand).
    var atkUp: Int?
    var hpUp: Int?
    /// Later overrides win field by field.
    mutating func merge(_ o: CardOverride) {
        if let c = o.cost { cost = c }
        if let f = o.fx { fx = f }
        if let b = o.bc { bc = b }
        if let p = o.pray { pray = p }
        if let t = o.text { text = t }
        if let a = o.atkUp { atkUp = a }
        if let h = o.hpUp { hpUp = h }
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
    /// Classes whose talents all come from one page (no mixing).
    let solo: [String]
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
    private(set) lazy var clsOf: [String: String] = {
        var d: [String: String] = [:]
        for (cls, pgs) in pages { for pg in pgs { for row in pg.tiers { for n in row { d[n.id] = cls } } } }
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
    func talentClass(of id: String) -> String? { var t = talents; return t.clsOf[id] }
    /// One-page class: every talent from the same page.
    func isSolo(_ cls: String?) -> Bool { cls.map { talents.solo.contains($0) } ?? false }
    /// Points a class can spend: one per tier.
    func maxPoints(_ cls: String?) -> Int { cls.flatMap { talents.pages[$0]?.map(\.tiers.count).max() } ?? talents.maxPts }

    /// The pick in tier `t` (either page), if any: one talent per tier.
    func tierPick(_ sel: [String], _ t: Int) -> String? { sel.first { talentNode($0) != nil && talentTier(of: $0) == t } }
    /// Tier 1 is always open; a later tier opens once the tier above it has its pick (on the same page `page`, for a
    /// one-page class).
    func tierOpen(_ sel: [String], _ t: Int, page: String? = nil) -> Bool {
        t == 0 || sel.contains { id in
            talentNode(id) != nil && talentTier(of: id) == t - 1
                && (page == nil || !isSolo(talentClass(of: id)) || talentPage(of: id)?.id == page)
        }
    }

    func validTalents(_ cls: String, _ sel: [String]) -> Bool {
        if sel.isEmpty { return true }
        guard let pages = talents.pages[cls], sel.count <= maxPoints(cls), Set(sel).count == sel.count else { return false }
        if isSolo(cls) && Set(sel.map { talentPage(of: $0)?.id }).count > 1 { return false }
        return sel.allSatisfy { id in
            guard let pg = talentPage(of: id), pages.contains(where: { $0.id == pg.id }) else { return false }
            let t = talentTier(of: id)
            return tierOpen(sel, t, page: pg.id) && sel.filter { talentNode($0) != nil && talentTier(of: $0) == t }.count == 1
        }
    }

    /// Drops nodes whose tier is no longer open (after the pick above was removed).
    func pruneTalents(_ sel: [String]) -> [String] {
        var a = sel
        while true {
            let b = a.filter { id in talentNode(id) != nil && tierOpen(a, talentTier(of: id), page: talentPage(of: id)?.id) }
            if b.count == a.count { return a }
            a = b
        }
    }

    /// Presets: 0 = the first page top to bottom, 1 = the second, 2 = alternating pages.
    func talentPreset(_ cls: String, _ i: Int) -> [String] { talents.presets[cls]?[safe: i] ?? [] }

    /// Adventure: one point every two duels, so `stage` (0-based) plays with 1 + stage / 2 points, up to the class's
    /// maximum.
    func advPoints(_ stage: Int, _ cls: String?) -> Int { min(maxPoints(cls), 1 + stage / 2) }

    /// The card changes a talent selection makes for its owner, stat boosts included.
    func overrides(for sel: [String]) -> [String: CardOverride] {
        var out: [String: CardOverride] = [:]
        for id in sel {
            guard let byCard = talents.overrides[id] else { continue }
            for (k, o) in byCard where card(k) != nil { out[k, default: CardOverride()].merge(o) }
        }
        // Heartseeker: Arcane, Steady and Deadly Shot deal 1 more damage and cost 1 less, on top of Precision and Deadly Aim.
        if sel.contains("hu_heart") {
            for k in ["spray", "steady", "riptide"] {
                var o = out[k] ?? CardOverride()
                guard let c = card(k), var fx = o.fx ?? c.fx else { continue }
                fx.dmg += 1
                o.fx = fx; o.cost = Swift.max(0, (o.cost ?? c.cost) - 1)
                out[k] = o
            }
        }
        for c in cards where c.isMinion {
            let (a, h) = statBonus(c, tal: sel)
            if a != 0 || h != 0 { out[c.id, default: CardOverride()].atkUp = a; out[c.id, default: CardOverride()].hpUp = h }
        }
        return out
    }

    /// The Attack and Health a minion card gets from these talents, known before it is played (the engine adds the
    /// situational boosts on top when it is summoned).
    func statBonus(_ c: Card, tal: [String]) -> (Int, Int) {
        func h(_ id: String) -> Bool { tal.contains(id) }
        var a = 0, hp = 0
        let key = c.id
        if c.sc == "fire" && h("fi_heart") { a += 1 }
        if key == "spellbreaker" && h("sh_breaker") { a += 1 }
        if key == "crab" && h("wa_crab") { hp += 2 }
        if c.hasGuard && h("wa_iron") { hp += 2 }
        if key == "berserker" && h("wa_berserk") { a += 1 }
        if key == "minnow" && h("pa_drill") { hp += 1 }
        if key == "direwolf" && h("hu_pack") { a += 1; hp += 1 }
        if (key == "hound" || key == "whound" || key == "phound") && h("hu_hound") { a += 1 }
        // Houndmaster: every canine, hounds, wolves and Dire Wolf.
        if ["hound", "whound", "phound", "elver", "direwolf"].contains(key) && h("hu_master") { a += 1; hp += 1 }
        if key == "sailor" && h("wl_bone") { a += 1; hp += 1 }
        if key == "bubble" && h("wl_wrath") { a += 1 }
        if c.gasp != nil && h("wl_gasp") { a += 1 }
        if key == "knight" && h("pa_vshield") { a += 1 }
        return (a, hp)
    }

    /// Adventure packs offered after winning `stage`, or nil for classes without talents.
    func advPacks(_ cls: String, stage: Int) -> [TalentPack]? { talents.adv[cls]?.packs[safe: stage] }
}
