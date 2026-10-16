import SwiftUI

enum CardSize { case sm, md, big
    /// Base unit; the web card is 10 × 15.6 units.
    var em: CGFloat { self == .sm ? 9.4 : self == .md ? 10.8 : 14 }
}

/// A full card face: art, cost, name plate, rarity gem, rules text and (for minions) stats.
struct CardView: View {
    let card: Card
    var size: CardSize = .sm
    @Environment(GameVM.self) private var vm

    var body: some View {
        let em = size.em, cjk = vm.lang.isCJK, tx = vm.tx
        let spell = !card.isMinion, leg = card.isLegendary
        let bg: [Color] = leg ? [Color(hex: "#f2cc6e"), Color(hex: "#8a5a1a")] : spell ? [Color(hex: "#7a66c0"), Color(hex: "#33285c")] : [Color(hex: "#9a7848"), Color(hex: "#4a3520")]
        let artBg: [Color] = leg ? [Color(hex: "#6a2a1a"), Color(hex: "#1a0806")] : spell ? [Color(hex: "#3d2f6e"), Color(hex: "#100a20")] : [Color(hex: "#5a4636"), Color(hex: "#17110d")]
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 0.9 * em)
                .fill(LinearGradient(colors: bg, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 0.9 * em).stroke(Color.black.opacity(0.25), lineWidth: 0.12 * em))
                .shadow(color: .black.opacity(0.6), radius: 0, y: 0.25 * em)
            VStack(spacing: 0.25 * em) {
                // Art
                ZStack {
                    RadialGradient(colors: artBg, center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 6 * em)
                    Image(card.artName).resizable().scaledToFit()
                }
                .frame(height: 6.1 * em)
                .clipShape(ArtShape(spell: spell, em: em))
                .overlay(ArtShape(spell: spell, em: em).stroke(Color.black.opacity(0.45), lineWidth: 0.15 * em))
                // Name plate
                Text(tx.name(card.names))
                    .font(Theme.display(1.12 * em, cjk: cjk))
                    .foregroundStyle(Theme.parch)
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 0.22 * em).padding(.horizontal, 0.25 * em)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: spell ? [Color(hex: "#3a2e5e"), Color(hex: "#1a1430")] : [Color(hex: "#4a3a2a"), Color(hex: "#22190f")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 0.3 * em))
                    .shadow(color: .black.opacity(0.6), radius: 0.25 * em, y: 0.1 * em)
                    .padding(.horizontal, 0.15 * em)
                    .padding(.top, -1 * em)
                    .zIndex(1)
                // Rarity gem
                Rectangle().fill(Theme.rarityColor(card.rarity))
                    .frame(width: 0.75 * em, height: 0.75 * em)
                    .overlay(Rectangle().stroke(Color.black.opacity(0.6), lineWidth: 0.1 * em))
                    .rotationEffect(.degrees(45))
                    .shadow(color: leg ? Theme.rarityColor("l") : .clear, radius: 0.4 * em)
                    .padding(.top, -0.15 * em)
                    .zIndex(1)
                // Text box
                VStack(spacing: 0.15 * em) {
                    Text(card.isMinion ? "\(tx.minion) · \(tx.race(card.race ?? ""))" : tx.spell)
                        .font(Theme.body(0.72 * em, .medium)).tracking(0.5)
                        .foregroundStyle(Theme.parchInk.opacity(0.6))
                        .textCase(.uppercase).lineLimit(1).minimumScaleFactor(0.7)
                    RichText(text: tx.cardText(card), keywords: tx.keywords, font: Theme.body(1 * em), color: Theme.parchInk)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.65)
                }
                .padding(.horizontal, 0.35 * em)
                .padding(.top, 0.3 * em)
                .padding(.bottom, card.isMinion ? 1.1 * em : 0.4 * em)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(spell ? Color(hex: "#e8e2f2") : Theme.parch, in: RoundedRectangle(cornerRadius: 0.45 * em))
            }
            .padding(0.45 * em)
            // Cost
            Text("\(card.cost)")
                .font(Theme.body(1.3 * em, .heavy)).foregroundStyle(.white)
                .frame(width: 2.6 * em, height: 2.6 * em)
                .background(RadialGradient(colors: [Color(hex: "#7cb8ee"), Theme.mana], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 1.6 * em), in: Hexagon())
                .overlay(Hexagon().stroke(Color(hex: "#bfe0fa"), lineWidth: 0.1 * em))
                .offset(x: -0.4 * em, y: -0.45 * em)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            if card.isMinion {
                HStack {
                    StatBubble(value: card.atk ?? 0, attack: true, em: em)
                    Spacer()
                    StatBubble(value: card.hp ?? 0, attack: false, em: em)
                }
                .offset(y: 0.3 * em)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, -0.3 * em)
            }
        }
        .frame(width: 10 * em, height: 15.6 * em)
    }
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
        let aimed = vm.aimed == m.id
        let sleeping = m.sleep && m.side == .p && myTurn
        var kws: [String] = []
        if m.hasGuard { kws.append(tx.guardKw) }
        if m.ward { kws.append(tx.wardKw) }
        if m.card.gasp != nil { kws.append(tx.gaspKw) }
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12)
                .fill(LinearGradient(colors: foe ? [Color(hex: "#4a2826"), Color(hex: "#24130f")] : [Color(hex: "#3a3046"), Color(hex: "#211b29")], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12).stroke(m.hasGuard ? Theme.gold : (foe ? Color(hex: "#6d3a33") : Color(hex: "#5a4a6a")), lineWidth: m.hasGuard ? 3 : 2))
            VStack(spacing: 1) {
                ZStack {
                    RadialGradient(colors: [Color(hex: "#5a4636"), Color(hex: "#17110d")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 40)
                    Image(m.card.artName).resizable().scaledToFit()
                }
                .frame(width: 54, height: 32)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 4, bottomTrailingRadius: 4, topTrailingRadius: 10))
                Text(tx.name(m.card.names)).font(Theme.body(9.5, .heavy)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.75).frame(height: 21)
                Text(kws.joined(separator: " ")).font(Theme.body(7.5, .bold)).foregroundStyle(Theme.gold).textCase(.uppercase).lineLimit(1).minimumScaleFactor(0.6)
            }
            .padding(.top, 3).padding(.horizontal, 3)
            HStack {
                Text("\(m.atk)").font(Theme.body(12, .heavy)).foregroundStyle(Color(hex: "#2a1d08"))
                    .frame(width: 22, height: 22).background(Theme.gold, in: Circle())
                    .overlay(Circle().stroke(Theme.ready, lineWidth: m.atk > m.baseAtk ? 2 : 0))
                Spacer()
                Text("\(m.hp)").font(Theme.body(12, .heavy)).foregroundStyle(m.hp < m.max ? Color(hex: "#ffb3a9") : .white)
                    .frame(width: 22, height: 22).background(m.hp < m.max ? Color(hex: "#8a1f18") : Theme.blood, in: Circle())
                    .overlay(Circle().stroke(Theme.ready, lineWidth: m.max > m.baseHp && m.hp >= m.max ? 2 : 0))
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, -7).padding(.bottom, -7)
            if sleeping {
                Text("zz").font(Theme.body(11, .heavy)).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing).offset(x: 6, y: -9)
            }
        }
        .frame(width: 60, height: 84)
        .saturation(sleeping ? 0.6 : 1).brightness(sleeping ? -0.08 : 0)
        .shadow(color: m.ward ? Theme.foam.opacity(0.7) : .clear, radius: m.ward ? 7 : 0)
        .overlay(RoundedRectangle(cornerRadius: m.hasGuard ? 6 : 12).stroke(Theme.foam.opacity(0.6), lineWidth: m.ward ? 3 : 0).padding(-3))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(aimed ? Theme.blood : target ? Theme.blood : selected ? Theme.ember : ready ? Theme.ready : .clear, lineWidth: aimed ? 3 : 2).padding(-4))
        .shadow(color: aimed ? Theme.blood.opacity(0.85) : .clear, radius: aimed ? 9 : 0)
        .offset(y: selected ? -8 : 0)
        .offset(vm.lungeOffset[m.id] ?? .zero)
        .zIndex(vm.lungeOffset[m.id] != nil ? 10 : 0)
        .shake(tick: vm.hitTick[m.id] ?? 0)
        .overlay(alignment: .top) { FloatStack(eid: m.id) }
        .reportFrame { vm.frames[m.id] = $0 }
        .contentShape(Rectangle())
        .onTapGesture { vm.tap(m.id) }
        .onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = m.key }
        .accessibilityLabel(Text("\(tx.name(m.card.names)), \(m.atk)/\(m.hp) \(kws.joined(separator: " "))"))
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

/// A hero row: face with health, name, mana crystals, hand/deck counts, hero power.
struct HeroView: View {
    let side: Side
    @Environment(GameVM.self) private var vm

    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let h = s[side], tx = vm.tx, foe = side == .e
        let id = h.id
        let name = vm.heroName(side)
        let portrait: HeroClass? = !foe ? vm.curClass : (s.mode != .camp ? vm.enemyClass : nil)
        let initials = foe && s.mode == .camp ? tx.name(GameData.shared.opponents[s.stage].initials) : tx.heroInit
        let target = vm.isValidTarget(id)
        let aimed = vm.aimed == id
        return AnyView(HStack(spacing: 10) {
            // Face
            ZStack {
                Circle().fill(RadialGradient(colors: foe ? [Color(hex: "#5a2a26"), Color(hex: "#1e0e0c")] : [Color(hex: "#4a3a5a"), Color(hex: "#1b1422")], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 30))
                if let portrait { Image(portrait.artName).resizable().scaledToFill().frame(width: 46, height: 46).clipShape(Circle()) }
                else { Text(initials).font(Theme.display(18, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch) }
            }
            .frame(width: 50, height: 50)
            .overlay(Circle().stroke(foe ? Color(hex: "#6d3a33") : Color(hex: "#5a4a6a"), lineWidth: 2))
            .overlay(Circle().stroke(aimed || target ? Theme.blood : .clear, lineWidth: aimed ? 3 : 2).padding(-4))
            .shadow(color: aimed ? Theme.blood.opacity(0.85) : .clear, radius: aimed ? 9 : 0)
            .overlay(alignment: .bottomTrailing) {
                Text("\(h.hp)").font(Theme.body(13, .heavy)).foregroundStyle(.white).monospacedDigit()
                    .frame(minWidth: 24).frame(height: 24).padding(.horizontal, 4)
                    .background(Theme.blood, in: Capsule()).offset(x: 8, y: 6)
            }
            .overlay(alignment: .bottomLeading) {
                if h.armor > 0 {
                    Text("\(h.armor)").font(Theme.body(12, .heavy)).foregroundStyle(.white)
                        .frame(minWidth: 22).frame(height: 22).background(Color(hex: "#5e6670"), in: RoundedRectangle(cornerRadius: 6)).offset(x: -8, y: 6)
                }
            }
            .shake(tick: vm.hitTick[id] ?? 0)
            .overlay(alignment: .top) { FloatStack(eid: id) }
            .reportFrame { vm.frames[id] = $0 }
            .contentShape(Circle())
            .onTapGesture { vm.tap(id) }
            .padding(.trailing, 6)
            .accessibilityLabel(Text("\(name), \(h.hp)"))
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(Theme.display(17, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch).lineLimit(1)
                HStack(spacing: 3) {
                    ForEach(0..<h.maxMana, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2).fill(i < h.mana ? Theme.manaLight : Color(hex: "#2a2234"))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(i < h.mana ? Color(hex: "#8cc4f0") : Color(hex: "#3d3150"), lineWidth: 1))
                            .frame(width: 9, height: 12)
                            .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.21, d: 1, tx: 0, ty: 0))
                    }
                    Text("\(h.mana)/\(h.maxMana)").font(Theme.body(12, .semibold)).foregroundStyle(Color(hex: "#8cc4f0")).monospacedDigit().padding(.leading, 4)
                }
                .accessibilityLabel(Text(tx.mana(h.mana, h.maxMana)))
                Text(tx.handDeck(h.hand.count, h.deck.count)).font(Theme.body(12)).foregroundStyle(Theme.muted).monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Power
            PowerButton(side: side, power: h.power)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .panel(radius: 10))
    }
}

struct PowerButton: View {
    let side: Side
    let power: Power
    @Environment(GameVM.self) private var vm
    @State private var pulse = false
    var body: some View {
        let tx = vm.tx, foe = side == .e
        let enabled = !foe && !vm.powerBlocked
        Button { if !foe { vm.usePower() } } label: {
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: "#4a3a2a"), Color(hex: "#1e160f")], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 34))
                Text(tx.powerName(power)).font(Theme.body(10, .bold)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7).frame(width: 50)
            }
            .frame(width: 58, height: 58)
            .overlay(Circle().stroke(foe ? Color(hex: "#6d3a33") : Theme.gold, lineWidth: 2))
            .overlay(alignment: .top) {
                Text("\(power.cost)").font(Theme.body(11, .heavy)).foregroundStyle(.white).frame(width: 20, height: 20).background(Theme.mana, in: Circle()).offset(y: -6)
            }
            .shadow(color: enabled && pulse ? Theme.gold.opacity(0.6) : .clear, radius: 10)
            .opacity(foe ? 0.75 : enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(foe)
        .reportFrame { if foe { vm.epowFrame = $0 } else { vm.powerFrame = $0 } }
        .onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { pulse = true } }
        .accessibilityLabel(Text("\(tx.heroPower) \(tx.powerName(power)), \(power.cost): \(tx.powerDesc(power))"))
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
                    CardView(card: c, size: .big)
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
