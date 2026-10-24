import XCTest
@testable import Ruinaccord

final class EngineTests: XCTestCase {
    func testDataLoads() {
        let gd = GameData.shared
        XCTAssertEqual(gd.cards.count, 126)
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
                XCTAssertEqual(p.count, gd.maxPoints(cls.id), "\(cls.id) preset \(i)")
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
        XCTAssertEqual(gd.advPoints(0, "mage"), 1); XCTAssertEqual(gd.advPoints(3, "mage"), 2); XCTAssertEqual(gd.advPoints(7, "mage"), 4)
        XCTAssertEqual(gd.advPoints(7, "hunter"), 3, "the Hunter has three tiers")
        // The Hunter takes every talent from one page.
        XCTAssertTrue(gd.validTalents("hunter", ["hu_pack", "hu_combo", "hu_whistle"]))
        XCTAssertFalse(gd.validTalents("hunter", ["hu_pack", "hu_heart"]), "no mixing pages")
        XCTAssertFalse(gd.tierOpen(["hu_pack"], 1, page: "shot"), "the other page stays shut")
        XCTAssertEqual(gd.pruneTalents(["hu_precise", "hu_combo"]), ["hu_precise"])
        let old = SavedDeck(id: "x", name: "", cls: "hunter", cards: [], t: 0, tal: ["hu_tame", "hu_wild", "hu_whistle", "hu_combo"])
        XCTAssertEqual(old.talents, ["hu_tame", "hu_wild", "hu_whistle"], "an old four-talent Hunter deck keeps its Beast picks")
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
        // Hunter: no Energy by default; Tamer gives 1 per Beast card played, Quiver 1 per Hunter attack spell; the power
        // spends 2 for +1 damage; a Beast with 3 Charges.
        s.setupTalents(.p, cls: "hunter", []); s.p.fero = 0; s.p.hand = ["direwolf", "boar", "goblin"]; s.p.board = []
        s.turn = .e; s.startTurn(.e); s.turn = .p; s.startTurn(.p)
        XCTAssertEqual(s.p.fero, 0, "Beasts in hand give nothing")
        _ = s.takeHand(.p, 0); XCTAssertEqual(s.p.fero, 0, "nor does playing one without Tamer")
        s.setupTalents(.p, cls: "hunter", ["hu_tame"]); s.p.hand = ["direwolf", "goblin", "steady", "huntmark"]
        _ = s.takeHand(.p, 0); _ = s.takeHand(.p, 0); XCTAssertEqual(s.p.fero, 1, "Tamer: the Beast counts, the goblin does not")
        _ = s.takeHand(.p, 0); XCTAssertEqual(s.p.fero, 1, "Tamer does not count spells")
        s.setupTalents(.p, cls: "hunter", ["hu_quiver"]); s.p.hand = ["steady", "huntmark", "direwolf", "fireball"]
        _ = s.takeHand(.p, 0); XCTAssertEqual(s.p.fero, 2, "Quiver: a Hunter spell that deals damage")
        _ = s.takeHand(.p, 0); _ = s.takeHand(.p, 0); XCTAssertEqual(s.p.fero, 2, "not Hunter's Mark, not a Beast")
        XCTAssertEqual(s.p.hand, ["fireball"], "and Quiver no longer adds an Arcane Shot")
        let ehp = s.e.hp
        s.applyFx(.p, gd.cls("hunter")!.power.fx, nil, isPower: true)
        XCTAssertEqual(s.e.hp, ehp - gd.cls("hunter")!.power.fx.face - 1); XCTAssertEqual(s.p.fero, 0)
        s.p.fero = 3; s.summon(.p, "panther"); s.summon(.p, "direwolf")
        XCTAssertFalse(s.p.board[1].sleep); XCTAssertEqual(s.p.fero, 0)
        // Paladin Prestige: Oaths resolve at once and give 1; buffed minions give 1 each at the end of the turn (up to 2);
        // with 3 the hero power makes a 2/2 Guard recruit, and Unity gives the board +1 Attack when it is spent.
        s.setupTalents(.p, cls: "paladin", ["pa_drill", "pa_command", "pa_double", "pa_coop"]); s.p.board = []; s.p.mana = 10; s.p.pres = 0
        XCTAssertNil(gd.card("oathmuster")!.pray)
        s.castSpell(.p, "oathmuster", nil); XCTAssertTrue(s.p.altar.isEmpty)
        XCTAssertEqual(s.p.board.filter { $0.key == "minnow" }.count, 3); XCTAssertEqual(s.p.pres, 1)
        s.castSpell(.p, "oathcrusade", nil); XCTAssertEqual(s.p.pres, 2)
        s.turn = .p; s.startTurn(.e); XCTAssertEqual(s.p.pres, 4, "two of the buffed minions count")
        s.p.board = [s.p.board[0]]; let a0 = s.p.board[0].atk
        var pw = Effect(); pw.summon = ["minnow"]
        s.applyFx(.p, pw, nil, isPower: true)
        XCTAssertEqual(s.p.pres, 1); let rec = s.p.board.last!
        XCTAssertEqual(rec.atk, gd.card("minnow")!.atk! + 1); XCTAssertTrue(rec.hasGuard); XCTAssertEqual(s.p.board[0].atk, a0 + 1, "Unity")
        s.applyFx(.p, pw, nil, isPower: true); XCTAssertFalse(s.p.board.last!.hasGuard, "not enough Prestige the second time")
        s.p.board = []; s.p.altar = []; s.p.pres = 0
        // Graveyard Summoner: five of the dead on offer (no tokens), the chosen come back to the hand.
        s.setupTalents(.p, cls: "warlock", []); s.p.hand = []; s.p.hb = []
        s.p.grave = ["goblin", "minnow", "golem", "ogre", "treant", "eel", "lurker"]
        let offer = s.reclaimOffer(.p)
        XCTAssertEqual(offer.count, 5); XCTAssertFalse(offer.contains("minnow"))
        s.reclaimTake(.p, Array(offer.prefix(2)))
        XCTAssertEqual(s.p.hand.count, 2); XCTAssertEqual(s.p.grave.count, 5); XCTAssertEqual(s.p.hb.count, 2)
        XCTAssertEqual(s.aiReclaim(.p, 2).count, 2); XCTAssertEqual(s.p.hand.count, 4)
        XCTAssertEqual(gd.card("gravecaller")?.bc?.reclaim, 2)
        // Wraith Ferryman: Ethereal shrugs off attacks and hero powers, not spells; each turn it ferries a dead minion back.
        s.p.board = []; s.e.board = []; s.p.hand = []; s.p.hb = []; s.p.grave = ["minnow", "ogre"]; s.turn = .e
        s.summon(.p, "gravecaller"); s.summon(.e, "ogre")
        let wraith = s.p.board[0].id
        s.attack(s.e.board[0].id, wraith); XCTAssertEqual(s.p.board[0].hp, 3, "no attack damage"); XCTAssertEqual(s.e.board[0].hp, gd.card("ogre")!.hp! - 3, "but it still strikes back")
        var bolt = Effect(); bolt.dmg = 1; bolt.tgt = .any
        s.applyFx(.e, bolt, wraith, isPower: true); XCTAssertEqual(s.p.board[0].hp, 3, "no hero power damage")
        s.applyFx(.e, bolt, wraith); XCTAssertEqual(s.p.board[0].hp, 2, "spells hurt it")
        s.turn = .p; s.startTurn(.p)
        XCTAssertTrue(s.p.hand.contains("ogre"), "the token stays, the minion comes back"); XCTAssertEqual(s.p.grave, ["minnow"])
        s.silence(wraith); s.turn = .e; s.startTurn(.e); s.turn = .p; s.p.grave = ["ogre"]; s.startTurn(.p)
        XCTAssertEqual(s.p.grave, ["ogre"], "silenced: nothing ferried")
        s.p.board = []; s.e.board = []; s.p.hand = []; s.p.hb = []; s.p.grave = []
        // Blood Rite: the rest of the hand is sacrificed, a chosen Legendary is copied in and costs (0); the third Rite copies twice.
        s.p.hand = ["bloodrite", "goblin", "ogre"]; s.p.hb = [0, 0, 0]; s.p.mana = 2; s.p.spellMana = 0; s.p.armor = 0
        XCTAssertTrue(gd.card("bloodrite")!.rite); XCTAssertFalse(gd.card("bloodrite")!.isMinion)
        s.pay(.p, "bloodrite"); s.takeHand(.p, 0); s.castSpell(.p, "bloodrite", nil)
        XCTAssertTrue(s.p.hand.isEmpty); XCTAssertEqual(s.p.rites, 1); XCTAssertEqual(s.p.mana, 0)
        XCTAssertEqual(s.riteOffer().count, Swift.min(3, gd.collectible.filter(\.isLegendary).count)); XCTAssertTrue(s.riteOffer().allSatisfy { gd.card($0)!.isLegendary })
        XCTAssertEqual(gd.card("bloodrite")!.maxCopies, 1); XCTAssertEqual(gd.card("gravecaller")!.maxCopies, 1); XCTAssertEqual(gd.card("gravecaller")!.rarity, "e")
        s.ritePick(.p, "lich")
        XCTAssertEqual(s.p.hand, ["lich"]); XCTAssertEqual(s.costOf(.p, "lich"), 0); XCTAssertTrue(s.canPay(.p, "lich"))
        s.takeHand(.p, 0); XCTAssertEqual(s.costOf(.p, "lich"), gd.card("lich")!.cost, "only the copy was free")
        s.p.rites = DuelState.riteNeed; s.ritePick(.p, "leviathan")
        XCTAssertEqual(s.p.hand, ["leviathan", "leviathan"]); XCTAssertEqual(s.p.free["leviathan"], 2); XCTAssertEqual(s.p.hb.count, 2)
        s.p.hand = []; s.p.hb = []; s.p.free = [:]; s.e.board = []; s.p.hp = 30
        let took = s.aiRitePick(.p); XCTAssertEqual(took.count, 1); XCTAssertTrue(gd.card(took[0])!.isLegendary && gd.card(took[0])!.isMinion)
        s.p.hand = []; s.p.hb = []; s.p.free = [:]
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
        z.castSpell(.p, "missiles", .hero(.e), extra: [.hero(.e), .hero(.e)])   // three missiles, each 1 + Spell Damage 1
        XCTAssertEqual(z.e.hp, 24); XCTAssertEqual(z.minion(wy.id)?.atk, 3)
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

    func testRewardsRespectCopyLimits() {
        let gd = GameData.shared
        let legs = gd.collectible.filter(\.isLegendary).map(\.id)
        for _ in 0..<30 {
            let r = Decks.rollRewards(stage: 5, cls: "warlock", deck: legs)
            XCTAssertEqual(r.count, 3)
            XCTAssertTrue(r.allSatisfy { !legs.contains($0) }, "a Legendary the deck has is never offered again")
        }
        let twice = ["goblin", "goblin"]
        for _ in 0..<30 { XCTAssertFalse(Decks.rollRewards(stage: 0, cls: nil, deck: twice).contains("goblin")) }
    }

    func testLegendaries() {
        let gd = GameData.shared
        var s = blank()
        s.p.board = []; s.e.board = []; s.p.hand = []; s.p.hb = []; s.turn = .p
        // Ignaroth: 10/10, Spellproof, and its On play destroys every minion under 4 Health on both sides.
        s.summon(.p, "goblin"); s.summon(.e, "goblin"); s.summon(.e, "ogre")
        let wyrm = s.summon(.p, "leviathan")!; s.applyFx(.p, gd.card("leviathan")!.bc!, nil); s.cleanup()
        XCTAssertEqual(wyrm.atk, 10); XCTAssertEqual(wyrm.hp, 10); XCTAssertFalse(wyrm.hasGuard)
        XCTAssertEqual(s.p.board.map(\.key), ["leviathan"]); XCTAssertEqual(s.e.board.map(\.key), ["ogre"], "the ogre has 4+ Health")
        var bolt = Effect(); bolt.dmg = 4; bolt.tgt = .any
        s.applyFx(.e, bolt, wyrm.id, isSpell: true); XCTAssertEqual(s.minion(wyrm.id)!.hp, 10, "spells do nothing")
        s.applyFx(.e, bolt, wyrm.id); XCTAssertEqual(s.minion(wyrm.id)!.hp, 6, "a battlecry still hurts")
        s.turn = .e; s.attack(s.e.board[0].id, wyrm.id); XCTAssertEqual(s.minion(wyrm.id)!.hp, 6 - gd.card("ogre")!.atk!, "attacks hurt")
        // Malakar: +3 Attack / -1 Health to Undead only, never below 1; Spell Damage +2.
        s.p.board = []; s.e.board = []; s.turn = .p
        s.summon(.p, "goblin"); let gh = s.summon(.p, "ghoul")!
        if let i = s.p.board.firstIndex(where: { $0.uid == gh.uid }) { s.p.board[i].hp = 1 }
        let lich = s.summon(.p, "lich")!; s.applyFx(.p, gd.card("lich")!.bc!, nil)
        XCTAssertEqual(s.minion(gh.id)!.atk, gd.card("ghoul")!.atk! + 3); XCTAssertEqual(s.minion(gh.id)!.hp, 1, "not below 1")
        XCTAssertEqual(s.p.board[0].atk, gd.card("goblin")!.atk!, "the goblin is not Undead")
        XCTAssertEqual(s.minion(lich.id)!.atk, 9, "Malakar is Undead himself"); XCTAssertEqual(s.spellBonus(.p), 2)
        // Thorgrim: 7/10 Guard, +3/+3 and Ward to every friendly minion.
        s.p.board = []; s.summon(.p, "goblin"); let king = s.summon(.p, "dwarfking")!; s.applyFx(.p, gd.card("dwarfking")!.bc!, nil)
        XCTAssertEqual(s.minion(king.id)!.atk, 10); XCTAssertEqual(s.minion(king.id)!.hp, 13); XCTAssertTrue(s.p.board.allSatisfy(\.ward))
        XCTAssertEqual(s.p.board[0].atk, gd.card("goblin")!.atk! + 3)
        // Sylvara: three attacks a turn, no damage striking back, no draw.
        s.p.board = []; s.e.board = []; s.p.deck = ["goblin", "goblin"]; s.p.hand = []; s.p.hb = []
        let queen = s.summon(.p, "elfqueen")!; s.applyFx(.p, gd.card("elfqueen")!.bc!, nil)
        XCTAssertEqual(s.p.hand.count, 0, "no draw")
        s.summon(.e, "ogre"); s.summon(.e, "ogre"); s.summon(.e, "ogre")
        if let i = s.p.board.firstIndex(where: { $0.uid == queen.uid }) { s.p.board[i].sleep = false; s.p.board[i].ward = false }
        for n in 0..<3 {
            XCTAssertTrue(s.canAttack(s.minion(queen.id)!), "attack \(n + 1)")
            s.attack(queen.id, s.e.board[n].id)
        }
        XCTAssertFalse(s.canAttack(s.minion(queen.id)!), "three are spent")
        XCTAssertEqual(s.minion(queen.id)!.hp, gd.card("elfqueen")!.hp!, "the ogres never struck back")
        XCTAssertTrue(s.e.board.allSatisfy { $0.hp == gd.card("ogre")!.hp! - 5 })
        s.turn = .e; s.startTurn(.e); s.turn = .p; s.startTurn(.p)
        XCTAssertTrue(s.canAttack(s.minion(queen.id)!), "fresh each turn")
    }

    func testArcaneMissiles() {
        let gd = GameData.shared
        var s = blank()
        s.p.board = []; s.e.board = []; s.p.hand = ["missiles"]; s.p.hb = [0]; s.p.mana = 1; s.turn = .p; s.e.hp = 30
        XCTAssertEqual(gd.card("missiles")!.fx!.multi, 3)
        let og = s.summon(.e, "ogre")!
        s.pay(.p, "missiles"); s.takeHand(.p, 0)
        s.castSpell(.p, "missiles", og.id, extra: [og.id, .hero(.e)])
        XCTAssertEqual(s.minion(og.id)!.hp, gd.card("ogre")!.hp! - 2, "two missiles on the ogre"); XCTAssertEqual(s.e.hp, 29, "one in the face")
        let plan = s.aiMultiTargets(gd.card("missiles")!.fx!, bonus: 0)
        XCTAssertEqual(plan.count, 3)
    }

    func testShatterNeedsASmallFrozenTarget() {
        var s = blank()
        s.p.board = []; s.e.board = []; s.turn = .p
        let small = s.summon(.e, "goblin")!, big = s.summon(.e, "ogre")!
        for m in [small, big] { if let i = s.e.board.firstIndex(where: { $0.uid == m.uid }) { s.e.board[i].frozen = 1 } }
        let fx = GameData.shared.card("shatter")!.fx!
        XCTAssertEqual(s.targetsFor(.p, fx.tgt!, fx.cond), [small.id], "only the frozen minion under 5 Health")
    }

    func testTalentStatBoostsShowOnHandCards() {
        let gd = GameData.shared
        let o = gd.overrides(for: ["hu_pack", "wa_iron"])
        XCTAssertEqual(o["direwolf"]?.atkUp, 1); XCTAssertEqual(o["direwolf"]?.hpUp, 1)
        XCTAssertEqual(o["crab"]?.hpUp, 2, "a Guard minion under Iron Guard"); XCTAssertNil(o["goblin"])
        var s = blank(); s.setupTalents(.p, cls: "hunter", ["hu_pack"])
        XCTAssertEqual(s.p.ovr["direwolf"]?.atkUp, 1, "the hero's overrides carry the boost for the hand")
        let w = s.summon(.p, "direwolf")!
        XCTAssertEqual(w.atk, gd.card("direwolf")!.atk! + 1, "and the summoned minion gets the same boost")
    }

    func testOneLegendaryPerDeck() {
        XCTAssertTrue(Decks.fits(["goblin"], "lich"))
        XCTAssertFalse(Decks.fits(["lich"], "leviathan"), "a second, different Legendary does not fit")
        XCTAssertFalse(Decks.isValid(["lich", "leviathan"]))
        XCTAssertEqual(Decks.legendaries(Decks.sanitize(["lich", "leviathan", "goblin"], cls: "mage")), 1)
        var d: [String] = []; Decks.autoFill(&d, cls: "mage"); XCTAssertLessThanOrEqual(Decks.legendaries(d), 1)
        for _ in 0..<20 { XCTAssertTrue(Decks.rollRewards(stage: 5, cls: "mage", deck: ["lich"]).allSatisfy { GameData.shared.card($0)?.isLegendary == false }) }
    }

    func testShadowTouchLightFromDamage() {
        var s = blank()
        s.setupTalents(.p, cls: "priest", ["sh_pain", "sh_death", "sh_touch"]); s.p.light = 0; s.p.hp = 30; s.p.max = 30
        s.summon(.e, "ogre")
        var bolt = Effect(); bolt.dmg = 2; bolt.tgt = .any
        s.applyFx(.p, bolt, s.e.board[0].id, isSpell: true); XCTAssertEqual(s.p.light, 2, "damage to a minion")
        s.applyFx(.p, bolt, .hero(.e), isSpell: true); XCTAssertEqual(s.p.light, 4, "damage to the hero")
        var mend = Effect(); mend.heal = 5
        s.applyFx(.p, mend, nil); XCTAssertEqual(s.p.light, 4, "overhealing gives nothing now")
        s.turn = .e; s.attack(s.e.board[0].id, .hero(.p)); XCTAssertEqual(s.p.light, 4, "the foe's damage does not count")
        var t = blank(); t.setupTalents(.p, cls: "priest", []); t.p.light = 0
        t.applyFx(.p, mend, nil); XCTAssertEqual(t.p.light, 5, "without the talent, overhealing as before")
        t.summon(.e, "ogre"); t.applyFx(.p, bolt, t.e.board[0].id, isSpell: true); XCTAssertEqual(t.p.light, 5)
    }

    func testWhistleHoundHasNoCharge() {
        var s = blank(); s.setupTalents(.p, cls: "hunter", ["hu_pack", "hu_hound", "hu_whistle"]); s.turn = .p
        s.summon(.p, "boar")
        XCTAssertTrue(s.p.hand.contains("whistle"), "the first Beast of the turn brings the whistle")
        s.castSpell(.p, "whistle", nil)
        let h = s.p.board.last!
        XCTAssertEqual(h.key, "whound"); XCTAssertEqual(h.atk, 2, "Vicious Hounds still counts it")
        XCTAssertFalse(s.canAttack(h), "the whistle's Hound waits a turn")
        var u = Effect(); u.perFoe = "hound"; s.summon(.e, "ogre")
        s.applyFx(.p, u, nil)
        XCTAssertTrue(s.canAttack(s.p.board.last!), "Unleash the Hounds keeps Charge")
    }

    func testRapidFireTwiceAndArmorPiercing() {
        var s = blank(); s.setupTalents(.p, cls: "hunter", ["hu_precise", "hu_aim", "hu_rapid"]); s.turn = .p
        XCTAssertEqual(s.p.power.tgt, .enemy, "Rapid Fire aims at minions too")
        XCTAssertEqual(s.pcost(.p), 1, "each shot costs 1")
        s.p.powerUsed = true; s.afterPower(.p)
        XCTAssertFalse(s.p.powerUsed, "Rapid Fire: a second use this turn")
        XCTAssertEqual(s.pcost(.p), 1, "the second one too")
        s.p.powerUsed = true; s.afterPower(.p)
        XCTAssertTrue(s.p.powerUsed, "but not a third")

        var t = blank(); t.setupTalents(.p, cls: "hunter", ["hu_precise", "hu_aim", "hu_pierce"]); t.turn = .p
        XCTAssertEqual(t.p.power.tgt, .enemy, "Armor Piercing aims at minions too")
        XCTAssertEqual(t.pcost(.p), 1, "and costs 1 less")
        t.summon(.e, "ogre"); let i = t.e.board.count - 1; t.e.board[i].ward = true
        let m = t.e.board[i], hp = m.hp
        t.applyFx(.p, t.p.power.fx, m.id, bonus: 0, isPower: true)
        XCTAssertLessThan(t.minion(m.id)?.hp ?? 0, hp, "Ward does not stop it")
        t.e.armor = 5; let h0 = t.e.hp
        t.applyFx(.p, t.p.power.fx, .hero(.e), bonus: 0, isPower: true)
        XCTAssertEqual(t.e.armor, 5, "Armor is ignored"); XCTAssertLessThan(t.e.hp, h0)
    }

    func testHeartseekerShots() {
        var s = blank(); s.setupTalents(.p, cls: "hunter", ["hu_precise", "hu_heart", "hu_rapid"])
        XCTAssertEqual(s.cardFx(.p, "spray")?.dmg, 4, "Precision and Heartseeker stack on Arcane Shot")
        XCTAssertEqual(s.costOf(.p, "spray"), 0)
        XCTAssertEqual(s.cardFx(.p, "steady")?.dmg, 4); XCTAssertEqual(s.costOf(.p, "steady"), 1)
        XCTAssertEqual(s.cardFx(.p, "riptide")?.dmg, 7); XCTAssertEqual(s.costOf(.p, "riptide"), 4)
    }

    func testAshenWyrmResistsMagicButNotBlows() {
        var s = blank(); s.turn = .p
        s.summon(.e, "leviathan"); let d = s.e.board.last!.id
        s.castSpell(.p, "wordtorment", d)
        XCTAssertEqual(s.minion(d)?.hp, 10, "Word of Torment cannot destroy it")
        s.castSpell(.p, "frostbolt", d)
        XCTAssertEqual(s.minion(d)?.hp, 10, "nor can a Mage spell hurt it")
        s.castSpell(.p, "riptide", d)
        XCTAssertLessThan(s.minion(d)?.hp ?? 10, 10, "a Hunter shot is physical")
    }

    func testHoundmasterCanines() {
        var s = blank(); s.setupTalents(.p, cls: "hunter", ["hu_pack", "hu_hound", "hu_master"]); s.turn = .p
        XCTAssertEqual(s.p.power.fx.face, GameData.shared.cls("hunter")!.power.fx.face, "the hero power stays Piercing Arrow")
        s.summon(.p, "direwolf"); let w = s.p.board.last!
        let base = GameData.shared.card("direwolf")!
        XCTAssertEqual(w.atk, (base.atk ?? 0) + 2); XCTAssertEqual(w.hp, (base.hp ?? 0) + 2, "Pack Leader and Houndmaster stack on Dire Wolf")
        s.summon(.p, "elver"); let e = s.p.board.last!, eb = GameData.shared.card("elver")!
        XCTAssertEqual(e.atk, (eb.atk ?? 0) + 1); XCTAssertEqual(e.hp, (eb.hp ?? 0) + 1)
        s.summon(.p, "hound"); let h = s.p.board.last!, hb = GameData.shared.card("hound")!
        XCTAssertEqual(h.atk, (hb.atk ?? 0) + 2, "Vicious Hounds and Houndmaster"); XCTAssertEqual(h.hp, (hb.hp ?? 0) + 1)
    }
}
