import Foundation

/// A class and the talent page of its capstone (tier 4): the build's tree. The first three tiers may take talents
/// from either page.
struct Arch: Hashable, Codable {
    let cls: String
    let tree: Int
    var name: String { "\(cls)/\(Sim.gd.talentPages(cls)[tree].id)" }
}

enum Search {
    static let gd = Sim.gd

    static func pool(_ cls: String) -> [String] { gd.collectible.filter { $0.allowed(for: cls) && $0.id != "coin" }.map(\.id) }

    /// Every talent choice of the tree: tiers 1-3 from either page, tier 4 the tree's own capstone.
    static func talentSets(_ a: Arch) -> [[String]] {
        let pages = gd.talentPages(a.cls)
        // A class that cannot mix pages: every tier from the arch's page.
        if gd.isSolo(a.cls) {
            return pages[a.tree].tiers.reduce([[]]) { acc, row in acc.flatMap { s in row.map { s + [$0.id] } } }.filter { gd.validTalents(a.cls, $0) }
        }
        func tier(_ t: Int) -> [String] { pages.flatMap { $0.tiers[t].map(\.id) } }
        let cap = pages[a.tree].tiers[3].map(\.id)
        var out: [[String]] = []
        for x in tier(0) { for y in tier(1) { for z in tier(2) { for w in cap { out.append([x, y, z, w]) } } } }
        return out.filter { gd.validTalents(a.cls, $0) }
    }

    /// Games of `b` against each opponent, alternating who goes first. Returns the mean score of `b`.
    static func eval(_ b: Build, vs opps: [Build], games perOpp: Int) -> Double {
        let jobs = opps.count * perOpp
        var res = [Double](repeating: 0, count: jobs)
        res.withUnsafeMutableBufferPointer { buf in
            DispatchQueue.concurrentPerform(iterations: jobs) { j in
                buf[j] = Sim.play(b, opps[j / perOpp], aFirst: j % 2 == 0)
            }
        }
        return res.reduce(0, +) / Double(jobs)
    }

    /// Many builds at once against the same field (one parallel batch).
    static func evalMany(_ bs: [Build], vs opps: [Build], games perOpp: Int) -> [Double] {
        let per = opps.count * perOpp, jobs = bs.count * per
        var res = [Double](repeating: 0, count: jobs)
        res.withUnsafeMutableBufferPointer { buf in
            DispatchQueue.concurrentPerform(iterations: jobs) { j in
                let i = j / per, r = j % per
                buf[j] = Sim.play(bs[i], opps[r / perOpp], aFirst: r % 2 == 0)
            }
        }
        return (0..<bs.count).map { i in res[(i * per)..<((i + 1) * per)].reduce(0, +) / Double(per) }
    }

    static func mutateDeck(_ d: [String], _ pool: [String], swaps: Int) -> [String] {
        var d = d
        for _ in 0..<swaps {
            d.remove(at: Int.random(in: 0..<d.count))
            for _ in 0..<200 {
                let k = pool.randomElement()!
                if Decks.fits(d, k) { d.append(k); break }
            }
        }
        return d.sorted()
    }

    static func mutateTalents(_ t: [String], _ sets: [[String]]) -> [String] {
        // Another set that differs in one tier.
        let near = sets.filter { s in zip(s, t).filter { $0 != $1 }.count == 1 }
        return near.randomElement() ?? t
    }
}
