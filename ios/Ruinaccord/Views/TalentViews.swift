import SwiftUI

/// The two talent pages of a class side by side, each tier a row of nodes: the whole tree fits one screen.
/// Used in the deck builder (12 points) and before each Adventure duel (the points earned so far).
struct TalentPanel: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let c = vm.talentContext else { return AnyView(EmptyView()) }
        let gd = GameData.shared, tx = vm.tx, pages = gd.talentPages(c.cls)
        return AnyView(VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(tx.talPts(c.sel.count, c.budget)).font(Theme.body(12, .heavy)).monospacedDigit()
                    .foregroundStyle(c.sel.count == c.budget ? Theme.ready : Theme.parch)
                    .padding(.horizontal, 10).frame(height: 26)
                    .overlay(Capsule().stroke(c.sel.count == c.budget ? Theme.ready : Theme.line, lineWidth: 1.2))
                Text(tx.talHint).font(Theme.body(11)).foregroundStyle(Theme.muted).lineLimit(1)
                Spacer()
                ForEach(0..<2, id: \.self) { i in
                    if let pg = pages[safe: i] { Button(tx.name(pg.names)) { vm.talPreset(i) }.ghost(compact: true) }
                }
                Button(tx.talBalanced) { vm.talPreset(2) }.ghost(compact: true)
                Button(tx.talClear) { vm.talPreset(nil) }.ghost(compact: true, danger: true)
            }
            HStack(alignment: .top, spacing: 10) {
                ForEach(pages) { pg in TalentPageView(page: pg, sel: c.sel, budget: c.budget) }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        })
    }
}

private struct TalentPageView: View {
    let page: TalentPage
    let sel: [String]
    let budget: Int
    @Environment(GameVM.self) private var vm
    var body: some View {
        let gd = GameData.shared, tx = vm.tx, col = Color(hex: page.color)
        let n = sel.filter { gd.talentPage(of: $0)?.id == page.id }.count
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(tx.name(page.names)).font(Theme.display(15, cjk: vm.lang.isCJK)).foregroundStyle(col)
                Spacer()
                Text("\(n)").font(Theme.body(13, .heavy)).foregroundStyle(col).monospacedDigit()
            }
            ForEach(Array(page.tiers.enumerated()), id: \.offset) { t, row in
                TalentTierRow(row: row, open: gd.tierOpen(sel, t), taken: gd.tierPick(sel, t) != nil, sel: sel, budget: budget, col: col)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#140e1c").opacity(0.8)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(col.opacity(0.4), lineWidth: 1))
    }
}

private struct TalentTierRow: View {
    let row: [TalentNode]
    let open: Bool
    let taken: Bool
    let sel: [String]
    let budget: Int
    let col: Color
    @Environment(GameVM.self) private var vm
    var body: some View {
        let room: Bool = open && !taken && sel.count < budget
        HStack(alignment: .top, spacing: 6) {
            ForEach(row) { nd in
                let on: Bool = sel.contains(nd.id)
                TalentNodeButton(nd: nd, on: on, ok: on || room, col: col)
            }
            if !open {
                Text("🔒 " + vm.tx.talNeed).font(Theme.body(9.5)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center).frame(width: 74).frame(minHeight: 50)
            }
        }
    }
}

private struct TalentNodeButton: View {
    let nd: TalentNode
    let on: Bool, ok: Bool
    let col: Color
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        Button { vm.talClick(nd.id) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.name(nd.names)).font(Theme.body(11.5, .heavy)).foregroundStyle(on ? Color.white : Theme.parch).lineLimit(1).minimumScaleFactor(0.8)
                Text(tx.name(nd.desc)).font(Theme.body(9.5)).foregroundStyle(on ? Color.white.opacity(0.9) : Theme.muted).lineLimit(3).minimumScaleFactor(0.85).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .topLeading)
            .padding(.horizontal, 7).padding(.vertical, 5)
            .background(on ? col.opacity(0.55) : Theme.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(on ? col : (ok ? col.opacity(0.5) : Theme.line), lineWidth: on ? 1.6 : 1))
            .opacity(ok ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!ok)
        .accessibilityLabel(Text(tx.name(nd.names) + ". " + tx.name(nd.desc)))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

/// Adventure: distribute the points earned so far, then fight.
struct TalentScreen: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: Scenes.forStage(vm.run.stage)) {
            VStack(spacing: 4) {
                BarRow(back: (tx.toMenu, { vm.goMenu() }), title: tx.talAdvTitle(vm.run.stage + 1), subtitle: tx.talAdvSub(GameData.shared.advPoints(vm.run.stage))) {
                    RouteRow()
                    Button(tx.talFight + " ›") { vm.startDuel() }.primary(compact: true, glow: true)
                }
                TalentPanel().padding(.horizontal, 10).padding(.bottom, 8)
            }
        }
    }
}

/// Quick play: the 12 points before the duel, kept on the deck.
struct QTalentScreen: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: "warfront") {
            VStack(spacing: 4) {
                // Back to the cards (or the deck list for a saved deck), on to the difficulty.
                let fromBuild = vm.q.talFrom == .build
                BarRow(back: fromBuild ? (tx.cardsTab, { vm.go(.build) }) : (tx.myDecks, { vm.goDecks() }), title: tx.qTalTitle, subtitle: tx.qTalSub) {
                    if !fromBuild { IconButton(symbol: "square.grid.2x2", label: tx.editDeck) { vm.q.talFrom = .build; vm.go(.build) } }
                    IconButton(symbol: "arrow.right", label: tx.nextDiff, primary: true) { vm.talentsNext() }
                }
                TalentPanel().padding(.horizontal, 10).padding(.bottom, 8)
            }
        }
    }
}

/// After an Adventure win: one pack per talent page, each naming the talents it goes with.
struct PackRow: View {
    let packs: [TalentPack]
    @Environment(GameVM.self) private var vm
    var body: some View {
        let gd = GameData.shared, tx = vm.tx
        HStack(alignment: .top, spacing: 14) {
            ForEach(Array(packs.enumerated()), id: \.offset) { i, p in
                let pg = gd.talentPages(vm.run.cls ?? "")[safe: i]
                let col = pg.map { Color(hex: $0.color) } ?? Theme.gold
                HStack(spacing: CardSlot.hGap * 9.6) {
                    ForEach(Array(p.cards.enumerated()), id: \.offset) { _, k in
                        if let c = gd.card(k) {
                            CardView(card: c, size: .fit(9.6)).onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = k }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        if let pg { Text(tx.name(pg.names)).font(Theme.display(17, cjk: vm.lang.isCJK)).foregroundStyle(col) }
                        Text(tx.talTeaches + " " + p.hint.compactMap { gd.talentNode($0).map { tx.name($0.names) } }.joined(separator: "、"))
                            .font(Theme.body(11.5)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Button(tx.talTakePack(pg.map { tx.name($0.names) } ?? "")) { vm.pickPack(i) }.primary(compact: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#140e1c").opacity(0.8)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(col.opacity(0.5), lineWidth: 1))
            }
        }
        .padding(.bottom, 10)
    }
}

/// Both sides' talents over the duel; tap outside or Close to dismiss.
struct TalentsOverlay: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { vm.showTalentPanel = false }
            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 16) {
                    TalentList(side: .p).frame(maxWidth: .infinity, alignment: .topLeading)
                    TalentList(side: .e).frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(14)
                HStack { Spacer(); Button(vm.tx.closeLbl) { vm.showTalentPanel = false }.primary(compact: true) }.padding(.horizontal, 14).padding(.bottom, 10)
            }
            .frame(maxWidth: 720)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold.opacity(0.6), lineWidth: 1))
            .padding(16)
        }
        .transition(.opacity)
    }
}

/// The talents a side plays with, as a compact grid (duel info).
struct TalentList: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        let gd = GameData.shared, tx = vm.tx
        let sel = vm.state?[side].tal ?? []
        VStack(alignment: .leading, spacing: 5) {
            Text(side == .p ? tx.talYours : tx.talFoes).font(Theme.display(15, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
            if sel.isEmpty { Text("—").foregroundStyle(Theme.muted) }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], alignment: .leading, spacing: 4) {
                ForEach(sel, id: \.self) { id in
                    if let nd = gd.talentNode(id), let pg = gd.talentPage(of: id) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(tx.name(nd.names)).font(Theme.body(11, .heavy)).foregroundStyle(Color(hex: pg.color)).lineLimit(1)
                            Text(tx.name(nd.desc)).font(Theme.body(9.5)).foregroundStyle(Theme.ink).lineLimit(2).minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
