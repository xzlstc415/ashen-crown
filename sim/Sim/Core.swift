import Foundation

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

/// The side whose turn it is plays as the AI: `me`, `E` (its hero) and `P` (the foe) in the rewritten AI.
extension DuelState {
    var me: Side { turn }
    var E: Hero { self[turn] }
    var P: Hero { self[turn.other] }
}

/// A class, its four talents and its 25 cards.
struct Build: Codable, Hashable {
    var cls: String
    var tal: [String]
    var deck: [String]
}

enum Sim {
    static let gd = GameData.shared
    static let roundCap = 60

    /// One AI-vs-AI quick-play duel at hard difficulty. Returns 1 when `a` wins, 0 when `b` wins, 0.5 for a draw.
    static func play(_ a: Build, _ b: Build, aFirst: Bool) -> Double {
        var s = DuelState(mode: .quick, pcls: a.cls, ecls: b.cls, diff: .hard,
                          p: DuelState.makeHero(.p, hp: 30, deck: a.deck.shuffled(), power: gd.cls(a.cls)!.power),
                          e: DuelState.makeHero(.e, hp: 30, deck: b.deck.shuffled(), power: gd.cls(b.cls)!.power))
        s.setupTalents(.p, cls: a.cls, a.tal)
        s.setupTalents(.e, cls: b.cls, b.tal)
        let first: Side = aFirst ? .p : .e
        s.draw(first, 5); s.draw(first.other, 5); s.talOpen(first); s.talOpen(first.other); s.turn = first
        s.applyMulligan(.p, s.aiMulliganPicks(.p)); s.applyMulligan(.e, s.aiMulliganPicks(.e))
        s[first.other].hand.append("coin")
        var side = first
        for _ in 0..<(roundCap * 2) {
            s.turn = side
            turn(&s)
            if s.over { break }
            side = side.other
        }
        if !s.over { return 0.5 }
        return s.result == .win ? 1 : s.result == .lose ? 0 : 0.5
    }

    /// The app's computer turn (GameVM.aiTurn) without the animations.
    static func turn(_ S: inout DuelState) {
        let me = S.turn
        if me == .e { S.round += 1 }
        S.startTurn(me)
        S.events.removeAll()
        if S.cleanup() { return }
        for _ in 0..<12 where !S.over {
            var did = false
            for o in S.aiPlayable() {
                S[me].castHb = S.hbOf(me)[safe: o.index] ?? 0
                guard let plan = S.aiPlan(o.key), let c = gd.card(o.key) else { continue }
                var t = plan
                S.pay(me, c.id)
                _ = S.takeHand(me, o.index)
                if c.isMinion {
                    let bc = S.cardBc(me, c.id)
                    let m = S.summon(me, c.id)
                    if let bc, let m {
                        if bc.tgt == .ally && t == nil { t = m.id }
                        S.applyFx(me, bc, t)
                        if bc.reclaim > 0 { _ = S.aiReclaim(me, bc.reclaim) }
                    }
                } else if let fx = S.cardFx(me, c.id) {
                    let extra: [EID] = fx.multi > 1 ? Array(S.aiMultiTargets(fx, bonus: S.spellBonus(me, c.id)).dropFirst()) : []
                    S.castSpell(me, c.id, t, extra: extra)
                    if c.rite { _ = S.aiRitePick(me) }
                }
                did = true
                _ = S.cleanup(); S.events.removeAll()
                break
            }
            if !did { break }
        }
        if !S.over, let plan = S.aiPowerPlan() {
            let p = S[me].power
            S[me].mana -= S.pcost(me); S[me].powerUsed = true
            S.applyFx(me, p.fx, plan, bonus: S.powerBonus(me), isPower: true); S.afterPower(me)
            _ = S.cleanup(); S.events.removeAll()
        }
        for _ in 0..<3 where !S.over {
            var any = false
            for m in S[me].board {
                if S.over { break }
                guard S[me].board.contains(where: { $0.uid == m.uid }), let cur = S.minion(m.id), S.canAttack(cur) else { continue }
                any = true
                S.attack(m.id, S.aiAttackTarget(cur))
                _ = S.cleanup(); S.events.removeAll()
            }
            if !any { break }
        }
    }
}
