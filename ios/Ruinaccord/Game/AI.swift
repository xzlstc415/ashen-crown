import Foundation

/// Decisions for the computer opponent (side `e`). Pure functions; the view model sequences them with animations.
extension DuelState {
    var aiEasy: Bool { mode == .quick && diff == .easy }

    func aiDamageTarget(_ n: Int, _ tgt: Target?) -> EID? {
        let foes = p.board
        if aiEasy && Bool.random() {
            let o = tgt == .minion ? foes.map(\.id) : [p.id] + foes.map(\.id)
            return o.randomElement()
        }
        if let kill = foes.filter({ !$0.ward && $0.hp <= n }).max(by: { $0.atk < $1.atk }) { return kill.id }
        if let ward = foes.filter({ $0.ward }).max(by: { $0.atk < $1.atk }), n <= 2 { return ward.id }
        if tgt == .any { return p.id }
        if tgt == .minion { return foes.max(by: { $0.atk < $1.atk })?.id }
        return nil
    }

    func aiBestAlly() -> EID? { e.board.max(by: { $0.atk < $1.atk })?.id }

    func aiWorth(_ fx: Effect) -> Bool {
        if fx.selfDmg > 0 && e.hp <= 12 { return false }
        if fx.draw > 0 && e.hand.count > 7 { return false }
        if fx.aoe > 0 && fx.face == 0 && p.board.count < 2 { return false }
        if fx.team != nil && e.board.count < 2 { return false }
        if !fx.summon.isEmpty && e.board.count >= Self.boardMax { return false }
        if fx.heal > 0 && fx.aoe == 0 && fx.armor == 0 && e.hp > e.max - 6 { return false }
        if fx.mana > 0 { return e.hand.contains { k in k != "coin" && GameData.shared.card(k)?.cost == e.mana + fx.mana } }
        return true
    }

    /// Returns `.some(target)` (target may be nil) when the card should be played now, or nil to hold it.
    func aiPlan(_ k: String) -> EID?? {
        guard let c = GameData.shared.card(k) else { return nil }
        if c.isMinion {
            if e.board.count >= Self.boardMax { return nil }
            if let bc = c.bc, bc.tgt == .ally { return .some(aiBestAlly()) }
            if let bc = c.bc, let tgt = bc.tgt { return .some(aiDamageTarget(bc.dmg, tgt)) }
            return .some(nil)
        }
        guard let fx = c.fx else { return nil }
        if fx.dmg > 0 { if let t = aiDamageTarget(fx.dmg, fx.tgt) { return .some(t) }; return nil }
        if fx.buff != nil { if let t = aiBestAlly() { return .some(t) }; return nil }
        return aiWorth(fx) ? .some(nil) : nil
    }

    /// Whether and where to use the enemy hero power.
    func aiPowerPlan() -> EID?? {
        let pw = e.power
        if aiEasy || e.mana < pw.cost { return nil }
        let fx = pw.fx
        if fx.dmg > 0 { if let t = aiDamageTarget(fx.dmg, pw.tgt) { return .some(t) }; return nil }
        if fx.healT > 0 {
            let cands = ([e.id] + e.board.map(\.id)).filter { hp($0) < maxHp($0) }
            guard let t = cands.max(by: { (maxHp($0) - hp($0)) < (maxHp($1) - hp($1)) }) else { return nil }
            return .some(t)
        }
        if fx.buff != nil { if let t = aiBestAlly() { return .some(t) }; return nil }
        return aiWorth(fx) ? .some(nil) : nil
    }

    func aiAttackTarget(_ m: Minion) -> EID {
        let opts = attackTargets(.e)
        if aiEasy && Bool.random(), let r = opts.randomElement() { return r }
        if p.board.contains(where: { $0.hasGuard }) {
            let kills = opts.filter { !(minion($0)?.ward ?? false) && hp($0) <= m.atk }
            if let k = kills.max(by: { atk($0) < atk($1) }) { return k }
            return opts.min(by: { hp($0) < hp($1) }) ?? p.id
        }
        let lethal = e.board.filter(canAttack).reduce(0) { $0 + $1.atk } >= p.hp + p.armor
        if lethal { return p.id }
        let kills = p.board.filter { !$0.ward && $0.hp <= m.atk }
        if let free = kills.filter({ $0.atk < m.hp }).max(by: { $0.atk < $1.atk }), free.atk >= 2 { return free.id }
        if let big = kills.filter({ $0.atk >= m.atk && $0.atk >= 3 }).max(by: { $0.atk < $1.atk }) { return big.id }
        return p.id
    }

    /// Playable cards this turn, most expensive first.
    func aiPlayable() -> [(key: String, index: Int)] {
        e.hand.enumerated().compactMap { i, k in
            guard let c = GameData.shared.card(k), c.cost <= e.mana else { return nil }
            return (k, i)
        }.sorted { (GameData.shared.card($0.key)?.cost ?? 0) > (GameData.shared.card($1.key)?.cost ?? 0) }
    }
}
