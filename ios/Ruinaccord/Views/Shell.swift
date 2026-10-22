import SwiftUI

/// Every screen outside the duel is one landscape screenful: a scene painting behind, a 44pt bar on top and
/// content that never scrolls. Anything that does not fit a screen is paged with arrows and dots.
struct ScreenShell<Content: View>: View {
    var scene = "dawn"
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            SceneBackdrop(name: scene, menu: true)
            content
        }
        .transition(.opacity)
    }
}

/// The top bar: a back button, the title, a short subtitle and trailing actions.
struct BarRow<Trailing: View>: View {
    var back: (String, () -> Void)? = nil
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing
    @Environment(GameVM.self) private var vm
    var body: some View {
        HStack(spacing: 12) {
            if let back { Button("‹ " + back.0, action: back.1).ghost(compact: true) }
            Text(title).font(Theme.display(19, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch).lineLimit(1)
            if let subtitle { Text(subtitle).font(Theme.body(12)).foregroundStyle(Theme.muted).lineLimit(1).minimumScaleFactor(0.8) }
            Spacer(minLength: 8)
            trailing
        }
        .frame(height: 44)
        .padding(.horizontal, 12)
    }
}

extension BarRow where Trailing == EmptyView {
    init(back: (String, () -> Void)? = nil, title: String, subtitle: String? = nil) {
        self.back = back; self.title = title; self.subtitle = subtitle; self.trailing = EmptyView()
    }
}

/// A big arrow button at the side of a paged area.
struct PageArrow: View {
    let next: Bool
    let enabled: Bool
    let action: () -> Void
    @Environment(GameVM.self) private var vm
    var body: some View {
        Button(action: action) {
            Image(systemName: next ? "chevron.right" : "chevron.left").font(.system(size: 18, weight: .heavy))
                .foregroundStyle(enabled ? Color(hex: "#9fc4ee") : Color(hex: "#5a4f66"))
                .frame(width: 36, height: 84)
                .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(enabled ? Color(hex: "#4a6a9a") : Color(hex: "#3a3246"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text(next ? vm.tx.nextPage : vm.tx.prevPage))
    }
}

/// Page dots under a paged area.
struct PageDots: View {
    let n: Int, cur: Int
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(1, n), id: \.self) { i in
                Circle().fill(i == cur ? Theme.gold : Color(hex: "#4a4256")).frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A paged grid: `rows` × as many columns as fit the width, arrows on the sides, dots underneath. The page
/// index resets when the item list changes (a new filter).
struct PagedGrid<Item: Identifiable, Cell: View>: View {
    let items: [Item]
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    var rows = 2
    var hGap: CGFloat = 8
    var vGap: CGFloat = 12
    /// The cell gets the scale (≤ 1) that makes `rows` rows fit the height on offer, so it can draw smaller.
    @ViewBuilder let cell: (Item, CGFloat) -> Cell
    @State private var page = 0
    @Environment(GameVM.self) private var vm

    /// Room kept above and below the rows for gems and badges that hang over the slot edges.
    private let bleed: CGFloat = 6
    private let footer: CGFloat = 18

    var body: some View {
        GeometryReader { g in
            let avail = g.size.height - footer - 6 - 2 * bleed - CGFloat(rows - 1) * vGap
            let s = min(1, max(0.5, avail / (CGFloat(rows) * cellHeight)))
            let cw = cellWidth * s, ch = cellHeight * s
            let cols = max(1, Int((g.size.width - 2 * 44 - 8) / (cw + hGap)))
            let per = cols * rows
            let pages = max(1, (items.count + per - 1) / per)
            let p = min(page, pages - 1)
            let slice = Array(items.dropFirst(p * per).prefix(per))
            let columns = Array(repeating: GridItem(.fixed(cw), spacing: hGap), count: cols)
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    PageArrow(next: false, enabled: p > 0) { page = p - 1 }
                    LazyVGrid(columns: columns, spacing: vGap) {
                        ForEach(slice) { it in cell(it, s).frame(width: cw, height: ch) }
                    }
                    .padding(.vertical, bleed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    PageArrow(next: true, enabled: p < pages - 1) { page = p + 1 }
                }
                HStack(spacing: 10) {
                    Text(vm.tx.pageOf(p + 1, pages)).font(Theme.body(11)).foregroundStyle(Theme.muted).monospacedDigit()
                    PageDots(n: pages, cur: p)
                }
                .frame(height: footer)
            }
            .frame(width: g.size.width, height: g.size.height)
            .clipped()
            .onChange(of: items.count) { _, _ in page = 0 }
        }
    }
}

/// A button that is only a symbol, named for VoiceOver: for bars and tiles where a word would be cut short.
struct IconButton: View {
    let symbol: String
    let label: String
    var primary = false
    var danger = false
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 14, weight: .bold)).frame(width: 20, height: 18) }
            .buttonStyle(PrimaryButtonStyle(ghost: !primary, danger: danger, compact: true))
            .accessibilityLabel(Text(label))
    }
}

/// A small square tag button (filters): a word, a symbol, or a symbol with a short value beside it.
struct Tag: View {
    var text = ""
    var symbol: String? = nil
    var label = ""
    let on: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let symbol { Image(systemName: symbol).font(.system(size: 11, weight: .bold)) }
                if !text.isEmpty { Text(text).font(Theme.body(11, .heavy)).lineLimit(1) }
            }
            .foregroundStyle(on ? Theme.gold : Theme.muted)
                .frame(minWidth: 26).frame(height: 26).padding(.horizontal, 4)
                .background(on ? Theme.gold.opacity(0.2) : Theme.panel, in: Capsule())
                .overlay(Capsule().stroke(on ? Theme.gold : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label.isEmpty ? text : label))
    }
}

/// A class as a standing tile: portrait, class and hero names, its line and its hero power.
struct ClassTile: View {
    let c: HeroClass
    var width: CGFloat = 126
    var height: CGFloat = 290
    let action: () -> Void
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, col = Color(hex: c.color)
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RadialGradient(colors: [Color(hex: "#3a3046"), Color(hex: "#140f18")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: width * 0.7)
                    Image(c.artName).resizable().scaledToFill().frame(width: width - 3, height: height * 0.47).clipped()
                }
                .frame(width: width - 3, height: height * 0.47)
                Text(tx.name(c.names)).font(Theme.display(16, cjk: vm.lang.isCJK)).foregroundStyle(col.mixed(with: .white, 0.5)).padding(.horizontal, 9).padding(.top, 7)
                Text("\(tx.heroName(c.id)) · \(tx.heroRace(c.id))").font(Theme.body(9.5, .bold)).foregroundStyle(Theme.gold).padding(.horizontal, 9).padding(.top, 2).lineLimit(1).minimumScaleFactor(0.8)
                Text(tx.name(c.tags)).font(Theme.body(10.5)).foregroundStyle(Theme.muted).lineSpacing(2).padding(.horizontal, 9).padding(.top, 5).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text("\(tx.heroPower) · \(tx.powerName(c.power))").font(Theme.body(9.5, .bold)).foregroundStyle(Color(hex: "#9fc4ee")).padding(.horizontal, 9).padding(.bottom, 9).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .background(LinearGradient(colors: [col.opacity(0.22), Color(hex: "#120c14").opacity(0.96)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(col, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .multilineTextAlignment(.leading)
        .accessibilityLabel(Text("\(tx.name(c.names)): \(tx.name(c.tags))"))
    }
}

extension Color {
    /// This colour blended towards another.
    func mixed(with other: Color, _ t: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0, r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1); b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(red: Double(r1 + (r2 - r1) * t), green: Double(g1 + (g2 - g1) * t), blue: Double(b1 + (b2 - b1) * t))
    }
}
