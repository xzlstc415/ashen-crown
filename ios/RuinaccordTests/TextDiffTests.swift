import XCTest
@testable import Ruinaccord

/// Numbers the talents change in card text are marked (Hearthstone-style highlighting).
final class TextDiffTests: XCTestCase {
    func testChangedNumbers() {
        XCTAssertEqual(RichText.changedNumbers("Deal 3 damage to a minion.", from: "Deal 2 damage to a minion."), [0])
        XCTAssertEqual(RichText.changedNumbers("造成3点伤害，抽1张牌。", from: "造成2点伤害，抽1张牌。"), [0])
        XCTAssertEqual(RichText.changedNumbers("Restore 10 Health.", from: "Restore 8 Health."), [0])
        XCTAssertEqual(RichText.changedNumbers("Same 4 text.", from: "Same 4 text."), [])
        // A different sentence: nothing is marked.
        XCTAssertEqual(RichText.changedNumbers("Deal 3 damage. Draw a card.", from: "Deal 2 damage."), [])
    }

    func testTalentTextOnRealCards() {
        let gd = GameData.shared, tx = Tx(lang: .en)
        let ovr = gd.overrides(for: ["ho_smite"])
        let smite = gd.card("holysmite")!
        let now = tx.cardText(smite, ovr: ovr["holysmite"]), base = tx.cardText(smite)
        XCTAssertNotEqual(now, base)
        XCTAssertEqual(RichText.changedNumbers(now, from: base).count, 1, "\(base) → \(now)")
        // Choir: Hymn of Return revives two, and the text says so.
        let zh = Tx(lang: .zh), req = gd.card("requiem")!, rov = gd.overrides(for: ["ho_hymn"])["requiem"]
        XCTAssertTrue(zh.cardText(req, ovr: rov).contains("2个随从"), zh.cardText(req, ovr: rov))
        XCTAssertEqual(RichText.changedNumbers(zh.cardText(req, ovr: rov), from: zh.cardText(req)).count, 1)
    }
}
