import Foundation

setvbuf(stdout, nil, _IOLBF, 0)
let gd = Sim.gd
let args = CommandLine.arguments
func arg(_ k: String, _ d: Int) -> Int { args.firstIndex(of: k).flatMap { args[safe: $0 + 1] }.flatMap(Int.init) ?? d }
let outDir = URL(fileURLWithPath: args.firstIndex(of: "-out").flatMap { args[safe: $0 + 1] } ?? ".")
let champFile = outDir.appendingPathComponent("champions.json")

// Warm the lazy tables before going parallel.
_ = gd.collectible; _ = gd.card("coin")
_ = Sim.play(Build(cls: "mage", tal: [], deck: gd.cls("mage")!.deck), Build(cls: "mage", tal: [], deck: gd.cls("mage")!.deck), aFirst: true)

let archs = gd.classes.flatMap { c in (0..<2).map { Arch(cls: c.id, tree: $0) } }
var champs: [Arch: Build] = [:]
if let d = try? Data(contentsOf: champFile), let saved = try? JSONDecoder().decode([String: Build].self, from: d) {
    for a in archs { if let b = saved[a.name] { champs[a] = b } }
}
for a in archs where champs[a] == nil {
    var d = Decks.sanitize(gd.cls(a.cls)!.deck, cls: a.cls); Decks.autoFill(&d, cls: a.cls)
    champs[a] = Build(cls: a.cls, tal: gd.talentPreset(a.cls, a.tree), deck: d.sorted())
}
func save() {
    var d: [String: Build] = [:]
    for (a, b) in champs { d[a.name] = b }
    let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    try? enc.encode(d).write(to: champFile)
}
/// The field an archetype is tested against: both trees of every other class.
func field(_ a: Arch) -> [Build] { archs.filter { $0.cls != a.cls }.map { champs[$0]! } }

let mode = args[safe: 1] ?? "search"
let t0 = Date()
func el() -> String { String(format: "%5.0fs", Date().timeIntervalSince(t0)) }

if mode == "search" {
    let rounds = arg("-rounds", 30), cands = arg("-cands", 24), quick = arg("-quick", 20), confirm = arg("-confirm", 120)
    for r in 1...rounds {
        for a in archs.shuffled() {
            let pool = Search.pool(a.cls), sets = Search.talentSets(a), f = field(a)
            let cur = champs[a]!
            var cs: [Build] = []
            for i in 0..<cands {
                var b = cur
                if i % 4 == 3 || (i % 4 == 2 && Bool.random()) { b.tal = Search.mutateTalents(b.tal, sets) }
                if i % 4 != 3 { b.deck = Search.mutateDeck(b.deck, pool, swaps: Int.random(in: 1...3)) }
                if b != cur { cs.append(b) }
            }
            // Every 5th round sweep all talent sets for the current deck.
            if r % 5 == 0 { cs += sets.filter { $0 != cur.tal }.map { Build(cls: a.cls, tal: $0, deck: cur.deck) } }
            let sc = Search.evalMany(cs, vs: f, games: quick)
            let top = zip(cs, sc).sorted { $0.1 > $1.1 }.prefix(3).map(\.0)
            let fin = Search.evalMany([cur] + top, vs: f, games: confirm)
            let best = fin.indices.max { fin[$0] < fin[$1] }!
            // A challenger must beat the champion clearly (about 1.5 standard errors on the paired run).
            let margin = 1.5 * 0.5 / Double(f.count * confirm).squareRoot()
            if best > 0, fin[best] > fin[0] + margin { champs[a] = top[best - 1] }
            print("\(el()) r\(r) \(a.name.padding(toLength: 16, withPad: " ", startingAt: 0)) champ \(String(format: "%.3f", fin[0])) best \(String(format: "%.3f", fin[best]))\(best > 0 && champs[a] != cur ? " ← new" : "")")
            save()
        }
    }
} else if mode == "eval" {
    // One archetype's champion against the field, `-games` games per opponent.
    let name = args.firstIndex(of: "-arch").flatMap { args[safe: $0 + 1] } ?? ""
    let n = arg("-games", 200)
    for a in archs where name.isEmpty || a.name == name {
        print(a.name, String(format: "%.3f", Search.eval(champs[a]!, vs: field(a), games: n)))
    }
} else if mode == "matrix" {
    // Every pair of archetypes, `-games` games each (alternating who goes first).
    let n = arg("-games", 50)
    var m: [[Double]] = Array(repeating: Array(repeating: 0.5, count: archs.count), count: archs.count)
    for i in archs.indices { for j in archs.indices where j > i {
        let s = Search.eval(champs[archs[i]]!, vs: [champs[archs[j]]!], games: n)
        m[i][j] = s; m[j][i] = 1 - s
    } }
    var out: [[String: Any]] = []
    for (i, a) in archs.enumerated() {
        let others = archs.indices.filter { archs[$0].cls != a.cls }
        let avg = others.map { m[i][$0] }.reduce(0, +) / Double(others.count)
        let b = champs[a]!
        out.append(["arch": a.name, "cls": a.cls, "tree": gd.talentPages(a.cls)[a.tree].id, "winRate": (avg * 1000).rounded() / 1000,
                    "talents": b.tal, "deck": b.deck, "vs": Dictionary(uniqueKeysWithValues: archs.indices.filter { $0 != i }.map { (archs[$0].name, (m[i][$0] * 1000).rounded() / 1000) })])
        print(a.name.padding(toLength: 16, withPad: " ", startingAt: 0), String(format: "%.3f", avg), archs.indices.map { $0 == i ? "  -  " : String(format: "%.2f ", m[i][$0]) }.joined())
    }
    let d = try! JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted, .sortedKeys])
    try! d.write(to: outDir.appendingPathComponent("matrix.json"))
}
print("done \(el())")
