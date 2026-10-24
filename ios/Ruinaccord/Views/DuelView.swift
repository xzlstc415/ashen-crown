import SwiftUI

/// Sizes shared by the duel layout and the hand layer, all from the duel area's size (landscape only).
/// Left to right: menu and battle log; the board column with both heroes at its left (enemy top, you bottom),
/// the boards between them and the hand to the right of your hero; a status column on the right holding both
/// heroes' numbers around the End Turn button. Your hero power is a round button at your hero's shoulder.
struct HandMetrics: Equatable {
    let size: CGSize
    /// The screen continues this far below the duel area (home indicator); cards may hang into it.
    var bottomInset: CGFloat = 0
    var leftW: CGFloat { 54 }
    var rightW: CGFloat { 116 }
    /// Height of the strip holding the enemy hand backs and counts. The enemy portrait is taller and hangs down
    /// beside the enemy board row (the minions sit in the middle of the row, well right of it).
    var topH: CGFloat { 48 }
    /// Height of one board row: the minion tile plus its corner gems hanging below.
    var rowH: CGFloat { 69 }
    /// Vertical padding of the duel column and the gaps between its rows.
    var pad: CGFloat { 2 }
    var gap: CGFloat { 3 }
    /// Card size: a whole card stands under the boards on your turn, clear of your minions' gems; capped so the
    /// hand keeps the size the user chose on big screens.
    var em: CGFloat {
        let free = size.height - 2 * pad - topH - 2 * rowH - 3 * gap - 8
        return min(11, max(6, (free - 8) / 15.6))
    }
    var cardW: CGFloat { 10 * em }
    var cardH: CGFloat { 15.6 * em }
    /// Off your turn the hand sinks this far below the bottom edge.
    var sink: CGFloat { cardH * 0.3 }
    /// Height the board column leaves free at the bottom for the hand (and the gems above it).
    var reserve: CGFloat { cardH + 12 }
    /// Local y above which a dragged card counts as played.
    var line: CGFloat { size.height - reserve - 2 * pad }
    /// Centre x of both heroes: the left part of the board column.
    var heroX: CGFloat { leftW + 100 }
    /// Centre y of your hero's portrait, in the hand zone, left of the cards.
    var heroY: CGFloat { size.height - heroSize / 2 - 32 }
    /// Portrait diameter of both heroes (about a quarter of the screen height, like Shadowverse).
    var heroSize: CGFloat { 80 }
    /// The hand fans between your hero power and the status column.
    var handMinX: CGFloat { heroX + 95 }
    var handMaxX: CGFloat { size.width - rightW - 4 }
    var handCX: CGFloat { (handMinX + handMaxX) / 2 }
    /// Centre y of a card in the hand on your turn: the whole card shows, its corner gems clear of the edge.
    var baseY: CGFloat { size.height - 8 - cardH / 2 }
    /// Centre y of a resting card (not your turn): three tenths hang below the edge.
    var restY: CGFloat { size.height + sink - 8 - cardH / 2 }
    var cornerScale: CGFloat { 0.42 }
    /// Where drawn cards come from: the deck pile behind the status column.
    var corner: CGPoint { CGPoint(x: size.width - 34, y: size.height - 40) }
    /// A lifted card rises this much out of the fan.
    var lift: CGFloat { 14 }
}

struct DuelView: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm

    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        return AnyView(HStack(spacing: 0) {
            LeftColumn(hm: hm).frame(width: hm.leftW)
            // Middle: enemy strip, the two boards, the hand zone with your hero. The target prompt floats over
            // the gap between the boards instead of taking a line of its own.
            let vh = hm.size.height - 2 * hm.pad
            let boardH = (vh - hm.topH - hm.reserve - 3 * hm.gap) / 2
            VStack(spacing: hm.gap) {
                TopStrip(hm: hm).frame(height: hm.topH)
                BoardView(side: .e, minions: s.e.board, empty: tx.noEnemy)
                BoardView(side: .p, minions: s.p.board, empty: tx.playMinions)
                Color.clear.frame(height: hm.reserve)
            }
            .overlay { PromptPill().offset(y: hm.topH + hm.gap + boardH + hm.gap / 2 - vh / 2) }
            .overlay(alignment: .topLeading) {
                // Your hero, name above, with the hero power at the right shoulder. The column starts `pad`
                // below the duel area, so hm's y values shift by that much.
                let x = hm.heroX - hm.leftW, y = hm.heroY - hm.pad
                ZStack(alignment: .topLeading) {
                    HeroCluster(side: .p).position(x: x, y: y - 10)
                    LastingTokens(side: .p).position(x: x, y: y - 92)
                    PowerButton().position(x: x + 60, y: y - 30)
                    GemView(kind: .health, value: max(0, s.p.hp), size: 34).position(x: x + 60, y: y + 24)
                        .accessibilityLabel(Text("\(tx.healthShort) \(max(0, s.p.hp))"))
                    ArmorGem(n: s.p.armor).position(x: x + 92, y: y + 22)
                }
                .frame(width: hm.size.width - hm.leftW - hm.rightW, height: vh)
            }
            RightColumn(hm: hm).frame(width: hm.rightW)
        })
    }
}

/// Floating pill between the boards: the opponent's turn, something being targeted (with a cancel button) or
/// a playable card lifted. Plays are not narrated here; the battle log has them.
private struct PromptPill: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        let liftedPlayable: Bool = {
            guard let i = vm.hsel, vm.pending == nil, vm.handActive, !vm.busy, let k = s.p.hand[safe: i] else { return false }
            return s.canPay(.p, k)
        }()
        let foeTurn = s.turn == .e && !s.over && !s.mulligan
        let shown = vm.pending != nil || liftedPlayable || foeTurn
        return AnyView(Group {
            if shown {
                HStack(spacing: 10) {
                    if vm.pending != nil {
                        Text(tx.chooseTarget(vm.pendingLabel())).font(Theme.body(12.5, .semibold)).foregroundStyle(Theme.parch)
                        Button(tx.cancel) { vm.cancelPending() }.ghost(compact: true)
                    } else if liftedPlayable {
                        let targeted = vm.hsel.flatMap { s.p.hand[safe: $0] }.flatMap(GameData.shared.card)?.isTargetedSpell == true
                        Text(targeted ? tx.dragTarget : tx.dragPlay).font(Theme.body(12.5, .semibold)).foregroundStyle(Theme.parch)
                    } else {
                        Circle().fill(Color(hex: "#f0a097")).frame(width: 6, height: 6)
                        Text(tx.foeTurn).font(Theme.body(11.5, .bold)).foregroundStyle(Color(hex: "#f0a097"))
                    }
                }
                .lineLimit(1).minimumScaleFactor(0.8)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Color.black.opacity(0.72), in: Capsule())
                .overlay(Capsule().stroke(foeTurn && vm.pending == nil && !liftedPlayable ? Color(hex: "#6d3a33") : Theme.gold.opacity(0.7), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityElement(children: .combine)
            }
        }
        .zIndex(5)
        .animation(.easeOut(duration: 0.15), value: shown))
    }
}

// MARK: - Top strip: enemy hero at the left, their hand backs in the middle, their counts at the right

private struct TopStrip: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        return AnyView(ZStack(alignment: .topLeading) {
            HStack {
                Spacer().frame(width: hm.handMinX - hm.leftW - 20)
                EnemyHandBacks(n: s.e.hand.count)
                Spacer()
                CountPill(hand: s.e.hand.count, deck: s.e.deck.count)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            HeroCluster(side: .e).position(x: hm.heroX - hm.leftW, y: 52)
            LastingTokens(side: .e).position(x: hm.heroX - hm.leftW, y: 130)
            GemView(kind: .health, value: max(0, s.e.hp), size: 34).position(x: hm.heroX - hm.leftW + 60, y: 44)
                .accessibilityLabel(Text("\(vm.tx.healthShort) \(max(0, s.e.hp))"))
            ArmorGem(n: s.e.armor).position(x: hm.heroX - hm.leftW + 92, y: 42)
        })
    }
}

/// The opponent's hand as a row of card backs.
private struct EnemyHandBacks: View {
    let n: Int
    var body: some View {
        HStack(spacing: -12) {
            ForEach(0..<n, id: \.self) { i in
                CardBack(width: 26).rotationEffect(.degrees(Double(i - n / 2) * 1.5))
            }
        }
        .padding(.top, 2)
        .animation(.spring(duration: 0.35), value: n)
        .accessibilityHidden(true)
    }
}

/// A face-down card.
struct CardBack: View {
    var width: CGFloat = 26
    var body: some View {
        let r = width * 0.14
        Image("card_back").resizable().scaledToFill()
            .frame(width: width, height: width * 1.4)
            .clipShape(RoundedRectangle(cornerRadius: r))
            .overlay(RoundedRectangle(cornerRadius: r).stroke(Color(hex: "#c9a455").opacity(0.9), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
    }
}

/// "Hand n · Deck m" in a small dark pill.
private struct CountPill: View {
    let hand: Int, deck: Int
    @Environment(GameVM.self) private var vm
    var body: some View {
        Text(vm.tx.handDeck(hand, deck)).font(Theme.body(11.5, .semibold)).foregroundStyle(Theme.muted).monospacedDigit().lineLimit(1)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Color.black.opacity(0.35), in: Capsule())
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }
}

/// Effects waiting off the board for a hero, apart from the status box: the Prayers on the altar for now, each a
/// round token of its art with the turns left; a tap opens the card with what is left.
private struct LastingTokens: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state, !s[side].altar.isEmpty else { return AnyView(EmptyView()) }
        let tx = vm.tx
        return AnyView(HStack(spacing: 8) {
            ForEach(Array(s[side].altar.enumerated()), id: \.offset) { _, a in
                Button { vm.zoomNote = tx.altarLeft(a.cd); vm.zoomCard = a.key } label: {
                    ArtThumb(key: a.key, width: 36, height: 36).clipShape(Circle())
                        .overlay(Circle().stroke(Color(hex: "#e8c35a"), lineWidth: 1.6))
                        .shadow(color: Color(hex: "#ffe9a0").opacity(0.55), radius: 5)
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(a.cd)").font(Theme.body(10, .heavy)).foregroundStyle(.white).monospacedDigit()
                                .frame(width: 17, height: 17).background(Color(hex: "#8a6a1a"), in: Circle())
                                .overlay(Circle().stroke(Color(hex: "#ffe9a0"), lineWidth: 1)).offset(x: 4, y: 4)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("\(tx.altarLbl): \(tx.cardName(a.key)), \(tx.altarLeft(a.cd))"))
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(Color.black.opacity(0.35), in: Capsule()))
    }
}

/// Portrait. The name label is gone, but its room is kept so the portrait (and the gems placed beside it) stay put;
/// VoiceOver still reads the name from the portrait.
private struct HeroCluster: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        let name = Text(vm.heroName(side)).font(Theme.body(11, .bold)).lineLimit(1)
            .padding(.horizontal, 8).padding(.vertical, 2).hidden().accessibilityHidden(true)
        VStack(spacing: 3) {
            if side == .p { name }
            HeroFace(side: side, size: 80)
            if side == .e { name }
        }
    }
}

// MARK: - Left column: menu, battle log, your counts

private struct LeftColumn: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        return AnyView(VStack(spacing: 10) {
            if s.mode == .online {
                if !s.over {
                    SideButton(system: "flag.fill", text: vm.o.concedeArm ? tx.concedeSure : nil, danger: vm.o.concedeArm, label: tx.concede) { vm.concede() }
                }
            } else {
                SideButton(system: "line.3.horizontal", text: vm.quitArm ? tx.quitSure : nil, danger: vm.quitArm, label: tx.quitAria) { vm.quitDuel() }
            }
            Spacer()
            SideButton(system: "doc.text.fill", text: nil, danger: false, label: tx.battleLog) { vm.showLog = true }
                .overlay(alignment: .topTrailing) {
                    if let last = vm.hist.last, last.side == .e, last.round == s.round, s.turn == .p {
                        Circle().fill(Theme.blood).frame(width: 9, height: 9).offset(x: 2, y: -2)
                    }
                }
            if s.p.hasTalents || s.e.hasTalents {
                SideButton(system: "sparkles", text: nil, danger: false, label: tx.talents) { vm.showTalentPanel = true }
            }
            Spacer()
            CountPill(hand: s.p.hand.count, deck: s.p.deck.count).fixedSize()
                .frame(width: hm.leftW + 60, alignment: .leading)
                .frame(width: hm.leftW, alignment: .leading)
        }
        .padding(.vertical, 2))
    }
}

/// Square icon button on the left edge; shows a short text instead while an action is armed.
private struct SideButton: View {
    let system: String
    let text: String?
    let danger: Bool
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if let text { Text(text).font(Theme.body(10, .heavy)).lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center) }
                else { Image(systemName: system).font(.system(size: 16, weight: .bold)) }
            }
            .foregroundStyle(danger ? Color(hex: "#f0a097") : Color(hex: "#9fc4ee"))
            .frame(width: 42, height: 38)
            .background(LinearGradient(colors: [Color(hex: "#1e2a44"), Color(hex: "#111726")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(danger ? Theme.blood : Color(hex: "#4a6a9a"), lineWidth: 1.2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

// MARK: - Right column: enemy status, end turn, your status, deck piles

private struct RightColumn: View {
    let hm: HandMetrics
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        return AnyView(VStack(spacing: 8) {
            StatusBox(side: .e).padding(.top, 2)
            Spacer()
            EndTurnButton()
            Spacer()
            StatusBox(side: .p)
        }
        .padding(.horizontal, 4)
        .background(alignment: .topTrailing) { DeckPile(n: s.e.deck.count).offset(x: -4, y: -6) }
        .background(alignment: .bottomTrailing) { DeckPile(n: s.p.deck.count).offset(x: -4, y: 8) }
        .padding(.vertical, 2))
    }
}

/// A hero's numbers in one box: banked spell mana, then mana as
/// "x / max" over a row of ten crystals. The enemy's box is tinted red, yours blue; the acting hero's box glows.
private struct StatusBox: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let h = s[side], tx = vm.tx, foe = side == .e
        let acting = s.turn == side && !s.over
        let label = foe ? Color(hex: "#f0a097") : Color(hex: "#9fc4ee")
        return AnyView(VStack(alignment: .leading, spacing: 5) {
            // Health and Armor sit beside the portrait; here: banked spell mana, then mana.
            if h.spellMana > 0 {
                HStack(spacing: 4) {
                    HStack(spacing: 3) {
                        ForEach(0..<min(6, h.spellMana), id: \.self) { _ in
                            Rectangle().fill(Color(hex: "#a77be8")).overlay(Rectangle().stroke(Color(hex: "#d2b8ff"), lineWidth: 1))
                                .frame(width: 7, height: 7).rotationEffect(.degrees(45))
                        }
                    }
                    .padding(.horizontal, 2)
                    Text(tx.spellManaShort).font(Theme.body(8, .bold)).foregroundStyle(Color(hex: "#d2b8ff"))
                }
                .frame(height: 16)
                .lineLimit(1).minimumScaleFactor(0.7)
            }
            ManaBox(side: side)
            // Class resource counters. Lasting effects (the altar) sit by the hero portrait instead (LastingTokens).
            let counters: [String] = [
                s.isCls(side, "warrior") ? tx.rage(h.rage) : nil,
                s.isCls(side, "warlock") ? tx.souls(h.soul) : nil,
                s.isCls(side, "priest") ? tx.light(h.light) : nil,
                s.isCls(side, "hunter") ? tx.fero(h.fero) : nil,
                s.isCls(side, "paladin") ? tx.prestige(h.pres) : nil,
                h.rites > 0 ? tx.rites(h.rites) : nil,
            ].compactMap { $0 }
            if !counters.isEmpty {
                Text(counters.joined(separator: " · ")).font(Theme.body(8.5, .bold)).foregroundStyle(Theme.gold).lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: foe ? "#2a1c22" : "#1c2a3a"), Color(hex: foe ? "#160c10" : "#0e1620")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(acting ? Theme.gold : (foe ? Color(hex: "#6d3a33") : Color(hex: "#4a6a9a")), lineWidth: 1.2))
        .shadow(color: Theme.gold.opacity(acting ? 0.45 : 0), radius: acting ? 8 : 0)
        .animation(.easeOut(duration: 0.25), value: acting)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(vm.heroName(side)), \(max(0, h.hp)), \(tx.armor) \(h.armor), \(tx.spellManaShort) \(h.spellMana), " + tx.mana(h.mana, h.maxMana))))
    }
}

/// The hero's Armor: a silver gem beside the Health shield, shown while there is any.
private struct ArmorGem: View {
    let n: Int
    @Environment(GameVM.self) private var vm
    var body: some View {
        if n > 0 {
            StatGem(value: n, colors: [Color(hex: "#e4e8f0"), Color(hex: "#7a8090")], label: vm.tx.armor, scale: 1.1, dark: true)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

/// A few card backs fanned out behind the column: the deck.
private struct DeckPile: View {
    let n: Int
    var body: some View {
        ZStack {
            ForEach(0..<min(3, max(n > 0 ? 1 : 0, (n + 9) / 10)), id: \.self) { i in
                CardBack(width: 40).rotationEffect(.degrees(Double(i) * 6 - 6)).offset(x: CGFloat(i) * 3, y: CGFloat(-i) * 2)
            }
        }
        .opacity(0.9)
        .accessibilityHidden(true)
    }
}

/// Mana as "x / max" with a row of ten crystals (inside a StatusBox).
private struct ManaBox: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let h = s[side], tx = vm.tx, foe = side == .e
        let label = foe ? Color(hex: "#f0a097") : Color(hex: "#9fc4ee")
        return AnyView(VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(tx.manaShort).font(Theme.body(9, .bold)).tracking(1).foregroundStyle(label).textCase(.uppercase)
                Text("\(h.mana)").font(Theme.body(15, .heavy)).foregroundStyle(.white).monospacedDigit()
                Text("/\(h.maxMana)").font(Theme.body(9, .bold)).foregroundStyle(label).monospacedDigit()
            }
            HStack(spacing: 2.5) {
                ForEach(0..<10, id: \.self) { i in
                    Circle().fill(i < h.mana ? Color(hex: "#5ad0ff") : i < h.maxMana ? Color(hex: "#2a4a6a") : Color(hex: "#1a2230"))
                        .overlay(Circle().stroke(i < h.maxMana ? Color(hex: "#7fa6d8") : Color(hex: "#2e3a4e"), lineWidth: 0.8))
                        .frame(width: 7, height: 7)
                        .shadow(color: i < h.mana ? Color(hex: "#5ad0ff").opacity(0.8) : .clear, radius: 2)
                }
            }
        }
        .accessibilityHidden(true))
    }
}

/// The big round End Turn button; grey on the enemy's turn, glowing when nothing is left to do.
private struct EndTurnButton: View {
    @Environment(GameVM.self) private var vm
    @State private var glow = false
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let myTurn = s.turn == .p && !vm.busy && !s.over
        let nudge = myTurn && !vm.hasMoves()
        return AnyView(Button { vm.endTurn() } label: {
            Text(vm.tx.endTurn).font(Theme.display(15, cjk: vm.lang.isCJK)).foregroundStyle(.white)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                .frame(width: 74, height: 74)
                .background(RadialGradient(colors: [Color(hex: "#5ad0ff"), Color(hex: "#1f5fa0"), Color(hex: "#123560")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 40), in: Circle())
                // The painted ring (its opening is 72.5% of the image) sits round the button, star medallion on top.
                .overlay(Image("frame_endturn").resizable().frame(width: 74 / 0.725, height: 74 / 0.725).allowsHitTesting(false))
                .shadow(color: nudge && glow ? Color(hex: "#7fe0ff").opacity(0.95) : .black.opacity(0.5), radius: nudge && glow ? 14 : 3, y: nudge && glow ? 0 : 2)
        }
        .buttonStyle(.plain)
        .disabled(!myTurn)
        .saturation(myTurn ? 1 : 0.1).brightness(myTurn ? 0 : -0.3)
        .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever()) { glow = true } }
        .accessibilityLabel(Text(vm.tx.endTurn)))
    }
}

/// Your hero power: a round orange button at your hero's shoulder with the cost on its rim and the name under
/// it. Tap to use; a targeted power can be dragged onto its target. Grey while it cannot be used.
private struct PowerButton: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let power = s.p.power, tx = vm.tx
        let enabled = !vm.powerBlocked
        let dragging = vm.drag?.src == .power
        return AnyView(VStack(spacing: 3) {
            ZStack {
                Circle().fill(RadialGradient(colors: enabled ? [Color(hex: "#f6a35a"), Color(hex: "#d8601e"), Color(hex: "#8a3212")] : [Color(hex: "#6a5a50"), Color(hex: "#4a3a32"), Color(hex: "#2a1e18")],
                                             center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 26))
                Image(systemName: "sparkles").font(.system(size: 20, weight: .bold)).foregroundStyle(enabled ? Color(hex: "#fff4dc") : Color(hex: "#c8bca8"))
            }
            .frame(width: 46, height: 46)
            .overlay(Circle().stroke(enabled ? Color(hex: "#f3c97a") : Color(hex: "#7a6a4a"), lineWidth: 2))
            .shadow(color: enabled ? Color(hex: "#f3c97a").opacity(dragging ? 0.95 : 0.5) : .clear, radius: dragging ? 14 : 8)
            .shadow(color: .black.opacity(0.6), radius: 3, y: 2)
            .overlay(alignment: .topLeading) {
                Text("\(s.pcost(.p))").font(Theme.body(10, .heavy)).foregroundStyle(enabled ? .white : Color(hex: "#c8d0dc"))
                    .frame(width: 18, height: 18)
                    .background(enabled ? Theme.mana : Color(hex: "#2a3a50"), in: Circle())
                    .overlay(Circle().stroke(enabled ? Color(hex: "#bfe0fa") : Color(hex: "#6a7a90"), lineWidth: 1))
                    .offset(x: -8, y: -6)
            }
            .scaleEffect(dragging ? 1.08 : 1)
            .reportFrame { vm.powerFrame = $0 }
            .contentShape(Circle())
            .pressDrag(onTap: { vm.usePower() }, onDrag: { vm.dragPower(to: $0) }, onDrop: { _ in vm.dropPower() })
            Text(tx.powerName(power)).font(Theme.body(9, .bold)).foregroundStyle(enabled ? Theme.gold : Color(hex: "#9a8a6a"))
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal, 6).frame(height: 15)
                .background(Color.black.opacity(0.55), in: Capsule())
                .allowsHitTesting(false)
        }
        .opacity(enabled ? 1 : 0.75)
        .animation(.spring(duration: 0.2), value: dragging)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(tx.heroPower) \(tx.powerName(power)), \(s.pcost(.p)): \(tx.powerDesc(power))"))
        .accessibilityAddTraits(.isButton))
    }
}

// MARK: - Boards

struct BoardView: View {
    let side: Side
    let minions: [Minion]
    let empty: String
    @Environment(GameVM.self) private var vm
    var body: some View {
        let glow = side == .p && vm.dropGlow
        HStack(spacing: 8) {
            if minions.isEmpty {
                // No hint text: an empty row stays empty so the hand below can have the room.
                Color.clear.frame(width: 1, height: 1).accessibilityLabel(Text(empty))
            }
            ForEach(minions) { m in
                MinionView(m: m)
                    .transition(.asymmetric(insertion: .scale(scale: 0.4).combined(with: .offset(y: -36)).combined(with: .opacity),
                                            removal: .scale(scale: 0.55).combined(with: .offset(y: 22)).combined(with: .opacity)))
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.35), value: minions.map(\.uid))
        .frame(maxWidth: .infinity, minHeight: 63, maxHeight: .infinity)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.ready.opacity(glow ? 0.12 : 0)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ready.opacity(glow ? 0.9 : 0), lineWidth: 2))
        .shadow(color: Theme.ready.opacity(glow ? 0.5 : 0), radius: glow ? 10 : 0)
        .animation(.easeOut(duration: 0.18), value: glow)
        .reportFrame { vm.boardFrames[side] = $0 }
    }
}

// MARK: - Battle log

/// Every play of the game, one round per page: your plays on the left, the foe's on the right. Arrows and
/// round chips page through; nothing scrolls. Tap an entry to see the card.
struct LogView: View {
    @Environment(GameVM.self) private var vm
    @State private var shown: Int? = nil
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx
        let rounds = Array(Set(vm.hist.map(\.round))).sorted()
        let cur = shown.flatMap { rounds.contains($0) ? $0 : nil } ?? rounds.last ?? 0
        let idx = rounds.firstIndex(of: cur) ?? 0
        let mine = vm.hist.filter { $0.round == cur && $0.side == .p }, theirs = vm.hist.filter { $0.round == cur && $0.side == .e }
        let perCol = 5
        return AnyView(ZStack {
            Color(hex: "#0a080c").opacity(0.7).ignoresSafeArea().contentShape(Rectangle()).onTapGesture { vm.showLog = false }
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text(tx.battleLog).font(Theme.display(18, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                    Spacer()
                    if !rounds.isEmpty {
                        Button { shown = rounds[max(0, idx - 1)] } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .heavy)).frame(width: 30, height: 28) }
                            .ghost(compact: true).disabled(idx == 0).opacity(idx == 0 ? 0.4 : 1)
                        ForEach(rounds.suffix(from: max(0, min(idx - 2, rounds.count - 5))).prefix(5), id: \.self) { r in
                            Button(tx.roundN(r + 1)) { shown = r }.buttonStyle(PrimaryButtonStyle(ghost: r != cur, compact: true))
                        }
                        Button { shown = rounds[min(rounds.count - 1, idx + 1)] } label: { Image(systemName: "chevron.right").font(.system(size: 14, weight: .heavy)).frame(width: 30, height: 28) }
                            .ghost(compact: true).disabled(idx >= rounds.count - 1).opacity(idx >= rounds.count - 1 ? 0.4 : 1)
                    }
                    Button { vm.showLog = false } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.parch).frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain).accessibilityLabel(Text(tx.back))
                }
                .padding(.horizontal, 14).padding(.top, 8).padding(.bottom, 6)
                Rectangle().fill(Theme.gold.opacity(0.5)).frame(height: 1).padding(.horizontal, 12)
                if rounds.isEmpty {
                    Text(tx.logEmpty).font(Theme.body(13)).foregroundStyle(Theme.muted).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach([(Side.p, mine), (Side.e, theirs)], id: \.0) { side, items in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(vm.heroName(side)).font(Theme.body(11, .heavy)).tracking(1).foregroundStyle(side == .p ? Color(hex: "#9fc4ee") : Color(hex: "#f0a097"))
                                if items.isEmpty { Text("—").font(Theme.body(12)).foregroundStyle(Theme.muted) }
                                ForEach(items.prefix(perCol)) { h in LogPlayRow(h: h) }
                                if items.count > perCol { Text("+\(items.count - perCol)").font(Theme.body(11)).foregroundStyle(Theme.muted) }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                }
            }
            .frame(maxWidth: 720, maxHeight: .infinity)
            .background(LinearGradient(colors: [Color(hex: "#1c2434"), Color(hex: "#0f1420")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#4a6a9a"), lineWidth: 1.5))
            .padding(.vertical, 12)
            .shadow(color: .black.opacity(0.7), radius: 16)
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
        .zIndex(40)
        .accessibilityAddTraits(.isModal)
        .onChange(of: s.round) { _, _ in vm.showLog = false })
    }
}

/// One play in the battle log: coloured stripe, card picture, "<hero> played <card>", target.
private struct LogPlayRow: View {
    let h: HistItem
    @Environment(GameVM.self) private var vm
    var body: some View {
        let foe = h.side == .e, tx = vm.tx
        Button { vm.peekItem = h } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(foe ? Theme.blood : Color(hex: "#5ad0ff")).frame(width: 4)
                ZStack {
                    RadialGradient(colors: foe ? [Color(hex: "#4a2a2a"), Color(hex: "#1a0c0c")] : [Color(hex: "#3a3046"), Color(hex: "#17121c")], center: .center, startRadius: 0, endRadius: 24)
                    ArtThumb(key: h.key, width: 44, height: 32)
                }
                .frame(width: 44, height: 32).clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.cardName(h.key)).font(Theme.body(12.5, .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
                    if let t = h.target { Text(tx.target(vm.name(t))).font(Theme.body(11.5)).foregroundStyle(Theme.muted).lineLimit(1) }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4).padding(.horizontal, 6)
            .background(LinearGradient(colors: [foe ? Color(hex: "#3a1c1c") : Color(hex: "#1c2e44"), Color.clear], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(foe ? Color(hex: "#6d3a33") : Color(hex: "#3a5a8a"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Shadowverse-style card description, top left: cost, name, type, stats and rules text of the lifted hand card
/// or the held board minion.
struct CardInfoPanel: View {
    let card: Card
    let hm: HandMetrics
    var ovr: CardOverride? = nil
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, cjk = vm.lang.isCJK
        let typ = [card.isMinion ? tx.race(card.race ?? "") : nil, card.cls == nil ? nil : card.classes.map(tx.className).joined(separator: "/")].compactMap { $0 }.joined(separator: " · ")
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text("\(ovr?.cost ?? card.cost)").font(Theme.body(14, .heavy)).foregroundStyle((ovr?.cost ?? card.cost) < card.cost ? Theme.ready : .white)
                    .frame(width: 28, height: 28)
                    .background(RadialGradient(colors: [Color(hex: "#7cb8ee"), Theme.mana], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 18), in: Hexagon())
                    .overlay(Hexagon().stroke(Color(hex: "#bfe0fa"), lineWidth: 1))
                Text(tx.name(card.names)).font(Theme.display(16, cjk: cjk)).foregroundStyle(Theme.parch).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if card.isMinion {
                    let au = ovr?.atkUp ?? 0, hu = ovr?.hpUp ?? 0
                    GemView(kind: .attack, value: (card.atk ?? 0) + au, size: 24, numberColor: au > 0 ? Theme.ready : nil)
                    GemView(kind: .health, value: (card.hp ?? 0) + hu, size: 24, numberColor: hu > 0 ? Theme.ready : nil)
                }
            }
            if !typ.isEmpty {
                Text(typ).font(Theme.body(10.5, .semibold)).tracking(0.5).foregroundStyle(Color(hex: "#9fc4ee")).textCase(.uppercase)
                    .padding(.horizontal, 6).padding(.vertical, 1).overlay(Capsule().stroke(Color(hex: "#4a6a9a"), lineWidth: 1))
            }
            RichText(text: tx.cardText(card, ovr: ovr), keywords: tx.keywords, font: Theme.body(12.5), color: Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(tx.name(card.flavor)).font(Theme.body(11)).italic().foregroundStyle(Theme.muted).lineLimit(2)
        }
        .padding(10)
        .frame(width: min(270, hm.size.width * 0.34), alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: "#1c2a44"), Color(hex: "#0d1320")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.gold.opacity(0.8), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.7), radius: 10, y: 4)
        .allowsHitTesting(false)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
}

/// Opening hand: tap cards to replace them, then confirm (online: wait for the opponent).
/// Graveyard Summoner: the dead on offer; tap `n`, then take them. Blood Rite: the Legendaries; pick one to copy.
struct ChoiceView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let c = vm.choice else { return AnyView(EmptyView()) }
        let tx = vm.tx, n = max(1, c.offer.count)
        let two = c.rite && (vm.state?.p.rites ?? 0) >= DuelState.riteNeed
        let title = c.rite ? tx.riteTitle : tx.chooseTitle(c.n), sub = c.rite ? tx.riteSub(two ? 2 : 1) : tx.chooseSub, ok = c.rite ? tx.riteOk : tx.chooseOk
        return AnyView(GeometryReader { g in
            let em = max(6, min(10.8, (g.size.height - 170) / (15.6 + CardSlot.top + CardSlot.bottom), (g.size.width - 40) / (CGFloat(n) * 10 + CGFloat(n - 1) * CardSlot.hGap + CardSlot.leading + CardSlot.trailing)))
            VStack(spacing: 10) {
                Text(title).font(Theme.display(22, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                Text(sub).font(Theme.body(12.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 440)
                HStack(spacing: CardSlot.hGap * em) {
                    ForEach(Array(c.offer.enumerated()), id: \.offset) { i, k in
                        if let card = GameData.shared.card(k) {
                            let on = c.picks.contains(i)
                            CardView(card: card, size: .fit(em), ring: on ? Theme.ready : .clear)
                                .offset(y: on ? -8 : 0)
                                .contentShape(Rectangle())
                                .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { vm.toggleChoice(i) } }
                                .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                }
                .cardRow(em)
                Button("\(ok) \(c.picks.count)/\(c.n)") { vm.confirmChoice() }.primary().disabled(c.picks.count != c.n).opacity(c.picks.count == c.n ? 1 : 0.5)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .background(Color.black.opacity(0.84).ignoresSafeArea())
        .transition(.opacity))
    }
}

struct MulliganView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let s = vm.state else { return AnyView(EmptyView()) }
        let tx = vm.tx, hand = s.p.hand, n = max(1, hand.count)
        return AnyView(GeometryReader { g in
            let em = max(6, min(10.8, (g.size.height - 170) / (15.6 + CardSlot.top + CardSlot.bottom), (g.size.width - 40) / (CGFloat(n) * 10 + CGFloat(n - 1) * CardSlot.hGap + CardSlot.leading + CardSlot.trailing)))
            VStack(spacing: 10) {
                Text(tx.mullTitle).font(Theme.display(22, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                Text(tx.mullSub).font(Theme.body(12.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 440)
                HStack(spacing: CardSlot.hGap * em) {
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
                .cardRow(em)
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
