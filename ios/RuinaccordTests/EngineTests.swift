import XCTest
@testable import Ruinaccord

final class EngineTests: XCTestCase {
    func testDataLoads() {
        let gd = GameData.shared
        XCTAssertEqual(gd.cards.count, 58)
        XCTAssertEqual(gd.classes.count, 6)
        XCTAssertEqual(gd.opponents.count, 8)
        XCTAssertEqual(gd.deckSize, 25)
        for c in gd.classes { XCTAssertEqual(c.deck.count, 20, c.id); XCTAssertTrue(Decks.isValid(c.deck), c.id) }
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
                s.e.mana -= c.cost
                s.e.hand.remove(at: o.index)
                if c.isMinion {
                    let m = s.summon(.e, c.id)
                    if let bc = c.bc, let m {
                        if bc.tgt == .ally && t == nil { t = m.id }
                        s.applyFx(.e, bc, t)
                    }
                } else if let fx = c.fx { s.applyFx(.e, fx, t) }
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
        for g in 0..<40 {
            let a = gd.classes[g % 6], b = gd.classes[(g * 5 + 1) % 6]
            var s = DuelState.onlineStart(hostCls: a.id, hostDeck: Decks.pad(a.deck, rarities: ["c", "r", "e", "l"]),
                                          guestCls: b.id, guestDeck: Decks.pad(b.deck, rarities: ["c", "r", "e", "l"]))
            var rounds = 0
            while !s.over && rounds < 300 {
                rounds += 1
                if s.turn == .p { s = s.flipped(); aiTurn(&s); s = s.flipped() } else { aiTurn(&s) }
                XCTAssertLessThanOrEqual(s.p.board.count, DuelState.boardMax)
                XCTAssertLessThanOrEqual(s.e.board.count, DuelState.boardMax)
                XCTAssertLessThanOrEqual(s.p.hand.count, 10)
            }
            XCTAssertTrue(s.over, "game \(g) did not finish")
            if let r = s.result { results[r, default: 0] += 1 }
        }
        XCTAssertGreaterThan(results[.win, default: 0] + results[.lose, default: 0], 30)
    }

    func testFlipIsSymmetricAndCodable() throws {
        let gd = GameData.shared
        var s = DuelState.onlineStart(hostCls: "mage", hostDeck: Decks.pad(gd.cls("mage")!.deck, rarities: ["c"]),
                                      guestCls: "warrior", guestDeck: Decks.pad(gd.cls("warrior")!.deck, rarities: ["r"]))
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
}
