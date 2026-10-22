import SwiftUI
import UIKit

/// The three number gems of a card, drawn like hand-painted stones: flat facets in a few tones, a dark ink
/// outline, a thin inner line, a short brush highlight and a grain of paint over everything. Cost is a blue
/// hexagon, Attack an amber diamond, Health a polished red shield (a smooth cabochon, no facets).
enum GemKind { case cost, attack, health }

struct GemView: View {
    let kind: GemKind
    let value: Int
    /// Width of the gem; a shield is a little taller.
    var size: CGFloat = 28
    /// Tints the number (a damaged minion, a buffed stat).
    var numberColor: Color? = nil

    var body: some View {
        let w = size, h = kind == .health ? size * 30 / 28 : size
        let ink: Color = kind == .cost ? Color(hex: "#0c1a36") : kind == .attack ? Color(hex: "#3a1c06") : Color(hex: "#3a0a06")
        ZStack {
            switch kind {
            case .cost: FacetHexagon()
            case .attack: FacetDiamond()
            case .health: CabochonShield()
            }
            GemShape(kind: kind).fill(Color.clear)
                .overlay(NoiseOverlay().clipShape(GemShape(kind: kind)))
            GemShape(kind: kind).stroke(ink, lineWidth: 2.2 * w / 28)
            Text("\(value)")
                .font(.system(size: 12 * w / 28, weight: .black, design: .rounded)).monospacedDigit()
                .foregroundStyle(numberColor ?? Color(hex: "#fff8e6"))
                .shadow(color: ink, radius: 0, x: -0.8 * w / 28, y: 0)
                .shadow(color: ink, radius: 0, x: 0.8 * w / 28, y: 0)
                .shadow(color: ink, radius: 0, x: 0, y: -0.8 * w / 28)
                .shadow(color: ink, radius: 0, x: 0, y: 0.8 * w / 28)
                .shadow(color: .black.opacity(0.6), radius: 1.5 * w / 28, y: 1.2 * w / 28)
                .offset(y: kind == .health ? -1 * w / 28 : 0)
        }
        .frame(width: w, height: h)
        .shadow(color: .black.opacity(0.8), radius: 1.5 * w / 28, y: 1 * w / 28)
        .accessibilityHidden(true)
    }
}

/// Outline of a gem, in the 28-unit space of the mock scaled to the rect.
struct GemShape: Shape {
    let kind: GemKind
    func path(in r: CGRect) -> Path {
        switch kind {
        case .cost: return Path.hexagon(in: r)
        case .attack: return Path.diamond(in: r)
        case .health: return Path.shield(in: r)
        }
    }
}

extension Path {
    /// Points given in the 28 × 28 (or 28 × 30) unit space of the design, scaled into `r`.
    static func unit(_ pts: [(CGFloat, CGFloat)], in r: CGRect, h: CGFloat = 28) -> Path {
        var p = Path()
        let sx = r.width / 28, sy = r.height / h
        for (i, pt) in pts.enumerated() {
            let q = CGPoint(x: r.minX + pt.0 * sx, y: r.minY + pt.1 * sy)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath()
        return p
    }
    static func hexagon(in r: CGRect) -> Path { unit([(14, 1), (26, 7.5), (26, 20.5), (14, 27), (2, 20.5), (2, 7.5)], in: r) }
    static func diamond(in r: CGRect) -> Path { unit([(14, 1.5), (26.5, 14), (14, 26.5), (1.5, 14)], in: r) }
    static func shield(in r: CGRect) -> Path {
        var p = Path()
        let sx = r.width / 28, sy = r.height / 30
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * sx, y: r.minY + y * sy) }
        p.move(to: pt(14, 1.5))
        p.addLine(to: pt(26, 5.5))
        p.addLine(to: pt(26, 14.5))
        p.addCurve(to: pt(14, 28), control1: pt(26, 21.5), control2: pt(20.8, 26.3))
        p.addCurve(to: pt(2, 14.5), control1: pt(7.2, 26.3), control2: pt(2, 21.5))
        p.addLine(to: pt(2, 5.5))
        p.closeSubpath()
        return p
    }
}

/// Six flat facets from the centre, lightest at the top left.
private struct FacetHexagon: View {
    var body: some View {
        GeometryReader { g in
            let r = CGRect(origin: .zero, size: g.size), s = g.size.width / 28
            let facets: [([(CGFloat, CGFloat)], String)] = [
                ([(14, 1), (2, 7.5), (14, 14)], "#9ad8ff"), ([(14, 1), (26, 7.5), (14, 14)], "#5aa8e8"),
                ([(2, 7.5), (2, 20.5), (14, 14)], "#3a80d0"), ([(26, 7.5), (26, 20.5), (14, 14)], "#2a5cae"),
                ([(2, 20.5), (14, 27), (14, 14)], "#1c4284"), ([(14, 27), (26, 20.5), (14, 14)], "#122c60")]
            ZStack {
                Path.hexagon(in: r).fill(Color(hex: "#3578c8"))
                ForEach(0..<facets.count, id: \.self) { i in Path.unit(facets[i].0, in: r).fill(Color(hex: facets[i].1)) }
                Path.unit([(14, 3.6), (23.4, 8.7), (23.4, 19.3), (14, 24.4), (4.6, 19.3), (4.6, 8.7)], in: r)
                    .stroke(Color(hex: "#9ad8ff").opacity(0.5), lineWidth: 0.7 * s)
                BrushStroke(from: (6.5, 7.5), to: (12.5, 4), width: 1.7 * s, color: Color(hex: "#e8f6ff"), opacity: 0.85, in: r)
            }
        }
    }
}

/// Four flat facets, amber.
private struct FacetDiamond: View {
    var body: some View {
        GeometryReader { g in
            let r = CGRect(origin: .zero, size: g.size), s = g.size.width / 28
            let facets: [([(CGFloat, CGFloat)], String)] = [
                ([(14, 1.5), (1.5, 14), (14, 14)], "#f6c858"), ([(14, 1.5), (26.5, 14), (14, 14)], "#e8a236"),
                ([(1.5, 14), (14, 26.5), (14, 14)], "#b4641a"), ([(26.5, 14), (14, 26.5), (14, 14)], "#7c3c0c")]
            ZStack {
                Path.diamond(in: r).fill(Color(hex: "#e59a30"))
                ForEach(0..<facets.count, id: \.self) { i in Path.unit(facets[i].0, in: r).fill(Color(hex: facets[i].1)) }
                Path.unit([(14, 3.8), (24.2, 14), (14, 24.2), (3.8, 14)], in: r).stroke(Color(hex: "#ffd98a").opacity(0.5), lineWidth: 0.7 * s)
                BrushStroke(from: (8.5, 8.5), to: (12.5, 4.5), width: 1.7 * s, color: Color(hex: "#fff4cc"), opacity: 0.85, in: r)
                BrushStroke(from: (6.2, 12.5), to: (7.5, 11.2), width: 1.2 * s, color: Color(hex: "#fff4cc"), opacity: 0.6, in: r)
            }
        }
    }
}

/// A smooth red stone: one radial gradient, a soft highlight at the top left, a soft shadow at the bottom.
private struct CabochonShield: View {
    var body: some View {
        GeometryReader { g in
            let r = CGRect(origin: .zero, size: g.size), s = g.size.width / 28
            ZStack {
                Path.shield(in: r).fill(RadialGradient(colors: [Color(hex: "#ff9a86"), Color(hex: "#d63a2c"), Color(hex: "#5c0c08")],
                                                       center: UnitPoint(x: 0.38, y: 0.3), startRadius: 0, endRadius: 22 * s))
                ZStack {
                    Ellipse().fill(Color(hex: "#ffd8cc").opacity(0.6)).frame(width: 13 * s, height: 8 * s).blur(radius: 1.6 * s).position(x: 9.5 * s, y: 8 * s)
                    Ellipse().fill(Color(hex: "#2a0404").opacity(0.45)).frame(width: 20 * s, height: 10 * s).blur(radius: 1.6 * s).position(x: 15 * s, y: 25 * s)
                }
                .clipShape(GemShape(kind: .health))
                Path { p in
                    let sx = r.width / 28, sy = r.height / 30
                    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
                    p.move(to: pt(14, 4)); p.addLine(to: pt(23.5, 7.3)); p.addLine(to: pt(23.5, 14.5))
                    p.addCurve(to: pt(14, 25.5), control1: pt(23.5, 20.1), control2: pt(19.3, 24.1))
                    p.addCurve(to: pt(4.5, 14.5), control1: pt(9.2, 24.1), control2: pt(4.5, 20.1))
                    p.addLine(to: pt(4.5, 7.3)); p.closeSubpath()
                }
                .stroke(Color(hex: "#ff9a88").opacity(0.5), lineWidth: 0.7 * s)
                BrushStroke(from: (6.5, 7.8), to: (12.5, 5), width: 1.7 * s, color: Color(hex: "#ffe0d8"), opacity: 0.85, in: r, h: 30)
                BrushStroke(from: (5, 11.5), to: (5.8, 13.5), width: 1.1 * s, color: Color(hex: "#ffe0d8"), opacity: 0.55, in: r, h: 30)
            }
        }
    }
}

/// A short rounded dab of light.
private struct BrushStroke: View {
    let from: (CGFloat, CGFloat), to: (CGFloat, CGFloat)
    let width: CGFloat
    let color: Color
    let opacity: Double
    let r: CGRect
    var h: CGFloat = 28
    init(from: (CGFloat, CGFloat), to: (CGFloat, CGFloat), width: CGFloat, color: Color, opacity: Double, in r: CGRect, h: CGFloat = 28) {
        self.from = from; self.to = to; self.width = width; self.color = color; self.opacity = opacity; self.r = r; self.h = h
    }
    var body: some View {
        let sx = r.width / 28, sy = r.height / h
        Path { p in
            p.move(to: CGPoint(x: from.0 * sx, y: from.1 * sy))
            p.addLine(to: CGPoint(x: to.0 * sx, y: to.1 * sy))
        }
        .stroke(color.opacity(opacity), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

/// Dark speckle tiled over a gem so the paint looks rough.
private struct NoiseOverlay: View {
    var body: some View {
        Image(uiImage: NoiseTexture.image).resizable(resizingMode: .tile).interpolation(.none)
            .opacity(0.4)
            .allowsHitTesting(false)
    }
}

/// A 48 × 48 tile of random dark dots with random alpha, made once.
enum NoiseTexture {
    static let image: UIImage = {
        let n = 48
        var bytes = [UInt8](repeating: 0, count: n * n * 4)
        var seed: UInt32 = 0x9E3779B9
        func rnd() -> UInt8 { seed = seed &* 1664525 &+ 1013904223; return UInt8(truncatingIfNeeded: seed >> 24) }
        for i in 0..<(n * n) {
            let a = rnd() % 110
            bytes[i * 4] = UInt8(30 * Int(a) / 255); bytes[i * 4 + 1] = UInt8(15 * Int(a) / 255); bytes[i * 4 + 2] = UInt8(5 * Int(a) / 255); bytes[i * 4 + 3] = a
        }
        let data = Data(bytes)
        guard let provider = CGDataProvider(data: data as CFData),
              let cg = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: n * 4,
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { return UIImage() }
        return UIImage(cgImage: cg)
    }()
}
