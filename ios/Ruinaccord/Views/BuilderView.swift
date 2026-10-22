import SwiftUI

/// Deck builder, one screen: the bar (name, count, save, Cards / Talents tabs, next step), a filter row, the
/// collection paged two rows at a time on the left, the deck as a list on the right. Nothing scrolls.
struct BuilderView: View {
    @Environment(GameVM.self) private var vm
    @FocusState private var nameFocused: Bool

    var body: some View {
        let tx = vm.tx, gd = GameData.shared
        guard let clsId = vm.q.cls, let cls = gd.cls(clsId) else { return AnyView(EmptyView()) }
        let d = vm.q.deck, need = Decks.size - d.count
        let tt = gd.hasTalents(clsId)
        let toOnline = vm.q.returnToOnline
        let list = gd.collectible.filter { c in
            c.allowed(for: clsId) && (vm.q.typeFilter == "all" || (vm.q.typeFilter == "cls" ? c.cls != nil : c.type.rawValue == vm.q.typeFilter)) && (vm.q.costFilter == 0 || (vm.q.costFilter == 7 ? c.cost >= 7 : c.cost == vm.q.costFilter)) && (vm.q.rarityFilter == "all" || c.rarity == vm.q.rarityFilter)
        }.sorted { a, b in (a.cls != nil) != (b.cls != nil) ? a.cls != nil : a.cost != b.cost ? a.cost < b.cost : (a.isMinion != b.isMinion ? a.isMinion : tx.name(a.names) < tx.name(b.names)) }

        return AnyView(ScreenShell(scene: "dawn") {
            VStack(spacing: 2) {
                // bar
                HStack(spacing: 8) {
                    Button("‹ " + (toOnline ? tx.modeOnline : tx.myDecks)) { toOnline ? vm.goOnline() : vm.goDecks() }.ghost(compact: true)
                    TextField(tx.deckName, text: Binding(get: { vm.q.name }, set: { vm.q.name = String($0.prefix(28)); vm.q.dirty = true }))
                        .focused($nameFocused)
                        .font(Theme.body(13, .semibold)).foregroundStyle(Theme.parch)
                        .padding(.horizontal, 10).frame(minWidth: 90, maxWidth: 150).frame(height: 32)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                        .submitLabel(.done)
                    Text("\(d.count)/\(Decks.size)").font(Theme.body(12, .heavy)).monospacedDigit()
                        .foregroundStyle(need > 0 ? Theme.ember : Theme.ready)
                        .padding(.horizontal, 10).frame(height: 26)
                        .overlay(Capsule().stroke(need > 0 ? Theme.ember : Theme.ready, lineWidth: 1.5))
                    Button(vm.q.dirty ? tx.saveDeck : "✓ " + tx.savedState) { nameFocused = false; vm.saveCurrent(asNew: false) }
                        .buttonStyle(PrimaryButtonStyle(ghost: !vm.q.dirty, compact: true)).lineLimit(1)
                    if vm.q.editId != nil {
                        Button { nameFocused = false; vm.saveAsNew() } label: { Image(systemName: "doc.on.doc").font(.system(size: 13, weight: .bold)) }.ghost(compact: true)
                            .accessibilityLabel(Text(tx.saveAsNew))
                    }
                    if tt {
                        HStack(spacing: 0) {
                            Button(tx.cardsTab) { vm.q.showTalents = false }.buttonStyle(PrimaryButtonStyle(ghost: vm.q.showTalents, compact: true))
                            Button("✦ \(vm.q.tal.count)/\(gd.talents.maxPts)") { vm.q.showTalents = true }.buttonStyle(PrimaryButtonStyle(ghost: !vm.q.showTalents, compact: true))
                                .accessibilityLabel(Text(tx.talents))
                        }
                    }
                    Spacer(minLength: 4)
                    if !vm.q.toast.isEmpty { Text(vm.q.toast).font(Theme.body(11.5)).foregroundStyle(Theme.ember).lineLimit(1).minimumScaleFactor(0.7) }
                    if toOnline { IconButton(symbol: "checkmark", label: tx.useDeck, primary: true) { vm.useDeckOnline() }.disabled(need > 0).opacity(need > 0 ? 0.45 : 1) }
                    else { IconButton(symbol: "arrow.right", label: tx.nextDiff, primary: true) { vm.toDifficulty() }.disabled(need > 0).opacity(need > 0 ? 0.45 : 1) }
                }
                .frame(height: 44).padding(.horizontal, 10)

                if tt && vm.q.showTalents {
                    TalentPanel().padding(.horizontal, 10).padding(.bottom, 8)
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(spacing: 0) {
                            // filters
                            HStack(spacing: 3) {
                                Text(tx.costLbl).font(Theme.body(10.5)).foregroundStyle(Theme.muted)
                                Tag(text: tx.typeAll, on: vm.q.costFilter == 0) { vm.q.costFilter = 0 }
                                ForEach(1..<8, id: \.self) { n in Tag(text: n == 7 ? "7+" : "\(n)", on: vm.q.costFilter == n) { vm.q.costFilter = n } }
                                Tag(text: "0", on: false) { vm.q.costFilter = 0 }.hidden().frame(width: 0)
                                Rectangle().fill(Theme.line).frame(width: 1, height: 18).padding(.horizontal, 4)
                                Tag(text: tx.typeAll, on: vm.q.typeFilter == "all") { vm.q.typeFilter = "all" }
                                Tag(symbol: "person.fill", label: tx.minions, on: vm.q.typeFilter == "m") { vm.q.typeFilter = "m" }
                                Tag(symbol: "sparkles", label: tx.spells, on: vm.q.typeFilter == "s") { vm.q.typeFilter = "s" }
                                Tag(symbol: "shield.fill", label: tx.classCards, on: vm.q.typeFilter == "cls") { vm.q.typeFilter = "cls" }
                                Rectangle().fill(Theme.line).frame(width: 1, height: 18).padding(.horizontal, 4)
                                // Rarity: tap a gem to show only epics or legendaries, tap it again for all.
                                ForEach(["e", "l"], id: \.self) { r in
                                    RarityTag(r: r, on: vm.q.rarityFilter == r) { vm.q.rarityFilter = vm.q.rarityFilter == r ? "all" : r }
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(height: 30).padding(.leading, 10)
                            PagedGrid(items: list, cellWidth: CardSlot.width * 9.6, cellHeight: CardSlot.height * 9.6, rows: 2, hGap: 2, vGap: 2) { c, s in
                                let n = Decks.copies(d, c.id), full = n >= c.maxCopies
                                Button { vm.addCard(c.id) } label: {
                                    CardView(card: c, size: .fit(9.6 * s), ring: full ? .clear : Theme.gold.opacity(0.0), ovr: tt ? gd.overrides(for: vm.q.tal)[c.id] : nil)
                                        .saturation(full ? 0.3 : 1).opacity(full ? 0.55 : 1)
                                        .overlay(alignment: .topTrailing) {
                                            if n > 0 {
                                                Text("\(n)/\(c.maxCopies)").font(Theme.body(10.5, .heavy)).foregroundStyle(Color(hex: "#10200f"))
                                                    .padding(.horizontal, 6).frame(height: 20).background(Theme.ready, in: Capsule()).offset(x: 6, y: -6)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .disabled(full)
                                .cardSlot(9.6 * s)
                                .onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = c.id }
                                .accessibilityLabel(Text("\(tx.name(c.names)), \(c.cost)"))
                            }
                        }
                        DeckList(deck: d, cls: cls)
                            .frame(width: 176)
                            .padding(.trailing, 8).padding(.bottom, 8)
                    }
                }
            }
        })
    }
}

/// The deck as a list with its mana curve: tap a row to remove one copy.
struct DeckList: View {
    let deck: [String]
    let cls: HeroClass
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, gd = GameData.shared
        let order: (String) -> Int = { k in (gd.card(k)?.cost ?? 0) * 100 + ((gd.card(k)?.isMinion ?? true) ? 0 : 50) }
        let uniq = Array(Set(deck)).sorted { order($0) != order($1) ? order($0) < order($1) : tx.cardName($0) < tx.cardName($1) }
        let buckets = deck.reduce(into: [Int](repeating: 0, count: 8)) { $0[min(7, gd.card($1)?.cost ?? 0)] += 1 }
        let mx = max(4, buckets.max() ?? 4)
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<8, id: \.self) { i in
                    VStack(spacing: 1) {
                        UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2).fill(Theme.manaLight)
                            .frame(height: max(2, CGFloat(buckets[i]) / CGFloat(mx) * 30))
                        Text(i == 7 ? "7+" : "\(i)").font(Theme.body(8)).foregroundStyle(Theme.muted).monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 44, alignment: .bottom)
            .accessibilityLabel(Text(tx.curve))
            if uniq.isEmpty {
                Text(tx.emptyDeck).font(Theme.body(11)).foregroundStyle(Theme.muted).padding(.top, 6)
            }
            // The rows scroll inside the panel: a deck of many distinct cards is taller than the
            // column, and the curve above and the buttons below must stay where they are.
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(uniq, id: \.self) { k in
                        if let c = gd.card(k) {
                            Button { vm.removeCard(k) } label: {
                                HStack(spacing: 5) {
                                    Text("\(c.cost)").font(Theme.body(9, .heavy)).foregroundStyle(.white).frame(width: 14, height: 14).background(Theme.mana, in: Hexagon())
                                    Text(tx.name(c.names)).font(Theme.body(10.5, .semibold)).foregroundStyle(c.isLegendary ? Theme.gold : Theme.ink).lineLimit(1)
                                    Spacer(minLength: 2)
                                    Text("×\(Decks.copies(deck, k))").font(Theme.body(9.5, .heavy)).foregroundStyle(Theme.gold).monospacedDigit()
                                }
                                .padding(.horizontal, 4).frame(height: 15)
                                .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("\(tx.name(c.names)) ×\(Decks.copies(deck, k))"))
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            HStack(spacing: 6) {
                IconButton(symbol: "wand.and.stars", label: tx.autoFill) { vm.autoFill() }.frame(maxWidth: .infinity)
                IconButton(symbol: "arrow.counterclockwise", label: tx.resetDeck) { vm.resetDeck() }.frame(maxWidth: .infinity)
                IconButton(symbol: "trash", label: tx.clearDeck, danger: true) { vm.clearDeck() }.frame(maxWidth: .infinity)
            }
        }
        .padding(8)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}

/// A filter tag that is only the rarity gem: lit and ringed in gold while it is on.
private struct RarityTag: View {
    let r: String
    let on: Bool
    let action: () -> Void
    @Environment(GameVM.self) private var vm
    var body: some View {
        Button(action: action) {
            Rectangle().fill(Theme.rarityColor(r)).frame(width: on ? 11 : 9, height: on ? 11 : 9)
                .overlay(Rectangle().stroke(Color.black.opacity(0.6), lineWidth: 1)).rotationEffect(.degrees(45))
                .shadow(color: on || r == "l" ? Theme.rarityColor(r) : .clear, radius: on ? 5 : 3)
                .opacity(on ? 1 : 0.75)
            .frame(minWidth: 26).frame(height: 26).padding(.horizontal, 5)
            .background(on ? Theme.gold.opacity(0.2) : Theme.panel, in: Capsule())
            .overlay(Capsule().stroke(on ? Theme.gold : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(vm.tx.rarity(r)))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}
