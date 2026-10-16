import SwiftUI

/// Landscape duel: a slim status rail on the left, the board in the middle, the card preview and the hand on the right.
/// Mirrors the web game's landscape layout.
struct DuelLandView: View {
    @Environment(GameVM.self) private var vm

    var body: some View {
        GeometryReader { g in
            let railW: CGFloat = 64, gap: CGFloat = 10
            let rest = g.size.width - railW - gap * 2
            let boardW = max(340, rest / 2.15)
            HStack(spacing: gap) {
                LandRail().frame(width: railW)
                LandBoard().frame(width: boardW)
                LandSide(screenHeight: g.size.height).frame(width: max(200, rest - boardW))
            }
            .environment(\.duelLandscape, true)
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

/// Hero power as a small icon button with its cost on top.
private struct MiniPower: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    @State private var pulse = false
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let power = s[side].power, foe = side == .e, tx = vm.tx
        let enabled = !foe && !vm.powerBlocked
        return AnyView(Button { if !foe { vm.usePower() } } label: {
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: "#4a3a2a"), Color(hex: "#1e160f")], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 20))
                Image(systemName: "sparkle").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.gold)
            }
            .frame(width: 32, height: 32)
            .overlay(Circle().stroke(foe ? Color(hex: "#6d3a33") : Theme.gold, lineWidth: 2))
            .overlay(alignment: .top) {
                Text("\(power.cost)").font(Theme.body(10, .heavy)).foregroundStyle(.white).frame(width: 16, height: 16).background(Theme.mana, in: Circle()).offset(y: -7)
            }
            .shadow(color: enabled && pulse ? Theme.gold.opacity(0.6) : .clear, radius: 8)
            .opacity(foe ? 0.75 : enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(foe)
        .reportFrame { if foe { vm.epowFrame = $0 } else { vm.powerFrame = $0 } }
        .onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { pulse = true } }
        .accessibilityLabel(Text("\(tx.heroPower) \(tx.powerName(power)), \(power.cost): \(tx.powerDesc(power))")))
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

// MARK: - Board

private struct LandBoard: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        return AnyView(VStack(spacing: 4) {
            BoardView(side: .e, minions: s.e.board, empty: tx.noEnemy)
            HStack(spacing: 10) {
                if vm.pending != nil {
                    Text(tx.chooseTarget(vm.pendingLabel())).font(Theme.body(12.5)).foregroundStyle(Theme.muted)
                    Button(tx.cancel) { vm.cancelPending() }.ghost(compact: true)
                } else {
                    Text(vm.logText()).font(Theme.body(12.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                        .lineLimit(2).minimumScaleFactor(0.85)
                }
            }
            .frame(minHeight: 22)
            .accessibilityElement(children: .combine)
            BoardView(side: .p, minions: s.p.board, empty: tx.playMinions)
        })
    }
}

// MARK: - Preview and hand

private struct LandSide: View {
    let screenHeight: CGFloat
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        let sel: Int? = vm.hsel.flatMap { $0 < s.p.hand.count ? $0 : nil }
        let pendIdx: Int? = { if let p = vm.pending, case .spell(let idx) = p.kind { return idx }; return nil }()
        let shown = (pendIdx ?? sel).flatMap { s.p.hand[safe: $0] }.flatMap { GameData.shared.card($0) }
        return AnyView(VStack(spacing: 4) {
            GeometryReader { g in
                VStack(spacing: 6) {
                    if let c = shown {
                        let em = min(14, max(6, (g.size.height - 24) / 15.6))
                        CardView(card: c, size: .fit(em))
                        if pendIdx == nil && s.turn == .p && s.canPay(.p, c.id) {
                            Text(tx.tapPlay).font(Theme.body(12)).foregroundStyle(Theme.muted)
                        }
                    } else {
                        VStack(spacing: 3) {
                            Text("\(vm.heroName(.e)) · \(tx.handDeck(s.e.hand.count, s.e.deck.count))")
                            Text("\(vm.heroName(.p)) · \(tx.handDeck(s.p.hand.count, s.p.deck.count))")
                            Text(s.turn == .p ? tx.yourTurn : tx.acting(vm.heroName(.e)))
                            Text(tx.tapPreview)
                        }
                        .font(Theme.body(12)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                    }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
            .overlay(alignment: .topTrailing) {
                if s.mode == .online {
                    if !s.over { Button(vm.o.concedeArm ? tx.concedeSure : "⚑") { vm.concede() }.ghost(compact: true, danger: vm.o.concedeArm) }
                } else {
                    Button(vm.quitArm ? tx.quitSure : "⌂") { vm.quitDuel() }.ghost(compact: true, danger: vm.quitArm)
                        .accessibilityLabel(Text(tx.quitAria))
                }
            }
            LandHand(em: min(12.5, max(6, screenHeight * 0.0225)))
        })
    }
}

/// The whole hand in one row, overlapping only as much as needed to fit.
private struct LandHand: View {
    let em: CGFloat
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let n = s.p.hand.count, cardW = 10 * em
        let newFrom = n - vm.drewCount
        return AnyView(GeometryReader { g in
            let avail = g.size.width - 8
            let spacing = n > 1 ? min(7, (avail - CGFloat(n) * cardW) / CGFloat(n - 1)) : 0
            HStack(spacing: spacing) {
                ForEach(Array(s.p.hand.enumerated()), id: \.offset) { i, k in
                    if let c = GameData.shared.card(k) {
                        let ok = s.turn == .p && !vm.busy && !s.over && s.canPay(.p, k) && vm.pending == nil
                        let pend: Bool = { if let p = vm.pending, case .spell(let idx) = p.kind { return idx == i }; return false }()
                        HandCard(card: c, index: i, ok: ok, off: !s.canPay(.p, k), pend: pend, fresh: i >= newFrom,
                                 delay: Double(max(0, i - newFrom)) * 0.11, size: .fit(em), previewFirst: true)
                            .zIndex(vm.hsel == i || pend ? 10 : Double(i))
                    }
                }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
        .frame(height: 15.6 * em + 14)
        .onChange(of: s.p.hand.count) { _, _ in Task { await vm.wait(600); vm.drewCount = 0 } })
    }
}
