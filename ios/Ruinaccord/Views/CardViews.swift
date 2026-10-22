import SwiftUI

enum CardSize { case sm, md, big, fit(CGFloat)
    /// Base unit; the web card is 10 × 15.6 units.
    var em: CGFloat {
        switch self { case .sm: return 9.4; case .md: return 10.8; case .big: return 14; case .fit(let e): return e }
    }
}

/// A full card face: art, cost, name plate, rarity gem, rules text and (for minions) stats.
struct CardView: View {
    let card: Card
    var size: CardSize = .sm
    /// A coloured ring on the frame (playable, lifted, aimed); drawn under the corner gems so they stay readable.
    var ring: Color = .clear
    /// The owner's talent changes to this card (cost, text), if any.
    var ovr: CardOverride? = nil
    /// The rules text is cut to three lines on a card face; the zoom and the duel's preview box show it all.
    var full = false
    @Environment(GameVM.self) private var vm

    var body: some View {
        let em = size.em, cjk = vm.lang.isCJK, tx = vm.tx
        let cost = ovr?.cost ?? card.cost
        let spell = !card.isMinion, leg = card.isLegendary
        // Legendaries wear the painted gold frame, one-copy class epics the purple one: its opening sits on the card's
        // edge, so the ornaments hang outside and cover neither the art nor the rules.
        let framed = leg || card.uniq
        let frame = leg ? Color(hex: "#e8b24a") : spell ? Color(hex: "#6c58b8") : Color(hex: "#8a6a3a")
        let artBg: [Color] = leg ? [Color(hex: "#6a2a1a"), Color(hex: "#1a0806")] : spell ? [Color(hex: "#3d2f6e"), Color(hex: "#100a20")] : [Color(hex: "#5a4636"), Color(hex: "#120d16")]
        let inner = RoundedRectangle(cornerRadius: 0.62 * em)
        ZStack(alignment: .top) {
            // Full-art layout: the painting is the whole card; cards without one show their vector art at the top.
            ZStack(alignment: .top) {
                RadialGradient(colors: artBg, center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: 11 * em)
                if Paintings.has(card.id) {
                    Image(Paintings.name(card.id)).resizable().scaledToFill()
                        .frame(width: 9.44 * em, height: 15.04 * em)
                } else {
                    Image(card.artName).resizable().scaledToFit().padding(.top, 0.45 * em)
                }
            }
            .frame(width: 9.44 * em, height: 15.04 * em)
            .clipShape(inner)
            .padding(0.28 * em)
            RoundedRectangle(cornerRadius: 0.9 * em).strokeBorder(frame, lineWidth: 0.28 * em)
            if ring != .clear { RoundedRectangle(cornerRadius: 0.9 * em).stroke(ring, lineWidth: 2) }
            // Translucent rules box: name, type and text start at the left edge, the part of a card that a
            // neighbour in the fanned hand never covers.
            VStack(alignment: .leading, spacing: 0.18 * em) {
                Text(tx.name(card.names))
                    .font(Theme.display(1.12 * em, cjk: cjk))
                    .foregroundStyle(Color(hex: "#fff4dc"))
                    .shadow(color: .black, radius: 0.2 * em, y: 0.08 * em)
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .multilineTextAlignment(.leading)
                // The frame colour shows minion or spell; this line names the race (Beasts matter in play) and the class.
                let typ = [card.isMinion ? tx.race(card.race ?? "") : nil, card.isPrayer ? tx.prayerT : nil, card.cls.map(tx.className)].compactMap { $0 }.joined(separator: " · ")
                if !typ.isEmpty { Text(typ)
                    .font(Theme.body(0.76 * em, .medium)).tracking(0.5)
                    .foregroundStyle(Color(hex: "#9fc4ee"))
                    .textCase(.uppercase).lineLimit(1).minimumScaleFactor(0.7) }
                RichText(text: tx.cardText(card, ovr: ovr), keywords: tx.keywords, font: Theme.body(0.96 * em), color: Color(hex: "#f3e9d4"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(full ? nil : 3).truncationMode(.tail)
                    .minimumScaleFactor(full ? 0.65 : 0.9)
            }
            .padding(.horizontal, 0.55 * em)
            .padding(.top, 0.85 * em)
            .padding(.bottom, card.isMinion ? 1.25 * em : 0.55 * em)
            .frame(maxWidth: .infinity, minHeight: 15.6 * em * 0.4, alignment: .topLeading)
            .background(Color(hex: "#0e0a12").opacity(0.66), in: RoundedRectangle(cornerRadius: 0.5 * em))
            .overlay(RoundedRectangle(cornerRadius: 0.5 * em).stroke(Color(hex: "#e8c35a").opacity(0.35), lineWidth: 0.08 * em))
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.rarityColor(card.rarity))
                    .frame(width: 0.75 * em, height: 0.75 * em)
                    .overlay(Rectangle().stroke(Color.black.opacity(0.6), lineWidth: 0.1 * em))
                    .rotationEffect(.degrees(45))
                    .shadow(color: leg ? Theme.rarityColor("l") : .clear, radius: 0.4 * em)
                    .offset(y: -0.42 * em)
            }
            .padding(0.35 * em)
            .frame(maxHeight: .infinity, alignment: .bottom)
            if framed {
                // The opening is mapped to the card inset by a quarter em, so the inner bar just covers the card's border.
                let g = leg ? FrameGeo.gold : FrameGeo.purple
                let w = (10 * em - 0.5 * em) / (g.x1 - g.x0), h = w / g.aspect
                Image(leg ? "frame_gold" : "frame_purple").resizable()
                    .frame(width: w, height: h)
                    .position(x: 5 * em + (0.5 - (g.x0 + g.x1) / 2) * w, y: 7.8 * em + (0.5 - (g.y0 + g.y1) / 2) * h)
                    .allowsHitTesting(false)
            }
            // The gems ride on the corners of the card, a little past its edge.
            GemView(kind: .cost, value: cost, size: 2.9 * em, numberColor: cost < card.cost ? Theme.ready : nil)
                .offset(x: -0.8 * em, y: -0.8 * em)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            if card.isMinion {
                HStack {
                    GemView(kind: .attack, value: card.atk ?? 0, size: 2.9 * em)
                    Spacer()
                    GemView(kind: .health, value: card.hp ?? 0, size: 2.9 * em)
                }
                .offset(y: 0.8 * em)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, -0.8 * em)
            }
        }
        .frame(width: 10 * em, height: 15.6 * em)
    }
}

/// Where the opening sits in a painted frame image, as fractions (printed by art/frames/build_frames.py).
private struct FrameGeo {
    let aspect: CGFloat, x0: CGFloat, x1: CGFloat, y0: CGFloat, y1: CGFloat
    static let gold = FrameGeo(aspect: 768 / 1075, x0: 0.1953, x1: 0.8138, y0: 0.1395, y1: 0.8288)
    static let purple = FrameGeo(aspect: 768 / 1082, x0: 0.1758, x1: 0.8333, y0: 0.1155, y1: 0.8438)
}

private struct ArtShape: Shape {
    let spell: Bool
    let em: CGFloat
    func path(in r: CGRect) -> Path {
        if spell { return Path(roundedRect: r, cornerRadius: 0.5 * em) }
        var p = Path()
        let top = r.height * 0.38
        p.move(to: CGPoint(x: r.minX, y: r.maxY - 0.5 * em))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + top))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + top), control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 0.5 * em))
        p.addQuadCurve(to: CGPoint(x: r.maxX - 0.5 * em, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + 0.5 * em, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - 0.5 * em), control: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct StatBubble: View {
    let value: Int
    let attack: Bool
    let em: CGFloat
    var body: some View {
        Text("\(value)")
            .font(Theme.body(1.25 * em, .heavy))
            .foregroundStyle(attack ? Color(hex: "#2a1d08") : .white)
            .frame(width: 2.5 * em, height: 2.5 * em)
            .background(
                RadialGradient(colors: attack ? [Color(hex: "#f3d888"), Color(hex: "#b88a2a")] : [Color(hex: "#ec7a6c"), Color(hex: "#9a2a20")],
                               center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 1.6 * em))
            .clipShape(Circle())
            .overlay(Circle().stroke(attack ? Color(hex: "#2a1d08") : Color(hex: "#3a0a05"), lineWidth: 0.08 * em))
    }
}

/// A minion on the board.
struct MinionView: View {
    let m: Minion
    @Environment(GameVM.self) private var vm

    var body: some View {
        let tx = vm.tx, s = vm.state
        let foe = m.side == .e
        let myTurn = s?.turn == .p
        let ready = m.side == .p && myTurn && vm.pending == nil && !vm.busy && (s?.canAttack(m) ?? false)
        let selected = vm.sel == m.uid
        let target = vm.isValidTarget(m.id)
        let aimed = vm.aimed == m.id || vm.drag?.over == m.id
        let sleeping = m.sleep && m.side == .p && myTurn
        var kws: [String] = []
        if m.isFrozen { kws.append(tx.fFreeze) }
        if m.hasGuard { kws.append(tx.guardKw) }
        if m.ward { kws.append(tx.wardKw) }
        if m.gasp != nil { kws.append(tx.gaspKw) }
        if m.spellDamage > 0 { kws.append(tx.spKw(m.spellDamage)) }
        if m.silenced { kws.append(tx.fSilence) }
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12)
                .fill(LinearGradient(colors: foe ? [Color(hex: "#4a2826"), Color(hex: "#24130f")] : [Color(hex: "#3a3046"), Color(hex: "#211b29")], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12).stroke(m.hasGuard ? Theme.gold : (foe ? Color(hex: "#6d3a33") : Color(hex: "#5a4a6a")), lineWidth: m.hasGuard ? 3 : 2))
            // The picture fills the tile; lasting effects show as icons down the left edge.
            ZStack {
                RadialGradient(colors: [Color(hex: "#5a4636"), Color(hex: "#17110d")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 50)
                if Paintings.has(m.key) { ArtThumb(key: m.key, width: 40, height: 59) }
                else { Image(m.card.artName).resizable().scaledToFit().frame(width: 52).offset(y: -3) }
            }
            .frame(width: 40, height: 59)
            .clipShape(RoundedRectangle(cornerRadius: m.hasGuard ? 4 : 10))
            .grayscale(m.silenced ? 0.85 : 0)
            .padding(.top, 2)
            HStack {
                GemView(kind: .attack, value: m.atk, size: 21, numberColor: m.atk > m.baseAtk ? Theme.ready : nil)
                Spacer()
                GemView(kind: .health, value: m.hp, size: 21, numberColor: m.hp < m.max ? Color(hex: "#ffb3a9") : m.max > m.baseHp ? Theme.ready : nil)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, -6).padding(.bottom, -6)
            if sleeping {
                Text("zz").font(Theme.body(11, .heavy)).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing).offset(x: 6, y: -9)
            }
        }
        .frame(width: 44, height: 63)
        .saturation(sleeping ? 0.6 : 1).brightness(sleeping ? -0.08 : 0)
        .overlay(RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12).fill(Color(hex: "#8fd0ff").opacity(m.isFrozen ? 0.22 : 0)).allowsHitTesting(false))
        .overlay(RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12).stroke(Color(hex: "#8fd0ff"), lineWidth: m.isFrozen ? 3 : 0).padding(-1.5))
        .shadow(color: m.ward ? Theme.foam.opacity(0.7) : .clear, radius: m.ward ? 7 : 0)
        .overlay(RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12).stroke(Theme.foam.opacity(0.6), lineWidth: m.ward ? 3 : 0).padding(-3))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(aimed ? Theme.blood : target ? Theme.blood : selected ? Theme.ember : ready ? Theme.ready : .clear, lineWidth: aimed ? 3 : 2).padding(-4))
        .shadow(color: aimed ? Theme.blood.opacity(0.85) : .clear, radius: aimed ? 9 : 0)
        .offset(y: selected ? -8 : 0)
        .scaleEffect(vm.drag?.src == .minion(m.id) ? 1.08 : 1)
        .offset(vm.lungeOffset[m.id] ?? .zero)
        .zIndex(vm.lungeOffset[m.id] != nil ? 10 : 0)
        .shake(tick: vm.hitTick[m.id] ?? 0)
        .overlay(alignment: .topLeading) { MinionIcons(m: m).offset(x: -7, y: 6) }
        .overlay(alignment: .top) { FloatStack(eid: m.id) }
        .reportFrame { vm.frames[m.id] = $0 }
        .contentShape(Rectangle())
        .pressDrag(onTap: { vm.tap(m.id) },
                   onHold: { vm.infoKey = m.key },
                   onHoldEnd: { if vm.infoKey == m.key { vm.infoKey = nil } },
                   onDrag: { p in if m.side == .p { vm.dragMinion(m.id, to: p) } },
                   onDrop: { _ in vm.dropMinion() })
        .accessibilityLabel(Text("\(tx.name(m.card.names)), \(m.atk)/\(m.hp) \(kws.joined(separator: " "))"))
        .accessibilityAddTraits(.isButton)
        .animation(.spring(duration: 0.25), value: selected)
    }
}

/// Floating numbers above a character.
struct FloatStack: View {
    let eid: EID
    @Environment(GameVM.self) private var vm
    var body: some View {
        ZStack {
            ForEach(vm.floats.filter { $0.eid == eid }) { f in
                FloatLabel(text: vm.floatText(f.kind).0, color: vm.floatText(f.kind).1)
            }
        }
        .offset(y: -18)
        .allowsHitTesting(false)
    }
}
private struct FloatLabel: View {
    let text: String
    let color: Color
    @State private var up = false
    var body: some View {
        Text(text).font(Theme.body(20, .heavy)).foregroundStyle(color)
            .shadow(color: .black, radius: 2, y: 1)
            .fixedSize()
            .scaleEffect(up ? 1 : 1.5)
            .offset(y: up ? -30 : 0)
            .opacity(up ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.9)) { up = true } }
    }
}

/// Class card used on the class pick screens.
struct ClassCard: View {
    let c: HeroClass
    let action: () -> Void
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, col = Color(hex: c.color)
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ClassPortrait(c: c, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.name(c.names)).font(Theme.display(20, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                    Text(tx.name(c.tags)).font(Theme.body(12.5)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(c.power.cost)").font(Theme.body(11, .heavy)).foregroundStyle(.white).frame(width: 20, height: 20).background(Theme.mana, in: Circle())
                        (Text(tx.powerName(c.power)).fontWeight(.bold).foregroundColor(Theme.parch) + Text(" · " + tx.powerDesc(c.power)).foregroundColor(Theme.ink))
                            .font(Theme.body(13)).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            .overlay(alignment: .top) { Rectangle().fill(col).frame(height: 3).clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)).padding(.horizontal, 1) }
        }
        .buttonStyle(.plain)
        .multilineTextAlignment(.leading)
    }
}

struct ClassPortrait: View {
    let c: HeroClass
    var size: CGFloat = 64
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(hex: "#3a3046"), Color(hex: "#140f18")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: size * 0.6))
            Image(c.artName).resizable().scaledToFill().frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(hex: c.color), lineWidth: 2))
    }
}

/// Zoomed card with flavour text, shown on long-press.
struct CardZoom: View {
    let key: String
    @Environment(GameVM.self) private var vm
    var body: some View {
        if let c = GameData.shared.card(key) {
            ZStack {
                Color(hex: "#0a080c").opacity(0.82).ignoresSafeArea()
                VStack(spacing: 10) {
                    CardView(card: c, size: .big, full: true)
                    Text(vm.tx.name(c.flavor)).font(Theme.body(13)).italic().foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 240)
                    Text(vm.tx.tapClose).font(Theme.body(12)).foregroundStyle(Theme.muted)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { vm.zoomCard = nil; vm.peekItem = nil }
            .transition(.opacity)
        }
    }
}

/// Card paintings (Assets.xcassets/Paint, made by art/build_art.py); cards without one use their vector art.
@MainActor enum Paintings {
    private static var cache: [String: Bool] = [:]
    static func name(_ id: String) -> String { "paint_\(id)" }
    static func has(_ id: String) -> Bool {
        if let v = cache[id] { return v }
        let v = UIImage(named: name(id)) != nil
        cache[id] = v
        return v
    }
}

/// A small landscape crop of a card's art: the upper part of a painting (where faces are), or the vector art.
struct ArtThumb: View {
    let key: String
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        if Paintings.has(key) {
            Image(Paintings.name(key)).resizable().scaledToFill()
                .frame(width: width, height: width * 1.5)
                .offset(y: width * 1.5 * 0.5 - height * 0.5 - width * 1.5 * 0.06)
                .frame(width: width, height: height)
                .clipped()
        } else {
            Image("art_\(key)").resizable().scaledToFit().frame(width: width, height: height)
        }
    }
}

/// A hero's round portrait; tap target for attacks and spells. Health, Armor and spell mana live in the status
/// column on the right, so the portrait carries no badges.
struct HeroFace: View {
    let side: Side
    var size: CGFloat = 50
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let h = s[side], tx = vm.tx, foe = side == .e, id = h.id
        let name = vm.heroName(side)
        let portrait: HeroClass? = !foe ? vm.curClass : (s.mode != .camp ? vm.enemyClass : nil)
        let initials = foe && s.mode == .camp ? tx.name(GameData.shared.opponents[s.stage].initials) : tx.heroInit
        let target = vm.isValidTarget(id), aimed = vm.aimed == id || vm.drag?.over == id
        let k = size / 50, dying = vm.dying.contains(side)
        return AnyView(ZStack {
            Circle().fill(RadialGradient(colors: foe ? [Color(hex: "#5a2a26"), Color(hex: "#1e0e0c")] : [Color(hex: "#4a3a5a"), Color(hex: "#1b1422")], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 30 * k))
            if let portrait { Image(portrait.artName).resizable().scaledToFill().frame(width: size - 4, height: size - 4).clipShape(Circle()) }
            else { Text(initials).font(Theme.display(18 * k, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch) }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(foe ? Color(hex: "#8a5a9a") : Color(hex: "#4a8ad0"), lineWidth: 2.5))
        .shadow(color: (foe ? Color(hex: "#8c5aa0") : Color(hex: "#5ad0ff")).opacity(0.5), radius: 8)
        .overlay(Circle().stroke(aimed || target ? Theme.blood : .clear, lineWidth: aimed ? 3 : 2).padding(-4))
        .shadow(color: aimed ? Theme.blood.opacity(0.85) : .clear, radius: aimed ? 9 : 0)
        .shake(tick: vm.hitTick[id] ?? 0)
        // Game over: the beaten portrait flares, swells and breaks apart (the shards are drawn by the FX layer).
        .overlay(Circle().fill(Color.white.opacity(dying ? 0.9 : 0)).animation(.easeOut(duration: 0.3), value: dying))
        .scaleEffect(dying ? 1.55 : 1).opacity(dying ? 0 : 1)
        .animation(.easeIn(duration: 0.6).delay(0.1), value: dying)
        .overlay(alignment: .top) { FloatStack(eid: id) }
        .reportFrame { vm.frames[id] = $0 }
        .contentShape(Circle())
        .onTapGesture { vm.tap(id) }
        .accessibilityLabel(Text("\(name), \(max(0, h.hp)), \(tx.armor) \(h.armor), \(tx.spellManaShort) \(h.spellMana)")))
    }
}

/// Small hexagonal number gem (armor in the status column).
struct StatGem: View {
    let value: Int
    let colors: [Color]
    var dim = false
    var label = ""
    var scale: CGFloat = 1
    /// Dark number, for a light (silver) gem.
    var dark = false
    var body: some View {
        Text("\(value)").font(Theme.body(11 * scale, .heavy)).foregroundStyle(dark ? Color(hex: "#10141c") : .white).monospacedDigit()
            .frame(width: 22 * scale, height: 24 * scale)
            .background(Hexagon().fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(Hexagon().stroke(Color.white.opacity(0.55), lineWidth: 1))
            .opacity(dim ? 0.45 : 1)
            .shadow(color: .black.opacity(0.5), radius: 1.5, y: 1)
            .accessibilityLabel(Text("\(label) \(value)"))
    }
}

/// Shadowverse-style health shield: flat top, pointed bottom.
struct ShieldShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c: CGFloat = r.width * 0.12
        p.move(to: CGPoint(x: r.minX + c, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - c, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + c), control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.62))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.62))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + c))
        p.addQuadCurve(to: CGPoint(x: r.minX + c, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Lasting effects of a board minion as small round icons (landscape board).
struct MinionIcons: View {
    let m: Minion
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        let items: [(String, Color, String)] = [
            m.hasGuard ? ("shield.fill", Theme.gold, tx.guardKw) : nil,
            m.ward ? ("circle.circle", Color(hex: "#a9c4ff"), tx.wardKw) : nil,
            m.gasp != nil ? ("skull", Color(hex: "#d8d3c2"), tx.gaspKw) : nil,
            m.spellDamage > 0 ? ("sparkle", Color(hex: "#c4a3ff"), tx.spKw(m.spellDamage)) : nil,
            m.onSpell != nil ? ("arrow.up", Color(hex: "#8fe08f"), "") : nil,
            m.isFrozen ? ("snowflake", Color(hex: "#8fd0ff"), tx.fFreeze) : nil,
            m.silenced ? ("nosign", Color(hex: "#a6a0aa"), tx.fSilence) : nil,
        ].compactMap { $0 }
        VStack(spacing: 2) {
            ForEach(items, id: \.0) { it in
                Group {
                    if it.0 == "skull" {
                        SkullShape().fill(it.1).frame(width: 10, height: 10)
                            .overlay(HStack(spacing: 2) { Circle().fill(Color(hex: "#17121c")).frame(width: 2.6, height: 2.6); Circle().fill(Color(hex: "#17121c")).frame(width: 2.6, height: 2.6) }.offset(y: -1))
                    }
                    else { Image(systemName: it.0).font(.system(size: 9, weight: .bold)).foregroundStyle(it.1) }
                }
                    .frame(width: 17, height: 17)
                    .background(Color(hex: "#17121c"), in: Circle())
                    .overlay(Circle().stroke(it.1, lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                    .accessibilityLabel(Text(it.2))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Last-breath icon: a small skull (the eyes are drawn on top).
struct SkullShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX, y: r.minY, width: w, height: h * 0.78))
        p.addRect(CGRect(x: r.minX + w * 0.22, y: r.minY + h * 0.6, width: w * 0.56, height: h * 0.4))
        return p
    }
}
