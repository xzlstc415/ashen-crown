import SwiftUI

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        let r, g, b, a: Double
        switch h.count {
        case 8: r = Double((v >> 24) & 255) / 255; g = Double((v >> 16) & 255) / 255; b = Double((v >> 8) & 255) / 255; a = Double(v & 255) / 255
        default: r = Double((v >> 16) & 255) / 255; g = Double((v >> 8) & 255) / 255; b = Double(v & 255) / 255; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// Torchlit dungeon stone, parchment cards, ember and arcane accents (same palette as the web game).
enum Theme {
    static let bg = Color(hex: "#141118")
    static let panel = Color(hex: "#221b26")
    static let line = Color(hex: "#3d3244")
    static let ink = Color(hex: "#ece3d0")
    static let muted = Color(hex: "#a69ba6")
    static let parch = Color(hex: "#efe2c2")
    static let parchInk = Color(hex: "#2b2219")
    static let ember = Color(hex: "#e2763a")
    static let ember2 = Color(hex: "#f39a3a")
    static let kelp = Color(hex: "#6aa57e")
    static let foam = Color(hex: "#a9c4ff")
    static let gold = Color(hex: "#d9b45a")
    static let blood = Color(hex: "#cf4a3f")
    static let ready = Color(hex: "#7fd17f")
    /// Like Hearthstone: a value better than printed is green, worse is red.
    static let upInk = Color(hex: "#9fe09f"), downInk = Color(hex: "#ffb3a9")
    static func delta(_ d: Int) -> Color? { d > 0 ? ready : d < 0 ? downInk : nil }
    static let arcane = Color(hex: "#8f78e0")
    static let mana = Color(hex: "#2f6fa8")
    static let manaLight = Color(hex: "#5aa3e0")

    static func rarityColor(_ r: String) -> Color {
        switch r {
        case "c": return Color(hex: "#e8e4da")
        case "r": return Color(hex: "#4f8fe0")
        case "e": return Color(hex: "#a35ad6")
        case "l": return Color(hex: "#f09a3a")
        default: return muted
        }
    }

    static func display(_ size: CGFloat, cjk: Bool) -> Font {
        cjk ? .system(size: size * 0.92, weight: .semibold, design: .serif) : .system(size: size, weight: .regular, design: .serif)
    }
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .rounded) }
}

struct PrimaryButtonStyle: ButtonStyle {
    var ghost = false
    var danger = false
    var compact = false
    var glow = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(compact ? 13 : 15, .heavy))
            .foregroundStyle(ghost ? (danger ? Color(hex: "#f0a097") : Theme.ink) : Color(hex: "#2a130a"))
            .padding(.horizontal, compact ? 12 : 18)
            .padding(.vertical, compact ? 7 : 11)
            .background(ghost ? Color.clear : Theme.ember, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ghost ? (danger ? Theme.blood : Theme.line) : .clear, lineWidth: 1))
            .shadow(color: glow ? Theme.ready.opacity(0.7) : .clear, radius: glow ? 8 : 0)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    func primary(compact: Bool = false, glow: Bool = false) -> some View { buttonStyle(PrimaryButtonStyle(compact: compact, glow: glow)) }
    func ghost(compact: Bool = false, danger: Bool = false) -> some View { buttonStyle(PrimaryButtonStyle(ghost: true, danger: danger, compact: compact)) }
    func panel(radius: CGFloat = 12) -> some View {
        background(Theme.panel, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Theme.line, lineWidth: 1))
    }
}

/// Text with the game's rule keywords (or `**markdown**`) in bold.
struct RichText: View {
    let text: String
    var keywords: [String] = []
    var font: Font = .body
    var color: Color = Theme.parchInk
    /// Which numbers in the text (0 = the first number) to draw in `greenColor`: values the talents changed.
    var greens: Set<Int> = []
    var greenColor: Color = Theme.upInk
    var body: some View {
        Text(attributed).font(font).foregroundStyle(color)
    }
    /// The numbers of `text` that differ from `base`, by position; none unless the rest of the two texts is the same.
    static func changedNumbers(_ text: String, from base: String) -> Set<Int> {
        func split(_ s: String) -> (words: [String], nums: [String]) {
            var words = [""], nums: [String] = []
            for ch in s {
                if ch.isASCII && ch.isNumber {
                    if words.count == nums.count + 1 { nums.append("") }
                    nums[nums.count - 1].append(ch)
                } else {
                    if words.count == nums.count { words.append("") }
                    words[words.count - 1].append(ch)
                }
            }
            return (words, nums)
        }
        let a = split(text), b = split(base)
        guard a.words == b.words, a.nums.count == b.nums.count else { return [] }
        return Set(a.nums.indices.filter { a.nums[$0] != b.nums[$0] })
    }
    private var attributed: AttributedString {
        var s = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
        if !greens.isEmpty {
            var n = 0, i = s.startIndex
            while i < s.endIndex {
                guard s.characters[i].isASCII && s.characters[i].isNumber else { i = s.characters.index(after: i); continue }
                var j = i
                while j < s.endIndex && s.characters[j].isASCII && s.characters[j].isNumber { j = s.characters.index(after: j) }
                if greens.contains(n) { s[i..<j].foregroundColor = greenColor; s[i..<j].font = font.weight(.heavy) }
                n += 1; i = j
            }
        }
        for kw in keywords {
            var searchRange = s.startIndex..<s.endIndex
            while let r = s[searchRange].range(of: kw) {
                s[r].font = font.weight(.heavy)
                searchRange = r.upperBound..<s.endIndex
            }
        }
        return s
    }
}

/// Reports a view's frame in global coordinates to the view model.
struct FrameReporter: ViewModifier {
    let onChange: (CGRect) -> Void
    func body(content: Content) -> some View {
        content.background(GeometryReader { geo in
            let f = geo.frame(in: .global)
            Color.clear.onAppear { onChange(f) }.onChange(of: f) { _, n in onChange(n) }
        })
    }
}
extension View {
    func reportFrame(_ onChange: @escaping (CGRect) -> Void) -> some View { modifier(FrameReporter(onChange: onChange)) }
}

/// Short horizontal shake used when a character takes a hit.
struct Shake: ViewModifier, Animatable {
    var t: CGFloat
    var animatableData: CGFloat { get { t } set { t = newValue } }
    func body(content: Content) -> some View {
        content.offset(x: sin(t * .pi * 3) * 5 * (1 - t))
    }
}
extension View {
    func shake(tick: Int) -> some View { modifier(ShakeHost(tick: tick)) }
}
private struct ShakeHost: ViewModifier {
    let tick: Int
    @State private var t: CGFloat = 1
    func body(content: Content) -> some View {
        content.modifier(Shake(t: t)).onChange(of: tick) { _, _ in
            t = 0
            withAnimation(.easeOut(duration: 0.38)) { t = 1 }
        }
    }
}

struct Hexagon: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.25))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.75))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.75))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.25))
        p.closeSubpath()
        return p
    }
}

struct Embers: View {
    @State private var seeds: [(x: CGFloat, size: CGFloat, dur: Double, dx: CGFloat, delay: Double)] = (0..<16).map { _ in
        (.random(in: 0...1), .random(in: 2...5), .random(in: 10...24), .random(in: -40...40), .random(in: 0...20))
    }
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
            Canvas { gc, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                for s in seeds {
                    let p = ((t + s.delay) / s.dur).truncatingRemainder(dividingBy: 1)
                    let y = size.height + 12 - p * (size.height + 24)
                    let x = s.x * size.width + s.dx * p
                    let a = p < 0.5 ? 0.7 : 0.7 * (1 - (p - 0.5) * 2)
                    let r = CGRect(x: x, y: y, width: s.size, height: s.size)
                    gc.fill(Path(ellipseIn: r), with: .color(Theme.ember2.opacity(a)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Light taps for picking up, aiming at and dropping cards.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let note = UINotificationFeedbackGenerator()
    static func lift() { light.impactOccurred(intensity: 0.7) }
    static func tick() { light.impactOccurred(intensity: 0.5) }
    static func drop() { medium.impactOccurred() }
    static func fail() { note.notificationOccurred(.error) }
}

/// One finger-down gesture that tells a tap, a hold and a drag apart, so a card can be tapped to lift, held to
/// read and dragged to play without the gestures fighting each other (as separate SwiftUI gestures would).
/// Locations are in global coordinates.
struct PressDrag: ViewModifier {
    var enabled = true
    var holdAfter: Double = 0.4
    var slack: CGFloat = 9
    var onTap: () -> Void = {}
    var onHold: () -> Void = {}
    var onHoldEnd: () -> Void = {}
    var onDrag: (CGPoint) -> Void = { _ in }
    var onDrop: (CGPoint) -> Void = { _ in }

    @State private var phase = Phase.idle
    @State private var holdTask: Task<Void, Never>?
    private enum Phase { case idle, pressed, held, dragging }

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { v in
                    guard enabled else { return }
                    let moved = hypot(v.translation.width, v.translation.height) > slack
                    switch phase {
                    case .idle:
                        phase = .pressed
                        holdTask?.cancel()
                        holdTask = Task { @MainActor in
                            try? await Task.sleep(for: .seconds(holdAfter))
                            if !Task.isCancelled, phase == .pressed { phase = .held; onHold() }
                        }
                    case .pressed:
                        if moved { holdTask?.cancel(); phase = .dragging; onDrag(v.location) }
                    case .held:
                        if moved { phase = .dragging; onHoldEnd(); onDrag(v.location) }
                    case .dragging:
                        onDrag(v.location)
                    }
                }
                .onEnded { v in
                    holdTask?.cancel()
                    let was = phase
                    phase = .idle
                    guard enabled else { return }
                    switch was {
                    case .pressed: onTap()
                    case .held: onHoldEnd()
                    case .dragging: onDrop(v.location)
                    case .idle: break
                    }
                },
            including: enabled ? .all : .subviews
        )
    }
}
extension View {
    func pressDrag(enabled: Bool = true, holdAfter: Double = 0.4, onTap: @escaping () -> Void = {}, onHold: @escaping () -> Void = {},
                   onHoldEnd: @escaping () -> Void = {}, onDrag: @escaping (CGPoint) -> Void = { _ in }, onDrop: @escaping (CGPoint) -> Void = { _ in }) -> some View {
        modifier(PressDrag(enabled: enabled, holdAfter: holdAfter, onTap: onTap, onHold: onHold, onHoldEnd: onHoldEnd, onDrag: onDrag, onDrop: onDrop))
    }
}
