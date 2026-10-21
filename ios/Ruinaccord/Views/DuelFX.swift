import SwiftUI

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
            if let d = vm.drag, let from = vm.arrowFrom {
                let to = d.over.flatMap { vm.frames[$0] }.map { CGPoint(x: $0.midX, y: $0.midY) } ?? d.pt
                TargetArrow(from: from, to: to, color: d.src == .power ? Theme.gold : Theme.blood, locked: d.over != nil)
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

/// Curved targeting arrow from an attacker (or the hero power) to the finger; it snaps onto a valid target.
struct TargetArrow: View {
    let from: CGPoint, to: CGPoint, color: Color, locked: Bool
    var body: some View {
        Canvas { gc, _ in
            let dx = to.x - from.x, dy = to.y - from.y
            let len = max(1, hypot(dx, dy))
            let nx = -dy / len, ny = dx / len
            let ctrl = CGPoint(x: (from.x + to.x) / 2 + nx * len * 0.16, y: (from.y + to.y) / 2 + ny * len * 0.16)
            var path = Path()
            path.move(to: from)
            path.addQuadCurve(to: to, control: ctrl)
            gc.stroke(path, with: .color(color.opacity(0.3)), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            gc.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [9, 8]))
            let tx = to.x - ctrl.x, ty = to.y - ctrl.y
            let tl = max(1, hypot(tx, ty)), ux = tx / tl, uy = ty / tl
            let size: CGFloat = locked ? 24 : 17
            let base = CGPoint(x: to.x - ux * size, y: to.y - uy * size)
            var head = Path()
            head.move(to: to)
            head.addLine(to: CGPoint(x: base.x - uy * size * 0.55, y: base.y + ux * size * 0.55))
            head.addLine(to: CGPoint(x: base.x + uy * size * 0.55, y: base.y - ux * size * 0.55))
            head.closeSubpath()
            gc.fill(head, with: .color(color))
            gc.fill(Path(ellipseIn: CGRect(x: from.x - 7, y: from.y - 7, width: 14, height: 14)), with: .color(color))
            if locked {
                gc.stroke(Path(ellipseIn: CGRect(x: to.x - 26, y: to.y - 26, width: 52, height: 52)), with: .color(color.opacity(0.8)), lineWidth: 3)
            }
        }
        .allowsHitTesting(false)
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

/// One recent play; tap it to see the card.
struct HistChip: View {
    let h: HistItem
    var size: CGFloat = 30
    @Environment(GameVM.self) private var vm
    var body: some View {
        let foe = h.side == .e
        let fresh = foe && h.round == vm.state?.round && vm.state?.turn == .p
        Button { vm.peekItem = h } label: {
            ZStack {
                RadialGradient(colors: foe ? [Color(hex: "#4a2a2a"), Color(hex: "#1a0c0c")] : [Color(hex: "#3a3046"), Color(hex: "#17121c")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 20)
                if Paintings.has(h.key) { ArtThumb(key: h.key, width: size, height: size) }
                else { Image("art_\(h.key)").resizable().scaledToFit().scaleEffect(1.5) }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(foe ? Color(hex: "#a0483f") : Theme.kelp, lineWidth: 2))
            .shadow(color: fresh ? Theme.blood.opacity(0.75) : .clear, radius: fresh ? 6 : 0)
        }
        .buttonStyle(.plain)
    }
}
