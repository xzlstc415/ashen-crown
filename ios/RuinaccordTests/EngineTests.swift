import XCTest
@testable import Ruinaccord

final class EngineTests: XCTestCase {
    func testDataLoads() {
        let gd = GameData.shared
        XCTAssertEqual(gd.cards.count, 90)
        XCTAssertEqual(gd.classes.count, 6)
        XCTAssertEqual(gd.opponents.count, 8)
        XCTAssertEqual(gd.deckSize, 25)
        for c in gd.classes {
            XCTAssertEqual(c.deck.count, 20, c.id); XCTAssertTrue(Decks.isValid(c.deck, cls: c.id), c.id)
            XCTAssertGreaterThanOrEqual(c.deck.filter { gd.card($0)?.isMinion == false }.count, 7, c.id)
        }
        // Class cards are only legal for their class.
        XCTAssertFalse(Decks.isValid(["frostbolt"], cls: "warrior"))
        XCTAssertTrue(Decks.isValid(["frostbolt", "retreat"], cls: "mage"))
        for c in gd.cards { for k in (c.fx?.summon ?? []) + [c.fx?.perFoe, c.gasp].compactMap({ $0 }) { XCTAssertNotNil(gd.card(k), c.id) } }
        for o in gd.opponents { XCTAssertTrue(o.deck.allSatisfy { gd.card($0) != nil }) }
    }

    func testCardTextInEveryLanguage() {
        for lang in Lang.allCases {
            let tx = Tx(lang: lang)
            for c in GameData.shared.cards {
                let t = tx.cardText(c)
                if c.bc != nil || c.fx != nil || c.hasGuard || c.ward || c.surge || c.gasp != nil { XCTAssertFalse(t.isEmpty, "\(c.id) \(lang)") }
                XCTAssertFalse(tx.name(c.names).isEmpty)
            }
            for k in GameData.shared.classes { XCTAssertFalse(tx.powerDesc(k.power).isEmpty) }
        }
    }

    /// Plays one full turn for side `e` using the AI decisions (no animations).
    private func aiTurn(_ s: inout DuelState) {
        s.round += 1
        s.startTurn(.e)
        s.cleanup()
        for _ in 0..<12 where !s.over {
            var did = false
            for o in s.aiPlayable() {
                guard let plan = s.aiPlan(o.key), let c = GameData.shared.card(o.key) else { continue }
                var t = plan
                s.pay(.e, c.id)
                s.e.hand.remove(at: o.index)
                if c.isMinion {
                    let m = s.summon(.e, c.id)
                    if let bc = c.bc, let m {
                        if bc.tgt == .ally && t == nil { t = m.id }
                        s.applyFx(.e, bc, t)
                    }
                } else if c.fx != nil { s.castSpell(.e, c.id, t) }
                did = true
                s.cleanup()
                break
            }
            if !did { break }
        }
        if !s.over, let plan = s.aiPowerPlan() {
            s.e.mana -= s.e.power.cost; s.e.powerUsed = true
            s.applyFx(.e, s.e.power.fx, plan); s.cleanup()
        }
        for m in s.e.board where !s.over {
            guard let cur = s.minion(m.id), s.canAttack(cur) else { continue }
            s.attack(m.id, s.aiAttackTarget(cur)); s.cleanup()
        }
        if !s.over { s.turn = .p; s.startTurn(.p); s.cleanup() }
    }

    func testRandomGamesFinish() {
        let gd = GameData.shared
        var results: [GameResult: Int] = [:]
        for g in 0..<60 {
            let a = gd.classes[g % 6], b = gd.classes[(g * 5 + 1) % 6]
            var s = DuelState.onlineStart(hostCls: a.id, hostDeck: Decks.pad(a.deck, rarities: ["c", "r", "e", "l"], cls: a.id),
                                          guestCls: b.id, guestDeck: Decks.pad(b.deck, rarities: ["c", "r", "e", "l"], cls: b.id))
            var rounds = 0
            while !s.over && rounds < 300 {
                rounds += 1
                if s.turn == .p { s = s.flipped(); aiTurn(&s); s = s.flipped() } else { aiTurn(&s) }
                XCTAssertLessThanOrEqual(s.p.board.count, DuelState.boardMax)
                XCTAssertLessThanOrEqual(s.e.board.count, DuelState.boardMax)
                XCTAssertLessThanOrEqual(s.p.hand.count, 10)
                for h in [s.p, s.e] { XCTAssertTrue((0...3).contains(h.spellMana)); XCTAssertGreaterThanOrEqual(h.mana, 0) }
            }
            XCTAssertTrue(s.over, "game \(g) did not finish")
            if let r = s.result { results[r, default: 0] += 1 }
        }
        XCTAssertGreaterThan(results[.win, default: 0] + results[.lose, default: 0], 45)
    }

    func testFlipIsSymmetricAndCodable() throws {
        let gd = GameData.shared
        var s = DuelState.onlineStart(hostCls: "mage", hostDeck: Decks.pad(gd.cls("mage")!.deck, rarities: ["c"], cls: "mage"),
                                      guestCls: "warrior", guestDeck: Decks.pad(gd.cls("warrior")!.deck, rarities: ["r"], cls: "warrior"))
        if s.turn == .p { s = s.flipped() }
        aiTurn(&s)
        let f = s.flipped()
        XCTAssertEqual(s.hash(hostSide: .p), f.hash(hostSide: .e))
        XCTAssertEqual(f.flipped().hash(hostSide: .p), s.hash(hostSide: .p))
        XCTAssertEqual(f.p.hp, s.e.hp)
        XCTAssertTrue(f.p.board.allSatisfy { $0.side == .p })
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(DuelState.self, from: data)
        XCTAssertEqual(back.hash(hostSide: .p), s.hash(hostSide: .p))
        XCTAssertTrue(back.events.isEmpty)
    }

    func testRulesDetails() {
        var s = DuelState(mode: .quick, pcls: "warrior", ecls: "mage", diff: .normal,
                          p: DuelState.makeHero(.p, hp: 30, deck: ["goblin", "goblin"], power: GameData.shared.cls("warrior")!.power),
                          e: DuelState.makeHero(.e, hp: 30, deck: [], power: GameData.shared.cls("mage")!.power))
        // Ward absorbs one hit, guard is forced.
        let g = s.summon(.e, "crab")!      // 1/4 guard
        let w = s.summon(.e, "pearl")!     // 1/1 ward
        XCTAssertEqual(s.attackTargets(.p), [g.id])
        s.damage(w.id, 5); XCTAssertEqual(s.minion(w.id)?.hp, 1); XCTAssertFalse(s.minion(w.id)!.ward)
        s.damage(w.id, 1); s.cleanup(); XCTAssertNil(s.minion(w.id))
        // Armor absorbs before health; fatigue damages when the deck is empty.
        s.p.armor = 3; s.damage(.hero(.p), 5); XCTAssertEqual(s.p.hp, 28); XCTAssertEqual(s.p.armor, 0)
        s.draw(.e, 2); XCTAssertEqual(s.e.hp, 27); XCTAssertEqual(s.e.fat, 2)
        // Last breath summons a token; the board cap holds.
        let t = s.summon(.p, "sailor")!; s.damage(t.id, 9); s.cleanup()
        XCTAssertEqual(s.p.board.map(\.key), ["bubble"])
        for _ in 0..<6 { s.summon(.p, "goblin") }
        XCTAssertEqual(s.p.board.count, DuelState.boardMax)
        // Charge minions can attack at once, others sleep.
        let b = s.summon(.e, "berserker")!; XCTAssertFalse(b.sleep); XCTAssertTrue(s.summon(.e, "lurker")!.sleep)
    }

    private func blank() -> DuelState {
        let gd = GameData.shared
        return DuelState(mode: .quick, pcls: "warrior", ecls: "mage", diff: .normal,
                         p: DuelState.makeHero(.p, hp: 30, deck: Array(repeating: "goblin", count: 10), power: gd.cls("warrior")!.power),
                         e: DuelState.makeHero(.e, hp: 30, deck: Array(repeating: "goblin", count: 10), power: gd.cls("mage")!.power))
    }

    func testNewSpellMechanics() {
        var s = blank()
        // Spell mana: unspent mana is banked (max 3) when the turn passes and only spells may use it.
        s.startTurn(.p); s.p.mana = 5; s.startTurn(.e)
        XCTAssertEqual(s.p.spellMana, 3); XCTAssertEqual(s.p.mana, 0)
        s.p.mana = 1
        XCTAssertTrue(s.canPay(.p, "frostnova")); XCTAssertFalse(s.canPay(.p, "direwolf"))
        s.pay(.p, "frostnova"); XCTAssertEqual(s.p.spellMana, 1); XCTAssertEqual(s.p.mana, 1)
        s.p.spellMana = 1; s.p.mana = 2; s.pay(.p, "frostbolt"); XCTAssertEqual(s.p.spellMana, 0); XCTAssertEqual(s.p.mana, 1)

        // Freeze: the frozen minion skips its next turn, then thaws.
        let f = s.summon(.e, "lurker")!
        s.castSpell(.p, "frostbolt", f.id)
        XCTAssertEqual(s.minion(f.id)?.hp, 2); XCTAssertTrue(s.minion(f.id)!.frozen)
        s.startTurn(.e); XCTAssertFalse(s.canAttack(s.minion(f.id)!))
        s.startTurn(.p); XCTAssertFalse(s.minion(f.id)!.frozen)
        s.turn = .e; s.startTurn(.e); XCTAssertTrue(s.canAttack(s.minion(f.id)!))

        // Silence removes buffs, keywords and last breath.
        var t = blank()
        let g = t.summon(.e, "sailor")!          // last breath
        t.applyFx(.e, GameData.shared.card("kings")!.fx!, g.id)
        t.castSpell(.p, "dispel", g.id)
        let gm = t.minion(g.id)!
        XCTAssertEqual(gm.atk, 1); XCTAssertEqual(gm.max, 2); XCTAssertTrue(gm.silenced); XCTAssertNil(gm.gasp)
        t.damage(g.id, 5); t.cleanup(); XCTAssertTrue(t.e.board.isEmpty)

        // Conditional destroy targets.
        var d = blank()
        let small = d.summon(.e, "goblin")!, big = d.summon(.e, "ogre")!
        XCTAssertEqual(d.targetsFor(.p, .foe, "atk<=3"), [small.id])
        XCTAssertEqual(d.targetsFor(.p, .foe, "atk>=5"), [big.id])
        XCTAssertTrue(d.targetsFor(.p, .foe, "damaged").isEmpty)
        d.damage(big.id, 1); XCTAssertEqual(d.targetsFor(.p, .foe, "damaged"), [big.id])
        d.castSpell(.p, "execute", big.id); d.cleanup(); XCTAssertNil(d.minion(big.id))

        // Set stats, temporary attack, sweep with heroes, armor damage, beast bonus, draw on kill.
        var x = blank()
        let o = x.summon(.e, "ogre")!
        x.castSpell(.p, "humility", o.id); XCTAssertEqual(x.minion(o.id)?.atk, 1)
        x.castSpell(.p, "huntmark", o.id); XCTAssertEqual(x.minion(o.id)?.hp, 1)
        let w = x.summon(.p, "direwolf")!
        x.castSpell(.p, "pounce", w.id); XCTAssertEqual(x.minion(w.id)?.atk, 5)
        x.startTurn(.e); XCTAssertEqual(x.minion(w.id)?.atk, 3)
        x.castSpell(.p, "killcmd", .hero(.e)); XCTAssertEqual(x.e.hp, 25)    // beast on board: 5
        x.p.armor = 4; let tr = x.summon(.e, "lurker")!
        x.castSpell(.p, "shieldslam", tr.id); XCTAssertEqual(x.minion(tr.id)?.hp, 1)
        let hand = x.p.hand.count
        x.castSpell(.p, "coil", tr.id); x.cleanup(); XCTAssertNil(x.minion(tr.id)); XCTAssertEqual(x.p.hand.count, hand + 1)
        x.p.armor = 0
        let ph = x.p.hp, eh = x.e.hp
        x.castSpell(.p, "hellfire", nil); x.cleanup()
        XCTAssertEqual(x.p.hp, ph - 3); XCTAssertEqual(x.e.hp, eh - 3); XCTAssertTrue(x.p.board.isEmpty && x.e.board.isEmpty)

        // Hounds per enemy minion, bounce, spell damage and spell-cast growth.
        var y = blank()
        y.summon(.e, "goblin"); y.summon(.e, "goblin"); y.summon(.e, "goblin")
        y.castSpell(.p, "hounds", nil)
        XCTAssertEqual(y.p.board.filter { $0.key == "hound" }.count, 3)
        XCTAssertTrue(y.p.board.allSatisfy { !$0.sleep })
        var z = blank()
        let geo = z.summon(.p, "geomancer")!, wy = z.summon(.p, "wyrmling")!
        _ = geo
        z.castSpell(.p, "missiles", nil)                     // 1 + Spell Damage 1
        XCTAssertEqual(z.e.hp, 28); XCTAssertEqual(z.minion(wy.id)?.atk, 3)
        z.castSpell(.p, "retreat", wy.id)
        XCTAssertNil(z.minion(wy.id)); XCTAssertEqual(z.p.hand.last, "wyrmling")
    }

    /// AI against AI with each class's starting deck (padded with normal-difficulty cards).
    func testClassBalance() {
        let gd = GameData.shared
        var won: [String: Int] = [:], played: [String: Int] = [:]
        for g in 0..<2160 {
            let a = gd.classes[g % 6], b = gd.classes[(g / 6) % 6]
            if a.id == b.id { continue }
            var s = DuelState.onlineStart(hostCls: a.id, hostDeck: Decks.pad(a.deck, rarities: ["r", "e"], cls: a.id),
                                          guestCls: b.id, guestDeck: Decks.pad(b.deck, rarities: ["r", "e"], cls: b.id))
            var rounds = 0
            while !s.over && rounds < 300 {
                rounds += 1
                if s.turn == .p { s = s.flipped(); aiTurn(&s); s = s.flipped() } else { aiTurn(&s) }
            }
            played[a.id, default: 0] += 1; played[b.id, default: 0] += 1
            if s.result == .win { won[a.id, default: 0] += 1 } else if s.result == .lose { won[b.id, default: 0] += 1 }
        }
        var line = "BALANCE"
        for c in gd.classes {
            let r = Double(won[c.id, default: 0]) / Double(max(1, played[c.id, default: 0]))
            line += " \(c.id)=\(Int(r * 100))%"
            XCTAssertTrue((0.3...0.7).contains(r), "\(c.id) win rate \(r)")
        }
        print(line)
    }
}
