import SwiftUI

/// How the hand is shown: fanned out along the bottom (your turn), parked as a small stack in the bottom-right
/// corner (any other time), or fanned out for a moment to read while parked.
enum HandMode: Hashable { case active, dormant, peek }

/// Your hand, drawn over the duel. Cards are dragged up to play them (a targeted spell straight onto its target),
/// tapped to lift one (tap again to play), or held to read. New cards fly in from the corner, where the deck sits.
struct HandLayer: View {
    let hm: HandMetrics
    /// Global origin of the duel area: drag locations arrive in global coordinates.
    let origin: CGPoint
    @Environment(GameVM.self) private var vm

    var body: some View {
        guard let s = vm.state, !s.mulligan else { return AnyView(EmptyView()) }
        let hand = s.p.hand, n = hand.count
        let mode: HandMode = vm.handActive ? .active : (vm.handPeek ? .peek : .dormant)
        let newFrom = max(0, n - vm.drewCount)
        return AnyView(ZStack(alignment: .topLeading) {
            ForEach(Array(hand.enumerated()), id: \.offset) { i, k in
                if let c = GameData.shared.card(k) {
                    HandSlot(card: c, index: i, n: n, hm: hm, mode: mode, origin: origin,
                             fresh: i >= newFrom, delay: Double(min(4, max(0, i - newFrom))) * 0.08)
                }
            }
            if mode == .dormant && n > 0 {
                Text("\(n)").font(Theme.body(12, .heavy)).foregroundStyle(.white).monospacedDigit()
                    .frame(minWidth: 22).frame(height: 22).padding(.horizontal, 3)
                    .background(Theme.ember, in: Capsule()).overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1))
                    .position(x: hm.corner.x + hm.cardW * hm.cornerScale / 2 - 2, y: hm.corner.y - hm.cardH * hm.cornerScale / 2 + 2)
                    .zIndex(60)
                    .allowsHitTesting(false)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: hm.size.width, height: hm.size.height, alignment: .topLeading)
        .animation(.spring(duration: 0.3), value: mode)
        .onChange(of: n) { _, _ in Task { await vm.wait(600); vm.drewCount = 0 } })
    }
}

/// One card of the hand, placed by its index and the hand's mode; follows the finger while dragged.
private struct HandSlot: View {
    let card: Card
    let index: Int, n: Int
    let hm: HandMetrics
    let mode: HandMode
    let origin: CGPoint
    let fresh: Bool
    let delay: Double
    @Environment(GameVM.self) private var vm
    @State private var appeared = false
    @State private var holdLift = false

    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let dragging: Bool = { if let d = vm.drag, d.src == .hand(index) { return true }; return false }()
        let lifted = vm.hsel == index && mode != .dormant && !dragging
        let canPay = s.canPay(.p, card.id)
        let ok = vm.handActive && !vm.busy && canPay && vm.pending == nil
        let pend: Bool = { if let p = vm.pending, case .spell(let idx) = p.kind { return idx == index }; return false }()
        let fan = mode != .dormant
        let aboveLine = dragging && (vm.drag?.aboveLine ?? false)

        // Slot in the hand: a straight row centred under your hero, overlapping as much as needed (right card on top).
        let rowMax = 2 * min(hm.heroX - hm.handMinX, hm.handMaxX - hm.heroX)
        let spacing = n > 1 ? min(hm.cardW * 0.8, (rowMax - hm.cardW) / CGFloat(n - 1)) : 0
        let fx = hm.heroX + (CGFloat(index) - CGFloat(n - 1) / 2) * spacing
        let rot: CGFloat = 0
        let fy = hm.baseY + (pend ? -hm.lift : 0)

        var pos: CGPoint, scale: CGFloat, angle: CGFloat, z: Double
        if dragging, let d = vm.drag {
            pos = CGPoint(x: d.pt.x - origin.x, y: d.pt.y - origin.y - hm.cardH * 0.18)
            scale = aboveLine ? 0.92 : 1.06; angle = 0; z = 100
        } else if lifted {
            pos = CGPoint(x: fx, y: hm.baseY - hm.lift)
            scale = 1; angle = 0; z = 100
        } else if fan {
            pos = CGPoint(x: fx, y: fy); scale = 1; angle = rot; z = Double(index)
        } else {
            pos = CGPoint(x: hm.corner.x - CGFloat(index) * 1.1, y: hm.corner.y - CGFloat(index) * 1.3)
            scale = hm.cornerScale; angle = -5 + CGFloat(index) * 1.4; z = Double(index)
        }
        if !appeared { pos = hm.corner; scale = hm.cornerScale; angle = 0 }

        let ring: Color = aboveLine && ok ? Theme.ready : lifted ? Theme.gold : pend ? Theme.ember : ok && fan ? Theme.ready : .clear
        let layoutKey = "\(mode)|\(n)|\(lifted)|\(dragging)|\(pend)"
        let anim: Animation? = dragging ? nil : vm.reduceMotion ? .easeOut(duration: 0.12) : .spring(duration: 0.42, bounce: 0.22)

        return AnyView(CardView(card: card, size: .fit(hm.em))
            .overlay(RoundedRectangle(cornerRadius: 0.9 * hm.em).stroke(ring, lineWidth: 2))
            .shadow(color: ring == .clear ? .black.opacity(fan ? 0.5 : 0.3) : ring.opacity(0.6), radius: ring == .clear ? 6 : 9, y: ring == .clear ? 4 : 0)
            .saturation(!canPay && fan && !dragging ? 0.5 : 1).brightness(!canPay && fan && !dragging ? -0.15 : 0)
            .opacity(vm.hiddenHand == index ? 0 : 1)
            .reportFrame { vm.handFrames[index] = $0 }
            // Hit area and gesture belong to the card itself, before it is placed (after `.position` they would cover the whole layer).
            .contentShape(Rectangle())
            .pressDrag(
                onTap: {
                    switch mode {
                    case .dormant: vm.peekHand()
                    case .peek: vm.hsel = vm.hsel == index ? nil : index
                    case .active:
                        if vm.hsel == index { if ok { vm.playHand(index) } else { vm.hsel = nil } }
                        else { vm.hsel = index }
                    }
                },
                onHold: {
                    if mode == .dormant { vm.peekHand() }
                    holdLift = true
                    vm.hsel = index
                    Haptics.lift()
                },
                onHoldEnd: { if holdLift { holdLift = false; if vm.hsel == index { vm.hsel = nil } } },
                onDrag: { p in
                    if mode == .active {
                        if vm.drag == nil { Haptics.lift() }
                        vm.dragHand(index, to: p, line: hm.line + origin.y)
                    } else if mode == .dormant { vm.peekHand() }
                },
                onDrop: { _ in if mode == .active { vm.dropHand(index) } else { vm.drag = nil } })
            .rotationEffect(.degrees(angle))
            .scaleEffect(scale)
            .position(pos)
            .zIndex(z)
            .animation(anim, value: layoutKey)
            .onAppear {
                if fresh && !vm.reduceMotion { withAnimation(.spring(duration: 0.5, bounce: 0.25).delay(delay)) { appeared = true } }
                else { appeared = true }
            }
            .accessibilityLabel(Text("\(vm.tx.name(card.names)), \(card.cost)"))
            .accessibilityAddTraits(.isButton))
    }
}
