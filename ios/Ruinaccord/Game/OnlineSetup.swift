import Foundation

extension DuelState {
    /// Fresh online game from the host's point of view (p = host, e = guest). Both clients load it from the match document.
    static func onlineStart(hostCls: String, hostDeck: [String], guestCls: String, guestDeck: [String]) -> DuelState {
        let gd = GameData.shared
        let hp = gd.cls(hostCls)?.power ?? gd.fortify, gp = gd.cls(guestCls)?.power ?? gd.fortify
        var s = DuelState(mode: .online, pcls: hostCls, ecls: guestCls,
                          p: makeHero(.p, hp: 30, deck: hostDeck.shuffled(), power: hp),
                          e: makeHero(.e, hp: 30, deck: guestDeck.shuffled(), power: gp))
        let first: Side = Bool.random() ? .p : .e
        s.turn = first
        s.draw(first, 3); s.draw(first.other, 4)
        s[first.other].hand.append("coin")
        s.startTurn(first)
        s.events = []
        return s
    }

    /// The same game seen from the other seat: p and e swap, every side flips.
    func flipped() -> DuelState {
        var s = self
        func flipHero(_ h: Hero) -> Hero {
            var x = h
            x.side = h.side.other
            x.board = h.board.map { var m = $0; m.side = $0.side.other; return m }
            return x
        }
        s.p = flipHero(e); s.e = flipHero(p)
        s.turn = turn.other
        s.order = order.map(\.other)
        s.pcls = ecls ?? pcls; s.ecls = pcls
        if let r = result { s.result = r == .win ? .lose : r == .lose ? .win : .draw }
        s.events = []
        return s
    }
}
