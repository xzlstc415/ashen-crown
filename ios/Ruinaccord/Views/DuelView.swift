import SwiftUI

/// Sizes shared by the duel layout and the hand layer, all from the duel area's size (landscape only).
struct HandMetrics: Equatable {
    let size: CGSize
    var em: CGFloat { min(12.5, max(6, size.height * 0.0235)) }
    var cardW: CGFloat { 10 * em }
    var cardH: CGFloat { 15.6 * em }
    /// How far the fanned cards hang below the bottom edge.
    var sink: CGFloat { cardH * 0.08 }
    /// Height the board column leaves free at the bottom for the fanned hand.
    var reserve: CGFloat { cardH - sink + 6 }
    /// Local y above which a dragged card counts as played.
    var line: CGFloat { size.height - reserve - 14 }
    var railW: CGFloat { 64 }
    var gap: CGFloat { 10 }
    /// Centre of the fan: the middle of the board column.
    var fanCenterX: CGFloat { railW + gap + (size.width - railW - gap) / 2 }
    var fanWidth: CGFloat { min((size.width - railW - gap) * 0.78, 7.5 * cardW) }
    /// Centre y of a card in the fan.
    var baseY: CGFloat { size.height - cardH / 2 + sink }
    var cornerScale: CGFloat { 0.42 }
    /// Centre of the parked hand (bottom-right corner).
    var corner: CGPoint { CGPoint(x: size.width - cardW * cornerScale / 2 - 10, y: size.height - cardH * cornerScale / 2 - 6) }
    /// Scale of a lifted card: as big as fits above the play line.
    var liftScale: CGFloat { min(1.7, (line - 10) / cardH) }
}

/// The duel: a slim status rail on the left and the two boards in the middle. The hand is drawn by HandLayer
/// on top of this view, fanned along the bottom during your turn and parked in the corner otherwise.
struct DuelView: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm

    var body: some View {
        HStack(spacing: hm.gap) {
            LandRail().frame(width: hm.railW)
            LandBoard(hm: hm)
        }
    }
}

// MARK: - Left rail

private struct LandRail: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        VStack(spacing: 6) {
            RailHero(side: .e)
            RailHist()
            RailHero(side: .p)
            EndTurnButton()
        }
    }
}

private struct RailHero: View {
    let side: Side
    var body: some View {
        let row = HStack(spacing: 5) { ManaGem(side: side); MiniPower(side: side) }
        VStack(spacing: 6) {
            if side == .e { HeroFace(side: side, size: 46); row } else { row; HeroFace(side: side, size: 46) }
        }
    }
}

/// Mana as one hexagon gem (current / max), with banked spell mana as small diamonds under it.
private struct ManaGem: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let h = s[side], on = h.mana > 0
        return AnyView(VStack(spacing: 2) {
            ZStack {
                Hexagon().fill(LinearGradient(colors: on ? [Color(hex: "#7cb8ee"), Theme.mana] : [Color(hex: "#3d3150"), Color(hex: "#2a2234")],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(spacing: -2) {
                    Text("\(h.mana)").font(Theme.body(13, .heavy)).foregroundStyle(on ? .white : Color(hex: "#8c7fa0")).monospacedDigit()
                    Text("/\(h.maxMana)").font(Theme.body(8, .bold)).foregroundStyle(on ? .white.opacity(0.85) : Color(hex: "#8c7fa0")).monospacedDigit()
                }
            }
            .frame(width: 30, height: 34)
            HStack(spacing: 2) {
                ForEach(0..<h.spellMana, id: \.self) { _ in
                    Rectangle().fill(Color(hex: "#a77be8")).overlay(Rectangle().stroke(Color(hex: "#d2b8ff"), lineWidth: 1))
                        .frame(width: 5, height: 5).rotationEffect(.degrees(45))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(vm.tx.mana(h.mana, h.maxMana) + (h.spellMana > 0 ? ", " + vm.tx.spellMana(h.spellMana) : ""))))
    }
}

/// Hero power as a small icon button with its cost on top. Tap to use; a targeted power can also be dragged onto its target.
private struct MiniPower: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    @State private var pulse = false
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let power = s[side].power, foe = side == .e, tx = vm.tx
        let enabled = !foe && !vm.powerBlocked
        let dragging = vm.drag?.src == .power
        return AnyView(ZStack {
            Circle().fill(RadialGradient(colors: [Color(hex: "#4a3a2a"), Color(hex: "#1e160f")], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 20))
            Image(systemName: "sparkle").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.gold)
        }
        .frame(width: 32, height: 32)
        .overlay(Circle().stroke(foe ? Color(hex: "#6d3a33") : Theme.gold, lineWidth: 2))
        .overlay(alignment: .top) {
            Text("\(power.cost)").font(Theme.body(10, .heavy)).foregroundStyle(.white).frame(width: 16, height: 16).background(Theme.mana, in: Circle()).offset(y: -7)
        }
        .shadow(color: enabled && (pulse || dragging) ? Theme.gold.opacity(dragging ? 0.9 : 0.6) : .clear, radius: 8)
        .scaleEffect(dragging ? 1.15 : 1)
        .opacity(foe ? 0.75 : enabled ? 1 : 0.4)
        .reportFrame { if foe { vm.epowFrame = $0 } else { vm.powerFrame = $0 } }
        .contentShape(Circle())
        .pressDrag(enabled: !foe, onTap: { vm.usePower() }, onDrag: { vm.dragPower(to: $0) }, onDrop: { _ in vm.dropPower() })
        .animation(.spring(duration: 0.2), value: dragging)
        .onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { pulse = true } }
        .accessibilityLabel(Text("\(tx.heroPower) \(tx.powerName(power)), \(power.cost): \(tx.powerDesc(power))"))
        .accessibilityAddTraits(.isButton))
    }
}

/// The newest plays (up to four) that fit completely, top to bottom.
private struct RailHist: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        GeometryReader { g in
            let fit = max(0, min(4, Int((g.size.height + 4) / 32)))
            VStack(spacing: 4) {
                ForEach(vm.hist.suffix(fit)) { h in HistChip(h: h, size: 28) }
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .frame(maxHeight: .infinity)
    }
}

private struct EndTurnButton: View {
    @Environment(GameVM.self) private var vm
    @State private var glow = false
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let myTurn = s.turn == .p && !vm.busy && !s.over
        let nudge = myTurn && !vm.hasMoves()
        return AnyView(Button { vm.endTurn() } label: {
            Image(systemName: "arrow.clockwise").font(.system(size: 17, weight: .heavy)).foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(RadialGradient(colors: [Color(hex: "#f0a060"), Color(hex: "#a8401a")], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 26), in: Circle())
                .overlay(Circle().stroke(Color(hex: "#f3c97a"), lineWidth: 2))
                .shadow(color: nudge && glow ? Color(hex: "#f3a060").opacity(0.9) : .black.opacity(0.5), radius: nudge && glow ? 10 : 2, y: nudge && glow ? 0 : 2)
        }
        .buttonStyle(.plain)
        .disabled(!myTurn)
        .saturation(myTurn ? 1 : 0.15).brightness(myTurn ? 0 : -0.25)
        .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever()) { glow = true } }
        .accessibilityLabel(Text(vm.tx.endTurn)))
    }
}

// MARK: - Boards

private struct LandBoard: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        let liftedPlayable: Bool = {
            guard let i = vm.hsel, vm.pending == nil, vm.handActive, !vm.busy, let k = s.p.hand[safe: i] else { return false }
            return s.canPay(.p, k)
        }()
        return AnyView(VStack(spacing: 4) {
            BoardView(side: .e, minions: s.e.board, empty: tx.noEnemy)
            HStack(spacing: 10) {
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
            .frame(minHeight: 22)
            .accessibilityElement(children: .combine)
            BoardView(side: .p, minions: s.p.board, empty: tx.playMinions)
            Color.clear.frame(height: hm.reserve)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                Text("\(vm.heroName(.e)) · \(tx.handDeck(s.e.hand.count, s.e.deck.count))").font(Theme.body(11.5)).foregroundStyle(Theme.muted).lineLimit(1)
                if s.mode == .online {
                    if !s.over { Button(vm.o.concedeArm ? tx.concedeSure : "⚑") { vm.concede() }.ghost(compact: true, danger: vm.o.concedeArm) }
                } else {
                    Button(vm.quitArm ? tx.quitSure : "⌂") { vm.quitDuel() }.ghost(compact: true, danger: vm.quitArm)
                        .accessibilityLabel(Text(tx.quitAria))
                }
            }
        })
    }
}

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
        .frame(maxWidth: .infinity, minHeight: 98, maxHeight: .infinity)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.ready.opacity(glow ? 0.12 : 0)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ready.opacity(glow ? 0.9 : 0), lineWidth: 2))
        .shadow(color: Theme.ready.opacity(glow ? 0.5 : 0), radius: glow ? 10 : 0)
        .animation(.easeOut(duration: 0.18), value: glow)
        .reportFrame { vm.boardFrames[side] = $0 }
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
