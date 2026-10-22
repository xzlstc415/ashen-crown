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
        if tgt == .any || tgt == .enemy { return p.id }
        if tgt == .minion || tgt == .foe { return foes.max(by: { $0.atk < $1.atk })?.id }
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
        if !fx.summon.isEmpty && fx.selfDmg > 0 && e.hp <= fx.selfDmg + 8 { return false }
        return true
    }

    func aiValue(_ m: Minion) -> Int { m.atk + m.hp + (m.hasGuard ? 2 : 0) + (m.ward ? 2 : 0) }

    /// An enemy minion worth silencing: buffed, keyworded or carrying an effect.
    func aiSilenceTarget() -> EID? {
        p.board.filter { m in
            !m.silenced && (m.hasGuard || m.ward || m.atk > m.baseAtk || m.max > m.baseHp || m.card.gasp != nil || m.card.sp > 0 || m.card.onSpell != nil)
        }.max(by: { aiValue($0) < aiValue($1) })?.id
    }

    /// Whether a Prayer is worth placing now.
    func aiPrayOk(_ k: String) -> Bool {
        guard let fx = cardPray(.e, k)?.fx else { return false }
        if e.altar.count >= altarMax(.e) { return false }
        if fx.revive > 0 { return e.grave.contains { GameData.shared.card($0)?.token == false } }
        if fx.purge > 0 {
            func big(_ h: Hero) -> Int { h.board.filter { $0.atk >= fx.purge }.count }
            return big(p) > big(e)
        }
        if fx.heal > 0 && fx.draw == 0 { return e.hp <= e.max - 6 }
        if fx.team != nil { return e.board.count >= 1 }
        return true
    }

    /// Returns `.some(target)` (target may be nil) when the card should be played now, or nil to hold it.
    func aiPlan(_ k: String) -> EID?? {
        guard let c = GameData.shared.card(k) else { return nil }
        if c.isPrayer { return aiPrayOk(k) ? .some(nil) : nil }
        if c.isMinion {
            if e.board.count >= Self.boardMax { return nil }
            let bc = cardBc(.e, k)
            if let bc, bc.silence { return .some(aiSilenceTarget()) }
            if let bc, bc.freeze { return .some(p.board.filter { !$0.isFrozen }.max(by: { $0.atk < $1.atk })?.id) }
            if let bc, bc.tgt == .ally { return .some(aiBestAlly()) }
            if let bc, let tgt = bc.tgt { return .some(aiDamageTarget(bc.dmg, tgt)) }
            return .some(nil)
        }
        guard let fx = cardFx(.e, k) else { return nil }
        let bonus = spellBonus(.e, k)
        let foes = p.board
        func best(_ l: [Minion], _ score: (Minion) -> Int) -> EID?? {
            guard let m = l.max(by: { score($0) < score($1) }) else { return nil }
            return .some(m.id)
        }
        if fx.icelance > 0 {
            let fr = foes.filter { $0.isFrozen && !$0.ward }
            let reach = fx.icelance + bonus + (tal(.e, "fr_deep") ? 2 : 0) + (tal(.e, "fr_perma") ? 1 : 0)
            if let t = fr.filter({ $0.hp <= reach }).max(by: { $0.atk < $1.atk }) ?? fr.max(by: { $0.atk < $1.atk })
                ?? foes.filter({ $0.atk >= 3 && !$0.isFrozen }).max(by: { $0.atk < $1.atk }) { return .some(t.id) }
            return nil
        }
        if fx.freezeBig && foes.isEmpty && e.hp > e.max - 5 { return nil }
        if fx.destroy {
            let l = targetsFor(.e, fx.tgt ?? .foe, fx.cond).compactMap { minion($0) }
            guard let m = l.max(by: { aiValue($0) < aiValue($1) }), aiValue(m) >= (c.cost >= 3 ? 8 : 5) else { return nil }
            return .some(m.id)
        }
        if fx.silence { return aiSilenceTarget().map { .some($0) } ?? nil }
        if fx.setAtk > 0 { return best(foes.filter { $0.atk >= 4 }) { $0.atk } }
        if fx.setHp > 0 { return best(foes.filter { $0.hp >= 5 }) { $0.hp } }
        if fx.freezeAll { return foes.filter { $0.atk >= 2 }.count >= 2 ? .some(nil) : nil }
        if fx.aoe > 0 {
            let hits = foes.contains { !$0.ward && $0.hp <= fx.aoe + bonus }
            if fx.face == 0 && foes.count < 2 && !hits { return nil }
            if fx.face > 0 && fx.aoe < 3 && !hits && foes.count < 2 && p.hp > fx.face + bonus { return nil }
        }
        if fx.sweep > 0 {
            let n = fx.sweep + bonus
            func dies(_ l: [Minion]) -> Int { l.filter { !$0.ward && $0.hp <= n }.reduce(0) { $0 + aiValue($1) } }
            if fx.heroes && e.hp + e.armor <= n + 6 { return nil }
            return dies(foes) >= dies(e.board) + 5 ? .some(nil) : nil
        }
        if fx.armorDmg {
            guard e.armor + fx.plus + bonus >= 2, let t = aiDamageTarget(e.armor + fx.plus + bonus, .minion) else { return nil }
            return .some(t)
        }
        if fx.drawIfKill { return best(foes.filter { !$0.ward && $0.hp <= fx.dmg + bonus }) { $0.atk } }
        if fx.dmg > 0 && fx.buff != nil { return best(e.board.filter { ($0.hp > fx.dmg || $0.ward) && !$0.isFrozen }) { $0.atk } }
        if fx.tempAtk > 0 { return best(e.board.filter { !$0.sleep && !$0.attacked && !$0.isFrozen }) { $0.atk } }
        if fx.bounce { return best(e.board.filter { $0.card.bc != nil && !$0.card.token && $0.hp * 2 <= $0.max }) { $0.card.cost } }
        if fx.perFoe != nil { return foes.count >= 2 && e.board.count < Self.boardMax ? .some(nil) : nil }
        if fx.ward && fx.tgt != nil { return best(e.board.filter { !$0.ward }) { $0.atk } }
        if fx.dmg > 0 {
            let beast = fx.dmgBeast > 0 && e.board.contains { $0.card.race == "beast" }
            if fx.selfDmg > 0 && e.hp <= fx.selfDmg + 8 { return nil }
            if let t = aiDamageTarget((beast ? fx.dmgBeast : fx.dmg) + bonus, fx.tgt) { return .some(t) }
            return nil
        }
        if fx.buff != nil { if let t = aiBestAlly() { return .some(t) }; return nil }
        return aiWorth(fx) ? .some(nil) : nil
    }

    /// Whether and where to use the enemy hero power.
    func aiPowerPlan() -> EID?? {
        let pw = e.power
        if aiEasy || e.mana < pcost(.e) { return nil }
        let fx = pw.fx
        if fx.dmg > 0 { if let t = aiDamageTarget(fx.dmg + powerBonus(.e), pw.tgt) { return .some(t) }; return nil }
        if fx.healT > 0 {
            let cands = ([e.id] + e.board.map(\.id)).filter { hp($0) < maxHp($0) }
            if let t = cands.max(by: { (maxHp($0) - hp($0)) < (maxHp($1) - hp($1)) }) { return .some(t) }
            if fx.hasten > 0 && !e.altar.isEmpty { return .some(e.id) }
            return nil
        }
        if fx.buff != nil { if let t = aiBestAlly() { return .some(t) }; return nil }
        if fx.tempAtk > 0 {
            if let t = e.board.filter({ !$0.sleep && !$0.attacked && !$0.isFrozen }).max(by: { $0.atk < $1.atk }) { return .some(t.id) }
            return nil
        }
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
            guard canPay(.e, k) else { return nil }
            return (k, i)
        }.sorted { costOf(.e, $0.key) > costOf(.e, $1.key) }
    }
}
