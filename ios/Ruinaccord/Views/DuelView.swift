import SwiftUI

/// Sizes shared by the duel layout and the hand layer, all from the duel area's size (landscape only).
/// The layout follows Shadowverse: heroes top and bottom centre, boards between them, the hand at the bottom
/// right of your hero, mana / end turn / hero power in a column on the right, menu and battle log on the left.
struct HandMetrics: Equatable {
    let size: CGSize
    /// The screen continues this far below the duel area (home indicator); cards may hang into it.
    var bottomInset: CGFloat = 0
    var leftW: CGFloat { 54 }
    var rightW: CGFloat { 116 }
    /// Height of the strip holding the enemy hero, their hand backs and counts.
    var topH: CGFloat { 58 }
    /// Height of one board row (minion tile plus padding) and of the message line between the rows.
    var rowH: CGFloat { 80 }
    var lineH: CGFloat { 18 }
    /// Card size: whatever height is left under the boards, capped for big screens.
    var em: CGFloat {
        let free = size.height - 12 - topH - 2 * rowH - lineH - 16
        return min(11, max(6, (free - 24 + bottomInset) / (15.6 * 0.7)))
    }
    var cardW: CGFloat { 10 * em }
    var cardH: CGFloat { 15.6 * em }
    /// The hand hangs off the bottom edge (Shadowverse): only the top part of each card shows until it is lifted.
    var sink: CGFloat { cardH * 0.3 }
    /// The part of a hand card inside the duel area.
    var visible: CGFloat { cardH - sink - bottomInset }
    /// Height the board column leaves free at the bottom for your hero and the hand.
    var reserve: CGFloat { visible + 24 }
    /// Local y above which a dragged card counts as played.
    var line: CGFloat { size.height - reserve - 12 }
    /// Centre x of the heroes and of the hand (the middle of the board column).
    var heroX: CGFloat { leftW + (size.width - leftW - rightW) / 2 }
    /// Centre y of your hero's portrait: its lower half sits behind the hand.
    var heroY: CGFloat { size.height - visible - 10 }
    var heroSize: CGFloat { 52 }
    /// The hand may spread across the whole board column.
    var handMinX: CGFloat { leftW + 70 }
    var handMaxX: CGFloat { size.width - rightW - 4 }
    /// Centre y of a card in the hand.
    var baseY: CGFloat { size.height + bottomInset + sink - cardH / 2 }
    var cornerScale: CGFloat { 0.42 }
    /// Where the parked hand stacks and drawn cards come from: the deck, at the right end of the hand area.
    var corner: CGPoint { CGPoint(x: handMaxX - cardW * cornerScale / 2 - 2, y: size.height - cardH * cornerScale / 2 - 6) }
    /// A lifted card rises until it is fully visible.
    var lift: CGFloat { sink + 10 }
}

struct DuelView: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm

    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        return AnyView(HStack(spacing: 0) {
            LeftColumn(hm: hm).frame(width: hm.leftW)
            // Middle: enemy strip, the two boards, your hero.
            VStack(spacing: 4) {
                TopStrip(hm: hm).frame(height: hm.topH)
                BoardView(side: .e, minions: s.e.board, empty: tx.noEnemy)
                LogLine()
                BoardView(side: .p, minions: s.p.board, empty: tx.playMinions)
                Color.clear.frame(height: hm.reserve)
            }
            .overlay(alignment: .bottom) {
                HeroFace(side: .p, size: hm.heroSize).offset(y: hm.heroY - (hm.size.height - 6 - hm.heroSize / 2))
            }
            RightColumn(hm: hm).frame(width: hm.rightW)
        })
    }
}

/// One-line message between the boards: the target prompt, the lifted-card hint or the latest rule message.
private struct LogLine: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        let liftedPlayable: Bool = {
            guard let i = vm.hsel, vm.pending == nil, vm.handActive, !vm.busy, let k = s.p.hand[safe: i] else { return false }
            return s.canPay(.p, k)
        }()
        return AnyView(HStack(spacing: 10) {
            if vm.pending != nil {
                Text(tx.chooseTarget(vm.pendingLabel())).font(Theme.body(12.5)).foregroundStyle(Theme.muted)
                Button(tx.cancel) { vm.cancelPending() }.ghost(compact: true)
            } else if liftedPlayable {
                Text(tx.tapPlay).font(Theme.body(12.5)).foregroundStyle(Theme.muted)
            } else {
                Text(vm.logText()).font(Theme.body(12.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.85)
            }
        }
        .frame(minHeight: 18)
        .accessibilityElement(children: .combine))
    }
}

// MARK: - Top strip: enemy hand backs, enemy hero, enemy counts

private struct TopStrip: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        return AnyView(ZStack {
            HStack {
                EnemyHandBacks(n: s.e.hand.count)
                Spacer()
                CountPill(hand: s.e.hand.count, deck: s.e.deck.count)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            HeroCluster(side: .e)
        })
    }
}

/// The opponent's hand as a row of card backs.
private struct EnemyHandBacks: View {
    let n: Int
    var body: some View {
        HStack(spacing: -12) {
            ForEach(0..<n, id: \.self) { i in
                CardBack(width: 26).rotationEffect(.degrees(Double(i - n / 2) * 1.5))
            }
        }
        .padding(.top, 2)
        .animation(.spring(duration: 0.35), value: n)
        .accessibilityHidden(true)
    }
}

/// A face-down card.
struct CardBack: View {
    var width: CGFloat = 26
    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.14)
            .fill(LinearGradient(colors: [Color(hex: "#2c3a5a"), Color(hex: "#141b2c")], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: width * 0.14).stroke(Color(hex: "#7fa6d8"), lineWidth: 1.2))
            .overlay(Hexagon().stroke(Color(hex: "#7fa6d8").opacity(0.7), lineWidth: 1).padding(width * 0.22))
            .overlay(Circle().fill(Color(hex: "#9fc4ee").opacity(0.8)).frame(width: width * 0.16))
            .frame(width: width, height: width * 1.4)
            .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
    }
}

/// "Hand n · Deck m" in a small dark pill.
private struct CountPill: View {
    let hand: Int, deck: Int
    @Environment(GameVM.self) private var vm
    var body: some View {
        Text(vm.tx.handDeck(hand, deck)).font(Theme.body(11.5, .semibold)).foregroundStyle(Theme.muted).monospacedDigit().lineLimit(1)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Color.black.opacity(0.35), in: Capsule())
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }
}

/// Portrait with health shield and gems, name underneath (enemy) or above (you).
private struct HeroCluster: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        let name = Text(vm.heroName(side)).font(Theme.body(11, .bold)).foregroundStyle(Theme.parch).lineLimit(1)
            .padding(.horizontal, 8).padding(.vertical, 2).background(Color.black.opacity(0.45), in: Capsule())
        VStack(spacing: 3) {
            if side == .p { name }
            HeroFace(side: side, size: 56)
            if side == .e { name }
        }
    }
}

// MARK: - Left column: menu, battle log, your counts

private struct LeftColumn: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        return AnyView(VStack(spacing: 10) {
            if s.mode == .online {
                if !s.over {
                    SideButton(system: "flag.fill", text: vm.o.concedeArm ? tx.concedeSure : nil, danger: vm.o.concedeArm, label: tx.concede) { vm.concede() }
                }
            } else {
                SideButton(system: "line.3.horizontal", text: vm.quitArm ? tx.quitSure : nil, danger: vm.quitArm, label: tx.quitAria) { vm.quitDuel() }
            }
            Spacer()
            SideButton(system: "doc.text.fill", text: nil, danger: false, label: tx.battleLog) { vm.showLog = true }
                .overlay(alignment: .topTrailing) {
                    if let last = vm.hist.last, last.side == .e, last.round == s.round, s.turn == .p {
                        Circle().fill(Theme.blood).frame(width: 9, height: 9).offset(x: 2, y: -2)
                    }
                }
            Spacer()
            CountPill(hand: s.p.hand.count, deck: s.p.deck.count).fixedSize()
                .frame(width: hm.leftW + 60, alignment: .leading)
                .frame(width: hm.leftW, alignment: .leading)
        }
        .padding(.vertical, 2))
    }
}

/// Square icon button on the left edge; shows a short text instead while an action is armed.
private struct SideButton: View {
    let system: String
    let text: String?
    let danger: Bool
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if let text { Text(text).font(Theme.body(10, .heavy)).lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center) }
                else { Image(systemName: system).font(.system(size: 16, weight: .bold)) }
            }
            .foregroundStyle(danger ? Color(hex: "#f0a097") : Color(hex: "#9fc4ee"))
            .frame(width: 42, height: 38)
            .background(LinearGradient(colors: [Color(hex: "#1e2a44"), Color(hex: "#111726")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(danger ? Theme.blood : Color(hex: "#4a6a9a"), lineWidth: 1.2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

// MARK: - Right column: enemy mana, end turn, your mana, hero power, deck piles

private struct RightColumn: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        return AnyView(VStack(spacing: 8) {
            ManaBox(side: .e).padding(.top, 10)
            Spacer()
            EndTurnButton()
            Spacer()
            ManaBox(side: .p)
            PowerBar()
        }
        .padding(.horizontal, 4)
        .background(alignment: .topTrailing) { DeckPile(n: s.e.deck.count).offset(x: -4, y: -6) }
        .background(alignment: .bottomTrailing) { DeckPile(n: s.p.deck.count).offset(x: -4, y: 8) }
        .padding(.vertical, 2))
    }
}

/// A few card backs fanned out behind the column: the deck.
private struct DeckPile: View {
    let n: Int
    var body: some View {
        ZStack {
            ForEach(0..<min(3, max(n > 0 ? 1 : 0, (n + 9) / 10)), id: \.self) { i in
                CardBack(width: 40).rotationEffect(.degrees(Double(i) * 6 - 6)).offset(x: CGFloat(i) * 3, y: CGFloat(-i) * 2)
            }
        }
        .opacity(0.9)
        .accessibilityHidden(true)
    }
}

/// Mana as "x / max" with a row of ten crystals, plus banked spell mana as purple diamonds.
private struct ManaBox: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let h = s[side], tx = vm.tx, foe = side == .e
        return AnyView(VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(tx.manaShort).font(Theme.body(10, .bold)).foregroundStyle(Color(hex: "#9fc4ee")).textCase(.uppercase)
                Text("\(h.mana)").font(Theme.body(17, .heavy)).foregroundStyle(.white).monospacedDigit()
                Text("/\(h.maxMana)").font(Theme.body(10, .bold)).foregroundStyle(Color(hex: "#9fc4ee")).monospacedDigit()
            }
            HStack(spacing: 2.5) {
                ForEach(0..<10, id: \.self) { i in
                    Circle().fill(i < h.mana ? Color(hex: "#5ad0ff") : i < h.maxMana ? Color(hex: "#2a4a6a") : Color(hex: "#1a2230"))
                        .overlay(Circle().stroke(i < h.maxMana ? Color(hex: "#7fa6d8") : Color(hex: "#2e3a4e"), lineWidth: 0.8))
                        .frame(width: 7, height: 7)
                        .shadow(color: i < h.mana ? Color(hex: "#5ad0ff").opacity(0.8) : .clear, radius: 2)
                }
            }
            if h.spellMana > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<h.spellMana, id: \.self) { _ in
                        Rectangle().fill(Color(hex: "#a77be8")).overlay(Rectangle().stroke(Color(hex: "#d2b8ff"), lineWidth: 1))
                            .frame(width: 5, height: 5).rotationEffect(.degrees(45))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [Color(hex: foe ? "#2a1c22" : "#1c2a3a"), Color(hex: foe ? "#160c10" : "#0e1620")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(foe ? Color(hex: "#6d3a33") : Color(hex: "#4a6a9a"), lineWidth: 1.2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(tx.mana(h.mana, h.maxMana) + (h.spellMana > 0 ? ", " + tx.spellMana(h.spellMana) : ""))))
    }
}

/// The big round End Turn button; grey on the enemy's turn, glowing when nothing is left to do.
private struct EndTurnButton: View {
    @Environment(GameVM.self) private var vm
    @State private var glow = false
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let myTurn = s.turn == .p && !vm.busy && !s.over
        let nudge = myTurn && !vm.hasMoves()
        return AnyView(Button { vm.endTurn() } label: {
            Text(vm.tx.endTurn).font(Theme.display(15, cjk: vm.lang.isCJK)).foregroundStyle(.white)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                .frame(width: 74, height: 74)
                .background(RadialGradient(colors: [Color(hex: "#5ad0ff"), Color(hex: "#1f5fa0"), Color(hex: "#123560")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 40), in: Circle())
                .overlay(Circle().stroke(Color(hex: "#bfe0fa"), lineWidth: 2))
                .overlay(Circle().stroke(Color(hex: "#f3c97a").opacity(0.8), lineWidth: 1.5).padding(-4))
                .shadow(color: nudge && glow ? Color(hex: "#7fe0ff").opacity(0.95) : .black.opacity(0.5), radius: nudge && glow ? 14 : 3, y: nudge && glow ? 0 : 2)
        }
        .buttonStyle(.plain)
        .disabled(!myTurn)
        .saturation(myTurn ? 1 : 0.1).brightness(myTurn ? 0 : -0.3)
        .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever()) { glow = true } }
        .accessibilityLabel(Text(vm.tx.endTurn)))
    }
}

/// Your hero power as an orange bar: cost badge and name. Tap to use; a targeted power can be dragged onto its target.
private struct PowerBar: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let power = s.p.power, tx = vm.tx
        let enabled = !vm.powerBlocked
        let dragging = vm.drag?.src == .power
        return AnyView(HStack(spacing: 6) {
            Text("\(power.cost)").font(Theme.body(11, .heavy)).foregroundStyle(.white).frame(width: 20, height: 20).background(Theme.mana, in: Circle())
                .overlay(Circle().stroke(Color(hex: "#bfe0fa"), lineWidth: 1))
            Text(tx.powerName(power)).font(Theme.body(12, .heavy)).foregroundStyle(.white).lineLimit(2).minimumScaleFactor(0.7).multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6).padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(LinearGradient(colors: [Color(hex: "#f08a3a"), Color(hex: "#a8401a")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#f3c97a"), lineWidth: 1.2))
        .shadow(color: dragging ? Theme.gold.opacity(0.9) : .clear, radius: 8)
        .scaleEffect(dragging ? 1.06 : 1)
        .saturation(enabled ? 1 : 0.15).opacity(enabled ? 1 : 0.55)
        .reportFrame { vm.powerFrame = $0 }
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .pressDrag(onTap: { vm.usePower() }, onDrag: { vm.dragPower(to: $0) }, onDrop: { _ in vm.dropPower() })
        .animation(.spring(duration: 0.2), value: dragging)
        .accessibilityLabel(Text("\(tx.heroPower) \(tx.powerName(power)), \(power.cost): \(tx.powerDesc(power))"))
        .accessibilityAddTraits(.isButton))
    }
}

// MARK: - Boards

struct BoardView: View {
    let side: Side
    let minions: [Minion]
    let empty: String
    @Environment(GameVM.self) private var vm
    var body: some View {
        let glow = side == .p && vm.dropGlow
        HStack(spacing: 8) {
            if minions.isEmpty {
                Text(empty).font(Theme.body(12)).foregroundStyle(Theme.muted.opacity(0.6))
            }
            ForEach(minions) { m in
                MinionView(m: m)
                    .transition(.asymmetric(insertion: .scale(scale: 0.4).combined(with: .offset(y: -36)).combined(with: .opacity),
                                            removal: .scale(scale: 0.55).combined(with: .offset(y: 22)).combined(with: .opacity)))
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.35), value: minions.map(\.uid))
        .frame(maxWidth: .infinity, minHeight: 74, maxHeight: .infinity)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.ready.opacity(glow ? 0.12 : 0)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ready.opacity(glow ? 0.9 : 0), lineWidth: 2))
        .shadow(color: Theme.ready.opacity(glow ? 0.5 : 0), radius: glow ? 10 : 0)
        .animation(.easeOut(duration: 0.18), value: glow)
        .reportFrame { vm.boardFrames[side] = $0 }
    }
}

// MARK: - Battle log

/// Every play of the game, newest last, grouped by turn; tap an entry to see the card.
struct LogView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        // Turn headers: a new group whenever the round or the side changes.
        var rows: [LogRow] = []
        var lastKey: (Int, Side)? = nil
        for h in vm.hist {
            if lastKey == nil || lastKey! != (h.round, h.side) { rows.append(.turn(h.side, h.round)); lastKey = (h.round, h.side) }
            rows.append(.play(h))
        }
        return AnyView(ZStack {
            Color(hex: "#0a080c").opacity(0.7).ignoresSafeArea().contentShape(Rectangle()).onTapGesture { vm.showLog = false }
            VStack(spacing: 0) {
                HStack {
                    Text(tx.battleLog).font(Theme.display(20, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                    Spacer()
                    Button { vm.showLog = false } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.parch).frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain).accessibilityLabel(Text(tx.back))
                }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 6)
                Rectangle().fill(Theme.gold.opacity(0.5)).frame(height: 1).padding(.horizontal, 12)
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 6) {
                            if rows.isEmpty {
                                Text(tx.logEmpty).font(Theme.body(13)).foregroundStyle(Theme.muted).padding(.top, 30)
                            }
                            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                                switch row {
                                case .turn(let side, let n):
                                    Text(tx.turnRound(side == .p, n + 1)).font(Theme.display(15, cjk: vm.lang.isCJK)).tracking(1)
                                        .foregroundStyle(side == .p ? Color(hex: "#9fc4ee") : Color(hex: "#f0a097"))
                                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                                        .overlay(alignment: .bottom) { Rectangle().fill(Theme.gold.opacity(0.35)).frame(height: 1) }
                                case .play(let h):
                                    LogPlayRow(h: h).id(i)
                                }
                            }
                            Color.clear.frame(height: 1).id("end")
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                    }
                    .onAppear { proxy.scrollTo("end", anchor: .bottom) }
                }
            }
            .frame(maxWidth: 520, maxHeight: .infinity)
            .background(LinearGradient(colors: [Color(hex: "#1c2434"), Color(hex: "#0f1420")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#4a6a9a"), lineWidth: 1.5))
            .padding(.vertical, 14)
            .shadow(color: .black.opacity(0.7), radius: 16)
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
        .zIndex(40)
        .accessibilityAddTraits(.isModal)
        .onChange(of: s.round) { _, _ in vm.showLog = false })
    }
    private enum LogRow { case turn(Side, Int), play(HistItem) }
}

/// One play in the battle log: coloured stripe, card picture, "<hero> played <card>", target.
private struct LogPlayRow: View {
    let h: HistItem
    @Environment(GameVM.self) private var vm
    var body: some View {
        let foe = h.side == .e, tx = vm.tx
        Button { vm.peekItem = h } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(foe ? Theme.blood : Color(hex: "#5ad0ff")).frame(width: 4)
                ZStack {
                    RadialGradient(colors: foe ? [Color(hex: "#4a2a2a"), Color(hex: "#1a0c0c")] : [Color(hex: "#3a3046"), Color(hex: "#17121c")], center: .center, startRadius: 0, endRadius: 24)
                    ArtThumb(key: h.key, width: 44, height: 32)
                }
                .frame(width: 44, height: 32).clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.played(vm.heroName(h.side)) + " · " + tx.cardName(h.key)).font(Theme.body(13, .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
                    if let t = h.target { Text(tx.target(vm.name(t))).font(Theme.body(11.5)).foregroundStyle(Theme.muted).lineLimit(1) }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4).padding(.horizontal, 6)
            .background(LinearGradient(colors: [foe ? Color(hex: "#3a1c1c") : Color(hex: "#1c2e44"), Color.clear], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(foe ? Color(hex: "#6d3a33") : Color(hex: "#3a5a8a"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Shadowverse-style card description, top left: cost, name, type, stats and rules text of the lifted hand card
/// or the held board minion.
struct CardInfoPanel: View {
    let card: Card
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, cjk = vm.lang.isCJK
        let typ = [card.isMinion ? tx.race(card.race ?? "") : nil, card.cls.map(tx.className)].compactMap { $0 }.joined(separator: " · ")
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text("\(card.cost)").font(Theme.body(14, .heavy)).foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(RadialGradient(colors: [Color(hex: "#7cb8ee"), Theme.mana], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 18), in: Hexagon())
                    .overlay(Hexagon().stroke(Color(hex: "#bfe0fa"), lineWidth: 1))
                Text(tx.name(card.names)).font(Theme.display(16, cjk: cjk)).foregroundStyle(Theme.parch).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if card.isMinion {
                    StatBubble(value: card.atk ?? 0, attack: true, em: 8)
                    StatBubble(value: card.hp ?? 0, attack: false, em: 8)
                }
            }
            if !typ.isEmpty {
                Text(typ).font(Theme.body(10.5, .semibold)).tracking(0.5).foregroundStyle(Color(hex: "#9fc4ee")).textCase(.uppercase)
                    .padding(.horizontal, 6).padding(.vertical, 1).overlay(Capsule().stroke(Color(hex: "#4a6a9a"), lineWidth: 1))
            }
            RichText(text: tx.cardText(card), keywords: tx.keywords, font: Theme.body(12.5), color: Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(tx.name(card.flavor)).font(Theme.body(11)).italic().foregroundStyle(Theme.muted).lineLimit(2)
        }
        .padding(10)
        .frame(width: min(270, hm.size.width * 0.34), alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: "#1c2a44"), Color(hex: "#0d1320")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.gold.opacity(0.8), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.7), radius: 10, y: 4)
        .allowsHitTesting(false)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
}

/// Opening hand: tap cards to replace them, then confirm (online: wait for the opponent).
struct MulliganView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx, hand = s.p.hand, n = max(1, hand.count)
        return AnyView(GeometryReader { g in
            let em = max(6, min(10.8, (g.size.height - 170) / 15.6, (g.size.width - 40 - CGFloat(n - 1) * 18) / (CGFloat(n) * 10)))
            VStack(spacing: 10) {
                Text(tx.mullTitle).font(Theme.display(22, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                Text(tx.mullSub).font(Theme.body(12.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 440)
                HStack(spacing: 18) {
                    ForEach(Array(hand.enumerated()), id: \.offset) { i, k in
                        if let c = GameData.shared.card(k) {
                            let x = vm.mullPicks.contains(i)
                            CardView(card: c, size: .fit(em))
                                .saturation(x ? 0.15 : 1).brightness(x ? -0.35 : 0)
                                .offset(y: x ? 6 : 0)
                                .overlay { if x { Text("✕").font(.system(size: 44, weight: .heavy)).foregroundStyle(Theme.blood).shadow(radius: 4) } }
                                .contentShape(Rectangle())
                                .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { vm.toggleMulligan(i) } }
                                .accessibilityAddTraits(x ? .isSelected : [])
                        }
                    }
                }
                .padding(.top, 6)
                if vm.mullMine != nil {
                    Text(tx.mullWait).font(Theme.body(13)).foregroundStyle(Theme.muted)
                } else {
                    Button(vm.mullPicks.isEmpty ? tx.mullKeep : tx.mullSwap(vm.mullPicks.count)) { vm.confirmMulligan() }.primary()
                }
            }
            .padding(16)
            .frame(width: g.size.width, height: g.size.height)
            .background(Color(hex: "#0a070e").opacity(0.86))
        }
        .ignoresSafeArea())
    }
}
