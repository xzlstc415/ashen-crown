import SwiftUI

/// The one-screen duel: enemy hero, enemy board, recent plays, log, your board, your hero, hand, end-turn bar.
struct DuelView: View {
    @Environment(GameVM.self) private var vm

    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        let myTurn = s.turn == .p && !vm.busy && !s.over
        return AnyView(VStack(spacing: 6) {
            HeroView(side: .e)
            BoardView(side: .e, minions: s.e.board, empty: tx.noEnemy)
            HistStrip()
            // Log / target prompt
            HStack(spacing: 10) {
                if vm.pending != nil {
                    Text(tx.chooseTarget(vm.pendingLabel())).font(Theme.body(13)).foregroundStyle(Theme.muted)
                    Button(tx.cancel) { vm.cancelPending() }.ghost(compact: true)
                } else {
                    Text(vm.logText()).font(Theme.body(13)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                        .lineLimit(2).minimumScaleFactor(0.85)
                }
            }
            .frame(minHeight: 28)
            .accessibilityElement(children: .combine)
            BoardView(side: .p, minions: s.p.board, empty: tx.playMinions)
            HeroView(side: .p)
            HandView()
            HStack(spacing: 10) {
                Text(s.turn == .p ? tx.yourTurn : tx.acting(vm.heroName(.e))).font(Theme.body(12)).foregroundStyle(Theme.muted)
                Spacer()
                if s.mode == .online && !s.over {
                    Button(vm.o.concedeArm ? tx.concedeSure : "⚑ " + tx.concede) { vm.concede() }.ghost(compact: true, danger: vm.o.concedeArm)
                }
                Button(tx.endTurn) { vm.endTurn() }
                    .primary(glow: myTurn && !vm.hasMoves())
                    .disabled(!myTurn)
                    .opacity(myTurn ? 1 : 0.45)
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
        .reportFrame { vm.boardFrames[side] = $0 }
    }
}

struct HandView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let newFrom = s.p.hand.count - vm.drewCount
        return AnyView(ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(Array(s.p.hand.enumerated()), id: \.offset) { i, k in
                    if let c = GameData.shared.card(k) {
                        let ok = s.turn == .p && !vm.busy && !s.over && c.cost <= s.p.mana && vm.pending == nil
                        let off = c.cost > s.p.mana
                        let pend: Bool = { if let p = vm.pending, case .spell(let idx) = p.kind { return idx == i }; return false }()
                        HandCard(card: c, index: i, ok: ok, off: off, pend: pend, fresh: i >= newFrom, delay: Double(max(0, i - newFrom)) * 0.11)
                    }
                }
            }
            .padding(.horizontal, 6).padding(.top, 12).padding(.bottom, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, -6)
        .onChange(of: s.p.hand.count) { _, _ in Task { await vm.wait(600); vm.drewCount = 0 } })
    }
}

private struct HandCard: View {
    let card: Card
    let index: Int
    let ok: Bool, off: Bool, pend: Bool, fresh: Bool
    let delay: Double
    @Environment(GameVM.self) private var vm
    @State private var shown = false
    var body: some View {
        CardView(card: card, size: .sm)
            .overlay(RoundedRectangle(cornerRadius: 8.5).stroke(pend ? Theme.ember : ok ? Theme.ready : .clear, lineWidth: 2))
            .shadow(color: pend ? Theme.ember.opacity(0.6) : ok ? Theme.ready.opacity(0.5) : .clear, radius: ok || pend ? 8 : 0)
            .saturation(off ? 0.5 : 1).brightness(off ? -0.15 : 0)
            .offset(y: pend ? -10 : 0)
            .opacity(vm.hiddenHand == index ? 0 : 1)
            .offset(x: shown ? 0 : 80).rotationEffect(.degrees(shown ? 0 : 10)).opacity(shown ? 1 : 0)
            .onAppear {
                if fresh && !vm.reduceMotion { withAnimation(.spring(duration: 0.45, bounce: 0.3).delay(delay)) { shown = true } } else { shown = true }
            }
            .reportFrame { vm.handFrames[index] = $0 }
            .contentShape(Rectangle())
            .onTapGesture { vm.playHand(index) }
            .onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = card.id }
            .accessibilityLabel(Text("\(vm.tx.name(card.names)), \(card.cost)"))
    }
}

/// Small chips of the last plays; tap one to see the card.
struct HistStrip: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        return AnyView(HStack(spacing: 4) {
            if !vm.hist.isEmpty {
                Text(vm.tx.history).font(Theme.body(11)).foregroundStyle(Theme.muted).padding(.trailing, 4)
                ForEach(vm.hist) { h in
                    let foe = h.side == .e
                    let fresh = foe && h.round == s.round && s.turn == .p
                    Button { vm.peekItem = h } label: {
                        ZStack {
                            RadialGradient(colors: foe ? [Color(hex: "#4a2a2a"), Color(hex: "#1a0c0c")] : [Color(hex: "#3a3046"), Color(hex: "#17121c")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 20)
                            Image("art_\(h.key)").resizable().scaledToFit().scaleEffect(1.5)
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(foe ? Color(hex: "#a0483f") : Theme.kelp, lineWidth: 2))
                        .shadow(color: fresh ? Theme.blood.opacity(0.75) : .clear, radius: fresh ? 6 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 30))
    }
}

/// Overlay layers that float above the duel: projectiles, bursts, sparks, waves, flying cards.
struct FXLayer: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(vm.fx) { item in
                switch item {
                case .orb(_, let from, let to, let color): OrbView(from: from, to: to, color: color)
                case .burst(_, let at, let color): BurstView(at: at, color: color)
                case .spark(_, let at, let dx, let dy, let size): SparkView(at: at, dx: dx, dy: dy, size: size)
                case .wave(_, let rect): WaveView(rect: rect)
                case .fly(_, let key, let from, let to): FlyView(key: key, from: from, to: to)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct OrbView: View {
    let from: CGPoint, to: CGPoint, color: Color
    @State private var p: CGFloat = 0
    var body: some View {
        let x = from.x + (to.x - from.x) * p
        let y = from.y + (to.y - from.y) * p - 30 * sin(p * .pi)
        Circle().fill(RadialGradient(colors: [.white, color, color.opacity(0)], center: .center, startRadius: 1, endRadius: 10))
            .frame(width: 18, height: 18).shadow(color: color, radius: 8)
            .scaleEffect(0.5 + p)
            .position(x: x, y: y)
            .onAppear { withAnimation(.easeIn(duration: 0.42)) { p = 1 } }
    }
}
private struct BurstView: View {
    let at: CGPoint, color: Color
    @State private var on = false
    var body: some View {
        Circle().stroke(color, lineWidth: 3).frame(width: 46, height: 46)
            .scaleEffect(on ? 1.7 : 0.2).opacity(on ? 0 : 1)
            .position(at)
            .onAppear { withAnimation(.easeOut(duration: 0.42)) { on = true } }
    }
}
private struct SparkView: View {
    let at: CGPoint, dx: CGFloat, dy: CGFloat, size: CGFloat
    @State private var on = false
    var body: some View {
        Circle().fill(Theme.ember2).frame(width: size, height: size).shadow(color: Theme.ember2, radius: 3)
            .position(at).offset(x: on ? dx : 0, y: on ? dy : 0).opacity(on ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.7 + .random(in: 0...0.4))) { on = true } }
    }
}
private struct WaveView: View {
    let rect: CGRect
    @State private var on = false
    var body: some View {
        LinearGradient(colors: [.clear, Theme.ember2.opacity(0.65), .clear], startPoint: .leading, endPoint: .trailing)
            .frame(width: rect.width * 0.45, height: rect.height)
            .position(x: rect.minX + (on ? rect.width * 1.3 : -rect.width * 0.3), y: rect.midY)
            .opacity(on ? 0 : 1)
            .mask(Rectangle().frame(width: rect.width, height: rect.height).position(x: rect.midX, y: rect.midY))
            .onAppear { withAnimation(.easeInOut(duration: 0.62)) { on = true } }
    }
}
private struct FlyView: View {
    let key: String, from: CGRect, to: CGPoint
    @State private var on = false
    @Environment(GameVM.self) private var vm
    var body: some View {
        if let c = GameData.shared.card(key) {
            CardView(card: c, size: .sm)
                .scaleEffect(on ? 0.45 : 1).rotationEffect(.degrees(on ? -6 : 0)).opacity(on ? 0 : 1)
                .position(x: on ? to.x : from.midX, y: on ? to.y : from.midY)
                .onAppear { withAnimation(.easeIn(duration: 0.34)) { on = true } }
        }
    }
}

/// "Your turn" / "Enemy turn" ribbon.
struct BannerView: View {
    let banner: Banner
    @Environment(GameVM.self) private var vm
    @State private var on = false
    var body: some View {
        Text(banner.text)
            .font(Theme.display(30, cjk: vm.lang.isCJK)).tracking(vm.lang.isCJK ? 6 : 3)
            .foregroundStyle(banner.foe ? Color(hex: "#f0b0a6") : Theme.parch)
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(LinearGradient(colors: [.clear, Theme.bg.opacity(0.94), Theme.bg.opacity(0.94), .clear], startPoint: .leading, endPoint: .trailing))
            .overlay(VStack { Rectangle().frame(height: 1.5); Spacer(); Rectangle().frame(height: 1.5) }.foregroundStyle(banner.foe ? Theme.blood : Theme.gold).padding(.horizontal, 40))
            .scaleEffect(y: on ? 1 : 0.2)
            .onAppear { withAnimation(.easeOut(duration: 0.28)) { on = true } }
            .allowsHitTesting(false)
    }
}

/// Spotlight of the card the opponent is playing.
struct RevealView: View {
    let r: Reveal
    @Environment(GameVM.self) private var vm
    @State private var on = false
    var body: some View {
        if let c = GameData.shared.card(r.key) {
            VStack(spacing: 8) {
                Text(vm.tx.played(vm.heroName(r.side))).font(Theme.body(13, .heavy)).foregroundStyle(Color(hex: "#f0b0a6"))
                    .padding(.horizontal, 12).padding(.vertical, 3).background(Theme.bg.opacity(0.92), in: Capsule()).overlay(Capsule().stroke(Color(hex: "#7a3f39"), lineWidth: 1))
                CardView(card: c, size: .md).reportFrame { vm.revealFrame = $0 }
                if let t = r.target {
                    Text(vm.tx.target(vm.name(t))).font(Theme.body(13, .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 3).background(Theme.blood.opacity(0.9), in: Capsule())
                }
            }
            .shadow(color: .black.opacity(0.8), radius: 12, y: 10)
            .scaleEffect(on ? 1 : 0.6).opacity(on ? 1 : 0).rotation3DEffect(.degrees(on ? 0 : 80), axis: (0, 1, 0))
            .onAppear { withAnimation(.easeOut(duration: 0.3)) { on = true } }
            .allowsHitTesting(false)
        }
    }
}

/// Full-screen look at a card from the history strip.
struct PeekView: View {
    let h: HistItem
    @Environment(GameVM.self) private var vm
    var body: some View {
        if let c = GameData.shared.card(h.key) {
            ZStack {
                Color(hex: "#0a080c").opacity(0.82).ignoresSafeArea()
                VStack(spacing: 10) {
                    Text(vm.tx.played(vm.heroName(h.side))).font(Theme.body(13, .heavy)).foregroundStyle(h.side == .e ? Color(hex: "#f0b0a6") : Theme.ready)
                        .padding(.horizontal, 12).padding(.vertical, 3).background(Theme.bg.opacity(0.92), in: Capsule()).overlay(Capsule().stroke(h.side == .e ? Color(hex: "#7a3f39") : Theme.kelp, lineWidth: 1))
                    CardView(card: c, size: .md)
                    if let t = h.target {
                        Text(vm.tx.target(vm.name(t))).font(Theme.body(13, .heavy)).foregroundStyle(.white).padding(.horizontal, 12).padding(.vertical, 3).background(Theme.blood.opacity(0.9), in: Capsule())
                    }
                    Text(vm.tx.tapClose).font(Theme.body(12)).foregroundStyle(Theme.muted)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { vm.peekItem = nil }
        }
    }
}
