import SwiftUI

/// The two talent pages of a class: tiers of nodes, lit when chosen, dim until the tier opens. Used in the deck
/// builder (12 points) and before each Adventure duel (the points earned so far).
struct TalentPanel: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        guard let c = vm.talentContext else { return AnyView(EmptyView()) }
        let gd = GameData.shared, tx = vm.tx, pages = gd.talentPages(c.cls)
        return AnyView(VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(tx.talPts(c.sel.count, c.budget)).font(Theme.body(13, .heavy)).monospacedDigit()
                    .foregroundStyle(c.sel.count == c.budget ? Theme.ready : Theme.parch)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .overlay(Capsule().stroke(c.sel.count == c.budget ? Theme.ready : Theme.line, lineWidth: 1.2))
                Spacer()
                ForEach(0..<2, id: \.self) { i in
                    if let pg = pages[safe: i] { Button(tx.name(pg.names)) { vm.talPreset(i) }.ghost(compact: true) }
                }
                Button(tx.talBalanced) { vm.talPreset(2) }.ghost(compact: true)
                Button(tx.talClear) { vm.talPreset(nil) }.ghost(compact: true)
            }
            HStack(alignment: .top, spacing: 10) {
                ForEach(pages) { pg in TalentPageView(page: pg, sel: c.sel, budget: c.budget) }
            }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(tx.name(page.names)).font(Theme.display(17, cjk: vm.lang.isCJK)).foregroundStyle(col)
                Spacer()
                Text("\(n)").font(Theme.body(13, .heavy)).foregroundStyle(col).monospacedDigit()
            }
            ForEach(Array(page.tiers.enumerated()), id: \.offset) { t, row in
                let open = gd.pointsBelow(sel, page, t) >= gd.talents.tierReq[t]
                VStack(alignment: .leading, spacing: 4) {
                    if !open { Text("🔒 " + tx.talNeed(gd.talents.tierReq[t])).font(Theme.body(10.5)).foregroundStyle(Theme.muted) }
                    HStack(alignment: .top, spacing: 6) {
                        ForEach(row) { nd in
                            let on = sel.contains(nd.id), ok = on || (open && sel.count < budget)
                            Button { vm.talClick(nd.id) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tx.name(nd.names)).font(Theme.body(12, .heavy)).foregroundStyle(on ? Color.white : Theme.parch).lineLimit(2)
                                    Text(tx.name(nd.desc)).font(Theme.body(10.5)).foregroundStyle(on ? Color.white.opacity(0.9) : Theme.muted).lineLimit(5).fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(on ? col.opacity(0.55) : Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(on ? col : (ok ? col.opacity(0.5) : Theme.line), lineWidth: on ? 1.6 : 1))
                                .opacity(ok ? 1 : 0.45)
                            }
                            .buttonStyle(.plain)
                            .disabled(!ok)
                            .accessibilityLabel(Text(tx.name(nd.names) + ". " + tx.name(nd.desc)))
                            .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                }
                .padding(.top, t == 3 ? 4 : 0)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 12).fill(col.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(col.opacity(0.35), lineWidth: 1))
    }
}

/// Adventure: distribute the points earned so far, then fight.
struct TalentScreen: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        VStack(spacing: 6) {
            NavRow(items: [("⌂ " + tx.toMenu, { vm.goMenu() })])
            RouteRow()
            Page(title: tx.talAdvTitle(vm.run.stage + 1), subtitle: tx.talAdvSub(GameData.shared.advPoints(vm.run.stage)), centered: false) {
                TalentPanel()
                Button(tx.talFight) { vm.startDuel() }.primary()
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
        HStack(alignment: .top, spacing: 12) {
            ForEach(Array(packs.enumerated()), id: \.offset) { i, p in
                let pg = gd.talentPages(vm.run.cls ?? "")[safe: i]
                let col = pg.map { Color(hex: $0.color) } ?? Theme.gold
                VStack(spacing: 8) {
                    if let pg { Text(tx.name(pg.names)).font(Theme.display(17, cjk: vm.lang.isCJK)).foregroundStyle(col) }
                    HStack(spacing: 8) {
                        ForEach(Array(p.cards.enumerated()), id: \.offset) { _, k in
                            if let c = gd.card(k) {
                                CardView(card: c, size: .md).onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = k }
                            }
                        }
                    }
                    Text(tx.talTeaches + " " + p.hint.compactMap { gd.talentNode($0).map { tx.name($0.names) } }.joined(separator: "、"))
                        .font(Theme.body(11.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    Button(tx.talTakePack(pg.map { tx.name($0.names) } ?? "")) { vm.pickPack(i) }.primary()
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(col.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(col.opacity(0.4), lineWidth: 1))
            }
        }
    }
}

/// Both sides' talents over the duel; tap outside or Close to dismiss.
struct TalentsOverlay: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { vm.showTalentPanel = false }
            VStack(spacing: 10) {
                ScrollView {
                    HStack(alignment: .top, spacing: 16) {
                        TalentList(side: .p).frame(maxWidth: .infinity, alignment: .topLeading)
                        TalentList(side: .e).frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .padding(14)
                }
                Button(vm.tx.closeLbl) { vm.showTalentPanel = false }.primary().padding(.bottom, 10)
            }
            .frame(maxWidth: 640, maxHeight: 360)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold.opacity(0.6), lineWidth: 1))
            .padding(20)
        }
        .transition(.opacity)
    }
}

/// The talents a side plays with, listed (duel info).
struct TalentList: View {
    let side: Side
    @Environment(GameVM.self) private var vm
    var body: some View {
        let gd = GameData.shared, tx = vm.tx
        let sel = vm.state?[side].tal ?? []
        VStack(alignment: .leading, spacing: 6) {
            Text(side == .p ? tx.talYours : tx.talFoes).font(Theme.display(18, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
            if sel.isEmpty { Text("—").foregroundStyle(Theme.muted) }
            ForEach(sel, id: \.self) { id in
                if let nd = gd.talentNode(id), let pg = gd.talentPage(of: id) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.name(nd.names)).font(Theme.body(12.5, .heavy)).foregroundStyle(Color(hex: pg.color))
                        Text(tx.name(nd.desc)).font(Theme.body(11.5)).foregroundStyle(Theme.ink)
                    }
                }
            }
        }
    }
}
