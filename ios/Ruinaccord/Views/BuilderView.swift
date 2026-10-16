import SwiftUI

/// Deck builder: name, mana curve, deck list, filters and the collection grid.
struct BuilderView: View {
    @Environment(GameVM.self) private var vm
    @FocusState private var nameFocused: Bool

    var body: some View {
        let tx = vm.tx, gd = GameData.shared
        guard let clsId = vm.q.cls, let cls = gd.cls(clsId) else { return AnyView(EmptyView()) }
        let d = vm.q.deck, need = Decks.size - d.count
        let order: (String) -> Int = { k in (gd.card(k)?.cost ?? 0) * 100 + ((gd.card(k)?.isMinion ?? true) ? 0 : 50) }
        let uniq = Array(Set(d)).sorted { order($0) != order($1) ? order($0) < order($1) : tx.cardName($0) < tx.cardName($1) }
        var buckets = [Int](repeating: 0, count: 8)
        for k in d { buckets[min(7, gd.card(k)?.cost ?? 0)] += 1 }
        let mx = max(4, buckets.max() ?? 4)
        let list = gd.collectible.filter { c in
            c.allowed(for: clsId) && (vm.q.typeFilter == "all" || c.type.rawValue == vm.q.typeFilter) && (vm.q.costFilter == 0 || (vm.q.costFilter == 7 ? c.cost >= 7 : c.cost == vm.q.costFilter))
        }.sorted { a, b in a.cost != b.cost ? a.cost < b.cost : (a.isMinion != b.isMinion ? a.isMinion : tx.name(a.names) < tx.name(b.names)) }
        let toOnline = vm.q.returnToOnline

        return AnyView(VStack(alignment: .leading, spacing: 10) {
            NavRow(items: [toOnline ? ("← " + tx.modeOnline, { vm.goOnline() }) : ("← " + tx.myDecks, { vm.goDecks() }), ("⌂ " + tx.toMenu, { vm.goMenu() })])
            HStack(spacing: 10) {
                Text(tx.deckTitle(tx.name(cls.names))).font(Theme.display(24, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch).lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                Text("\(d.count)/\(Decks.size)").font(Theme.body(13, .heavy)).monospacedDigit()
                    .foregroundStyle(need > 0 ? Theme.ember : Theme.ready)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .overlay(Capsule().stroke(need > 0 ? Theme.ember : Theme.ready, lineWidth: 1.5))
            }
            HStack(spacing: 8) {
                TextField(tx.deckName, text: Binding(get: { vm.q.name }, set: { vm.q.name = String($0.prefix(28)); vm.q.dirty = true }))
                    .focused($nameFocused)
                    .font(Theme.body(15, .semibold)).foregroundStyle(Theme.parch)
                    .padding(.horizontal, 11).padding(.vertical, 9)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                    .submitLabel(.done)
                Button(vm.q.dirty ? tx.saveDeck : "✓ " + tx.savedState) { nameFocused = false; vm.saveCurrent(asNew: false) }
                    .buttonStyle(PrimaryButtonStyle(ghost: !vm.q.dirty, compact: true))
                if vm.q.editId != nil { Button(tx.saveAsNew) { nameFocused = false; vm.saveAsNew() }.ghost(compact: true) }
            }
            Text("\(tx.deckRules(Decks.size)) \(tx.tapAdd)").font(Theme.body(12.5)).foregroundStyle(Theme.muted).lineSpacing(2)

            // Deck panel
            VStack(alignment: .leading, spacing: 8) {
                Text(tx.curve).font(Theme.body(12)).foregroundStyle(Theme.muted)
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<8, id: \.self) { i in
                        VStack(spacing: 2) {
                            UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2).fill(Theme.manaLight)
                                .frame(height: max(2, CGFloat(buckets[i]) / CGFloat(mx) * 46))
                            Text(i == 7 ? "7+" : "\(i)").font(Theme.body(10)).foregroundStyle(Theme.muted).monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 62, alignment: .bottom)
                .accessibilityLabel(Text(tx.curve))
                if uniq.isEmpty {
                    Text(tx.emptyDeck).font(Theme.body(12.5)).foregroundStyle(Theme.muted)
                } else {
                    ScrollView {
                        VStack(spacing: 3) {
                            ForEach(uniq, id: \.self) { k in
                                if let c = gd.card(k) {
                                    Button { vm.removeCard(k) } label: {
                                        HStack(spacing: 7) {
                                            Text("\(c.cost)").font(Theme.body(11, .heavy)).foregroundStyle(.white).frame(width: 20, height: 20).background(Theme.mana, in: Hexagon())
                                            Text(tx.name(c.names)).font(Theme.body(13)).foregroundStyle(Theme.ink).lineLimit(1)
                                            Spacer()
                                            Text("×\(Decks.copies(d, k))").font(Theme.body(13, .heavy)).foregroundStyle(Theme.gold).monospacedDigit()
                                        }
                                        .padding(.horizontal, 7).padding(.vertical, 4)
                                        .background(Color(hex: "#2c2432"), in: RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
                                        .overlay(alignment: .leading) { Rectangle().fill(Theme.rarityColor(c.rarity)).frame(width: 3).clipShape(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6)) }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text("\(tx.name(c.names)) ×\(Decks.copies(d, k))"))
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                }
                HStack(spacing: 6) {
                    Button(tx.autoFill) { vm.autoFill() }.ghost(compact: true).disabled(need == 0).opacity(need == 0 ? 0.45 : 1)
                    Button(tx.resetDeck) { vm.resetDeck() }.ghost(compact: true)
                    Button(tx.clearDeck) { vm.clearDeck() }.ghost(compact: true).disabled(d.isEmpty).opacity(d.isEmpty ? 0.45 : 1)
                }
            }
            .padding(10).panel()

            // Filters + collection
            FlowChips {
                ForEach([("all", tx.filterAll), ("m", tx.minions), ("s", tx.spells)], id: \.0) { v, t in Chip(text: t, on: vm.q.typeFilter == v) { vm.q.typeFilter = v } }
            }
            FlowChips {
                ForEach([(0, tx.filterAll), (1, "1"), (2, "2"), (3, "3"), (4, "4"), (5, "5"), (6, "6"), (7, "7+")], id: \.0) { v, t in Chip(text: t, on: vm.q.costFilter == v) { vm.q.costFilter = v } }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 8)], spacing: 12) {
                ForEach(list) { c in
                    let n = Decks.copies(d, c.id), full = n >= c.maxCopies || d.count >= Decks.size
                    Button { vm.addCard(c.id) } label: { CardView(card: c, size: .sm) }
                        .buttonStyle(.plain)
                        .saturation(full ? 0.3 : 1).brightness(full ? -0.25 : 0)
                        .disabled(full)
                        .overlay(alignment: .topTrailing) {
                            if n > 0 {
                                Text("\(n)/\(c.maxCopies)").font(Theme.body(11, .heavy)).foregroundStyle(Color(hex: "#10200f"))
                                    .padding(.horizontal, 5).frame(height: 20).background(Theme.ready, in: Capsule()).offset(x: 6, y: -6)
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = c.id }
                        .accessibilityLabel(Text("\(tx.name(c.names)), \(c.cost)"))
                }
            }
            .padding(.vertical, 6)
            .padding(.bottom, 70)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Text(vm.q.toast.isEmpty ? (vm.q.dirty && vm.q.editId != nil ? tx.unsaved : need > 0 ? tx.deckNeed(need) : tx.deckReady) : vm.q.toast)
                    .font(Theme.body(12.5)).foregroundStyle(Theme.ember).lineLimit(2)
                Spacer()
                if toOnline { Button(tx.useDeck) { vm.useDeckOnline() }.primary().disabled(need > 0).opacity(need > 0 ? 0.45 : 1) }
                else { Button(tx.nextDiff) { vm.toDifficulty() }.primary().disabled(need > 0).opacity(need > 0 ? 0.45 : 1) }
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
            .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.3)))
        })
    }
}
