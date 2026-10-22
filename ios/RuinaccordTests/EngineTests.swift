import XCTest
@testable import Ruinaccord

final class EngineTests: XCTestCase {
    func testDataLoads() {
        let gd = GameData.shared
        XCTAssertEqual(gd.cards.count, 123)
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

    func testTalents() {
        let gd = GameData.shared
        for cls in gd.classes {
            XCTAssertTrue(gd.hasTalents(cls.id), cls.id)
            for i in 0..<3 {
                let p = gd.talentPreset(cls.id, i)
                XCTAssertEqual(p.count, gd.talents.maxPts, "\(cls.id) preset \(i)")
                XCTAssertTrue(gd.validTalents(cls.id, p), "\(cls.id) preset \(i)")
            }
            guard let adv = gd.talents.adv[cls.id] else { XCTFail(cls.id); continue }
            XCTAssertEqual(adv.packs.count, gd.opponents.count - 1, cls.id)
            XCTAssertTrue(Decks.isValid(adv.deck, cls: cls.id), cls.id)
            for st in adv.packs { for p in st { for k in p.cards { XCTAssertNotNil(gd.card(k), k) }; for h in p.hint { XCTAssertNotNil(gd.talentNode(h), h) } } }
            for lang in Lang.allCases { let tx = Tx(lang: lang); for pg in gd.talentPages(cls.id) { for row in pg.tiers { for n in row { XCTAssertFalse(tx.name(n.desc).isEmpty) } } } }
        }
        // Tier gating: a tier-2 node needs a tier-1 pick above it (either page), one pick a tier across both pages;
        // pruning drops a node when the pick above it goes.
        XCTAssertFalse(gd.validTalents("mage", ["fi_fireball"]))
        XCTAssertTrue(gd.validTalents("mage", ["fi_ignite", "fi_fireball"]))
        XCTAssertTrue(gd.validTalents("mage", ["fi_ignite", "fr_bolt", "fi_spark", "fr_deep"]))
        XCTAssertFalse(gd.validTalents("mage", ["fi_ignite", "fi_heart"]))
        XCTAssertFalse(gd.validTalents("mage", ["fi_ignite", "fr_blood"]))
        XCTAssertEqual(gd.pruneTalents(["fi_fireball", "fi_spark"]), [])
        XCTAssertEqual(gd.talents.maxPts, 4)
        XCTAssertEqual(gd.advPoints(0), 1); XCTAssertEqual(gd.advPoints(3), 2); XCTAssertEqual(gd.advPoints(7), 4)
        // Overrides change the owner's card: Frostbolt deals 5 with its talent, Frost Nova costs 1 less, Frost Blood adds Health.
        var s = DuelState(mode: .quick, pcls: "mage", ecls: "warrior", diff: .normal,
                          p: DuelState.makeHero(.p, hp: 30, deck: [], power: gd.cls("mage")!.power),
                          e: DuelState.makeHero(.e, hp: 30, deck: [], power: gd.cls("warrior")!.power))
        s.setupTalents(.p, cls: "mage", ["fr_blood"])
        XCTAssertEqual(s.p.hp, 37)
        s.setupTalents(.p, cls: "mage", ["fr_nova", "fr_bolt"])
        XCTAssertEqual(s.costOf(.p, "frostnova"), gd.card("frostnova")!.cost - 1)
        XCTAssertEqual(s.cardFx(.p, "frostbolt")?.dmg, 5)
        s.p.mana = 10; s.castSpell(.p, "frostbolt", .hero(.e)); XCTAssertEqual(s.e.hp, 25)
        XCTAssertFalse(Tx(lang: .zh).cardText(gd.card("frostbolt")!, ovr: s.p.ovr["frostbolt"]).isEmpty)
        // Class resources. Warrior: Rage from the power and from hero damage, bursting at 4 into +2 Attack.
        s.setupTalents(.p, cls: "warrior", [])
        s.p.deck = Array(repeating: "goblin", count: 8); s.e.deck = Array(repeating: "goblin", count: 8)   // no fatigue damage below
        s.p.rage = 0; s.afterPower(.p); s.damage(.hero(.p), 1); s.damage(.hero(.p), 1); s.damage(.hero(.p), 1)
        XCTAssertEqual(s.p.rage, 4)
        s.summon(.p, "goblin"); s.turn = .e; s.startTurn(.e); s.turn = .p; s.startTurn(.p)
        XCTAssertEqual(s.p.rage, 0); XCTAssertEqual(s.p.board[0].atk, gd.card("goblin")!.atk! + 2)
        // Warlock: Souls from friendly deaths; the power spends 2 instead of hurting; 5 become a Bone Warrior.
        s.setupTalents(.p, cls: "warlock", []); s.p.board = []; s.p.soul = 0
        s.summon(.p, "goblin"); s.damage(s.p.board[0].id, 9); s.cleanup()
        XCTAssertEqual(s.p.soul, 1)
        s.p.soul = 2; let hp0 = s.p.hp
        s.applyFx(.p, gd.cls("warlock")!.power.fx, nil, isPower: true)
        XCTAssertEqual(s.p.hp, hp0); XCTAssertEqual(s.p.soul, 0)
        s.p.soul = 5; s.turn = .e; s.startTurn(.e)
        XCTAssertTrue(s.p.board.contains { $0.key == "bonewarr" }); XCTAssertEqual(s.p.soul, 0)
        // Priest: healing past full is Light, and Light shortens a Prayer's wait.
        s.setupTalents(.p, cls: "priest", []); s.p.light = 0; s.p.hp = s.p.max
        s.heal(.hero(.p), 3); XCTAssertEqual(s.p.light, 3)
        s.p.light = 2; s.castSpell(.p, "matins", nil); XCTAssertEqual(s.p.altar.last?.cd, gd.card("matins")!.pray!.cd - 1); XCTAssertEqual(s.p.light, 0)
        s.p.altar = []
        // Hunter: Ferocity per Beast in hand at the start of a turn; the power spends 2 for +1 damage; a Beast with 3 Charges.
        s.setupTalents(.p, cls: "hunter", []); s.p.fero = 0; s.p.hand = ["direwolf", "boar", "goblin"]; s.p.board = []
        s.turn = .e; s.startTurn(.e); s.turn = .p; s.startTurn(.p)
        XCTAssertEqual(s.p.fero, 2)
        let ehp = s.e.hp
        s.applyFx(.p, gd.cls("hunter")!.power.fx, nil, isPower: true)
        XCTAssertEqual(s.e.hp, ehp - gd.cls("hunter")!.power.fx.face - 1); XCTAssertEqual(s.p.fero, 0)
        s.p.fero = 3; s.summon(.p, "panther"); s.summon(.p, "direwolf")
        XCTAssertFalse(s.p.board[1].sleep); XCTAssertEqual(s.p.fero, 0)
        // Paladin: Oaths are Prayers; Unity gives +1 Attack when one is answered.
        s.setupTalents(.p, cls: "paladin", ["pa_drill", "pa_command", "pa_double", "pa_coop"]); s.p.board = []; s.p.mana = 10
        s.summon(.p, "goblin"); let a0 = s.p.board[0].atk
        s.castSpell(.p, "oathmuster", nil); XCTAssertEqual(s.p.altar.count, 1)
        for _ in 0..<(gd.card("oathmuster")!.pray!.cd) { s.turn = .e; s.startTurn(.e); s.turn = .p; s.startTurn(.p) }
        XCTAssertTrue(s.p.altar.isEmpty); XCTAssertEqual(s.p.board.filter { $0.key == "minnow" }.count, 3); XCTAssertEqual(s.p.board[0].atk, a0 + 1)
        s.p.board = []; s.p.altar = []
        // Prayers wait on the altar and resolve after their countdown.
        s.setupTalents(.p, cls: "priest", [])
        s.castSpell(.p, "matins", nil); XCTAssertEqual(s.p.altar.count, 1)
        let cd = s.p.altar[0].cd
        for _ in 0..<cd { s.turn = .e; s.startTurn(.e); s.turn = .p; s.startTurn(.p) }
        XCTAssertTrue(s.p.altar.isEmpty)
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
                s.e.castHb = s.hbOf(.e)[safe: o.index] ?? 0
                guard let plan = s.aiPlan(o.key), let c = GameData.shared.card(o.key) else { continue }
                var t = plan
                s.pay(.e, c.id)
                s.takeHand(.e, o.index)
                if c.isMinion {
                    let m = s.summon(.e, c.id)
                    if let bc = s.cardBc(.e, c.id), let m {
                        if bc.tgt == .ally && t == nil { t = m.id }
                        s.applyFx(.e, bc, t)
                    }
                } else if c.fx != nil || c.isPrayer { s.castSpell(.e, c.id, t) }
                did = true
                s.cleanup()
                break
            }
            if !did { break }
        }
        if !s.over, let plan = s.aiPowerPlan() {
            s.e.mana -= s.pcost(.e); s.e.powerUsed = true
            s.applyFx(.e, s.e.power.fx, plan, bonus: s.powerBonus(.e), isPower: true); s.afterPower(.e); s.cleanup()
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
            var s = DuelState.onlineStart(hostCls: a.id, hostDeck: Decks.pad(a.deck, rarities: ["c", "r", "e", "l"], cls: a.id), hostTal: gd.talentPreset(a.id, g % 3),
                                          guestCls: b.id, guestDeck: Decks.pad(b.deck, rarities: ["c", "r", "e", "l"], cls: b.id), guestTal: gd.talentPreset(b.id, (g + 1) % 3))
            open(&s)
            var rounds = 0
            while !s.over && rounds < 300 {
                rounds += 1
                if s.turn == .p { s = s.flipped(); aiTurn(&s); s = s.flipped() } else { aiTurn(&s) }
                XCTAssertLessThanOrEqual(s.p.board.count, DuelState.boardMax)
                XCTAssertLessThanOrEqual(s.e.board.count, DuelState.boardMax)
                XCTAssertLessThanOrEqual(s.p.hand.count, 10)
                for h in [s.p, s.e] { XCTAssertTrue((0...5).contains(h.spellMana)); XCTAssertGreaterThanOrEqual(h.mana, 0) }
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
        open(&s)
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

    /// Both sides mulligan like the AI, then the coin and the first turn (as the app does after the mulligan screen).
    private func open(_ s: inout DuelState) {
        XCTAssertTrue(s.mulligan)
        s.applyMulligan(.p, s.aiMulliganPicks(.p)); s.applyMulligan(.e, s.aiMulliganPicks(.e))
        s.mulligan = false
        s[s.turn.other].hand.append("coin")
        s.startTurn(s.turn)
    }

    func testMulligan() {
        let gd = GameData.shared
        var s = DuelState.onlineStart(hostCls: "mage", hostDeck: Decks.pad(gd.cls("mage")!.deck, rarities: ["c"], cls: "mage"),
                                      guestCls: "warrior", guestDeck: Decks.pad(gd.cls("warrior")!.deck, rarities: ["r"], cls: "warrior"))
        XCTAssertTrue(s.mulligan); XCTAssertFalse(s.p.hand.contains("coin") || s.e.hand.contains("coin"))
        let side = s.turn, hand = s[side].hand, deck = s[side].deck
        s.applyMulligan(side, [0, 2, 2, 9])          // duplicates and out-of-range indices are ignored
        XCTAssertEqual(s[side].hand.count, hand.count)
        XCTAssertEqual(s[side].deck.count, deck.count)
        XCTAssertEqual(Array(s[side].deck.prefix(2)), [hand[0], hand[2]])   // replaced cards go to the bottom
        XCTAssertEqual(s[side].hand[0], hand[1])                          // kept cards stay, new ones follow
        XCTAssertEqual(Array(s[side].hand.suffix(2)), [deck[deck.count - 1], deck[deck.count - 2]])
        // the same choices give the same result on the other phone (flipped view)
        var a = DuelState.onlineStart(hostCls: "mage", hostDeck: gd.cls("mage")!.deck + ["ogre", "ogre", "golem", "golem", "lurker"],
                                      guestCls: "priest", guestDeck: gd.cls("priest")!.deck + ["ogre", "ogre", "golem", "golem", "lurker"])
        var b = a.flipped()
        a.applyMulligan(.p, [1]); a.applyMulligan(.e, [0, 2])
        b.applyMulligan(.e, [1]); b.applyMulligan(.p, [0, 2])
        XCTAssertEqual(a.hash(hostSide: .p), b.hash(hostSide: .e))
    }

    private func blank() -> DuelState {
        let gd = GameData.shared
        return DuelState(mode: .quick, pcls: "warrior", ecls: "mage", diff: .normal,
                         p: DuelState.makeHero(.p, hp: 30, deck: Array(repeating: "goblin", count: 10), power: gd.cls("warrior")!.power),
                         e: DuelState.makeHero(.e, hp: 30, deck: Array(repeating: "goblin", count: 10), power: gd.cls("mage")!.power))
    }

    func testNewSpellMechanics() {
        var s = blank()
        // Spell mana: a Mage's unspent mana is banked (max 3) when the turn passes and only spells may use it;
        // other classes bank nothing.
        s.startTurn(.p); s.p.mana = 5; s.startTurn(.e)
        XCTAssertEqual(s.p.spellMana, 0, "a warrior banks no spell mana")
        s.p.cls = "mage"
        s.startTurn(.p); s.p.mana = 5; s.startTurn(.e)
        XCTAssertEqual(s.p.spellMana, 3); XCTAssertEqual(s.p.mana, 0)
        s.p.mana = 1
        XCTAssertTrue(s.canPay(.p, "frostnova")); XCTAssertFalse(s.canPay(.p, "direwolf"))
        s.pay(.p, "frostnova"); XCTAssertEqual(s.p.spellMana, 1); XCTAssertEqual(s.p.mana, 1)
        s.p.spellMana = 1; s.p.mana = 2; s.pay(.p, "frostbolt"); XCTAssertEqual(s.p.spellMana, 0); XCTAssertEqual(s.p.mana, 1)

        // Freeze: the frozen minion skips its next turn, then thaws.
        let f = s.summon(.e, "lurker")!
        s.castSpell(.p, "frostbolt", f.id)
        XCTAssertEqual(s.minion(f.id)?.hp, 1); XCTAssertTrue(s.minion(f.id)!.isFrozen)   // Frostbolt: 4 damage
        s.startTurn(.e); XCTAssertFalse(s.canAttack(s.minion(f.id)!))
        s.startTurn(.p); XCTAssertFalse(s.minion(f.id)!.isFrozen)
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
            open(&s)
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

    /// The opponent counts as present when their heartbeat or move arrives, measured on this phone's clock.
    @MainActor func testOpponentPresence() async throws {
        let m = OnlineMatch(id: "m", role: .host, myUid: "me", foeUid: "foe",
                            send: { _, _, _, _ in }, reset: { _ in }, again: {}, leave: { _ in }, drop: { _ in }, beat: {}, mull: { _ in })
        func doc(beat: Double, actsBy: String? = nil, seq: Int = 0) -> MatchDoc {
            MatchDoc(players: ["me", "foe"], h: "me", g: "foe", hc: "mage", gc: "priest", hDeck: [], gDeck: [], v: "x", game: 1, state: nil,
                     seq: seq, acts: [], actsBy: actsBy, again: [:], left: nil, beat: ["me": 0, "foe": beat], createdAt: 0, updatedAt: 0)
        }
        m.receive(doc(beat: 100))
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertGreaterThan(m.foeIdle, 0.25)
        m.receive(doc(beat: 100))                 // nothing new from the opponent
        XCTAssertGreaterThan(m.foeIdle, 0.25)
        m.receive(doc(beat: 90))                  // a heartbeat (even with a clock behind ours) counts
        XCTAssertLessThan(m.foeIdle, 0.1)
        try await Task.sleep(for: .milliseconds(300))
        m.receive(doc(beat: 90, actsBy: "foe", seq: 3))   // a move counts too
        XCTAssertLessThan(m.foeIdle, 0.1)
    }
}
