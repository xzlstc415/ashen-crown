import SwiftUI

/// Centered page with a serif title and muted subtitle.
struct Page<Content: View>: View {
    var title: String
    var subtitle: String? = nil
    var centered = true
    @ViewBuilder var content: Content
    @Environment(GameVM.self) private var vm
    var body: some View {
        VStack(spacing: 16) {
            if centered { Spacer(minLength: 0) }
            Text(title).font(Theme.display(30, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch).multilineTextAlignment(.center)
            if let subtitle { Text(subtitle).font(Theme.body(15)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 420) }
            content
            if centered { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, minHeight: centered ? 420 : 0)
        .padding(.vertical, 20)
        .transition(.opacity.combined(with: .offset(y: 10)))
    }
}

struct NavRow: View {
    var items: [(String, () -> Void)]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                Button(it.0, action: it.1).ghost(compact: true)
            }
            Spacer()
        }
        .padding(.top, 6)
    }
}

struct ModeButton: View {
    let title: String, sub: String, color: Color
    let action: () -> Void
    @Environment(GameVM.self) private var vm
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.display(20, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                Text(sub).font(Theme.body(13)).foregroundStyle(Theme.muted).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            .overlay(alignment: .leading) { Rectangle().fill(color).frame(width: 4).clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 12)) }
        }
        .buttonStyle(.plain)
        .multilineTextAlignment(.leading)
    }
}

// MARK: - Intro

struct IntroView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        Page(title: tx.introTitle) {
            // Fan of cards
            ZStack {
                ForEach(Array(["crab", "firelem", "leviathan", "maelstrom", "elfqueen"].enumerated()), id: \.offset) { i, k in
                    if let c = GameData.shared.card(k) {
                        CardView(card: c, size: .sm)
                            .rotationEffect(.degrees(Double(i - 2) * 9), anchor: UnitPoint(x: 0.5, y: 1.4))
                            .offset(x: CGFloat(i - 2) * 62)
                    }
                }
            }
            .frame(maxWidth: .infinity).frame(height: 165).padding(.top, 6).clipped()
            .accessibilityHidden(true)
            VStack(spacing: 10) {
                ModeButton(title: tx.modeCamp, sub: tx.modeCampSub, color: Theme.ember) { vm.goClass() }
                ModeButton(title: tx.modeQuick, sub: tx.modeQuickSub, color: Theme.arcane) { vm.goDecks() }
                ModeButton(title: tx.modeOnline, sub: tx.modeOnlineSub, color: Theme.kelp) { vm.goOnline() }
            }
            .frame(maxWidth: 640)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array((tx.rules + [tx.lpHint]).enumerated()), id: \.offset) { _, r in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle().fill(Theme.ember).frame(width: 6, height: 6).offset(y: -2)
                        RichText(text: r, font: Theme.body(14), color: Theme.ink).lineSpacing(3)
                    }
                }
            }
            .frame(maxWidth: 440)
            Button(tx.viewCards) { vm.openGallery() }.ghost()
        }
    }
}

// MARK: - Adventure

struct RouteRow: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let n = GameData.shared.opponents.count
        HStack(spacing: 3) {
            ForEach(0..<n, id: \.self) { i in
                if i > 0 { Rectangle().fill(Theme.line).frame(width: 6, height: 1.5) }
                let done = i < vm.run.stage, here = i == vm.run.stage
                Text(i == n - 1 ? "B" : "\(i + 1)").font(Theme.body(10, .heavy))
                    .foregroundStyle(here ? Theme.ember : done ? Theme.ink : Theme.muted)
                    .frame(width: 20, height: 20)
                    .background(done ? Theme.line : .clear, in: Circle())
                    .overlay(Circle().stroke(here ? Theme.ember : Theme.line, lineWidth: 1.5))
            }
        }
        .frame(maxWidth: .infinity).padding(.top, 4)
        .accessibilityLabel(Text(vm.tx.duelOf(vm.run.stage + 1, n)))
    }
}

struct ClassPickView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        VStack(spacing: 6) {
            NavRow(items: [("⌂ " + tx.toMenu, { vm.goMenu() })])
            RouteRow()
            Page(title: tx.classTitle, subtitle: tx.classSub(tx.oppName(0)), centered: false) {
                ClassGrid { vm.pickClass($0) }
            }
        }
    }
}

struct ClassGrid: View {
    let pick: (String) -> Void
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 10)], spacing: 10) {
            ForEach(GameData.shared.classes) { c in ClassCard(c: c) { pick(c.id) } }
        }
    }
}

struct RewardView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        VStack(spacing: 6) {
            RouteRow()
            if let packs = vm.advPacks {
                Page(title: tx.defeated(tx.oppName(vm.run.stage)), subtitle: tx.packText(vm.run.deck.count, tx.oppName(vm.run.stage + 1)), centered: false) {
                    PackRow(packs: packs)
                    Button(tx.skip) { vm.skipReward() }.ghost()
                }
            } else {
                Page(title: tx.defeated(tx.oppName(vm.run.stage)), subtitle: tx.rewardText(vm.run.deck.count, tx.oppName(vm.run.stage + 1))) {
                    HStack(spacing: 10) {
                        ForEach(Array(vm.picks.enumerated()), id: \.offset) { i, k in
                            if let c = GameData.shared.card(k) {
                                Button { vm.pickReward(i) } label: { CardView(card: c, size: .md) }.buttonStyle(.plain)
                                    .onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = k }
                            }
                        }
                    }
                    .padding(.top, 8)
                    Button(tx.skip) { vm.skipReward() }.ghost()
                }
            }
        }
    }
}

struct LostView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        Page(title: tx.lostTitle, subtitle: tx.lostText(tx.oppName(vm.run.stage))) {
            HStack(spacing: 10) {
                Button(tx.retry) { vm.startDuel() }.primary()
                Button(tx.newRun) { vm.newRun() }.ghost()
            }
        }
    }
}

struct ChampView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        Page(title: tx.champTitle, subtitle: tx.champText(vm.run.deck.count)) {
            Button(tx.again) { vm.newRun() }.primary()
        }
    }
}

// MARK: - Quick match

struct DecksView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        VStack(spacing: 6) {
            NavRow(items: [("⌂ " + tx.toMenu, { vm.goMenu() })])
            Page(title: tx.myDecks, subtitle: tx.myDecksSub, centered: false) {
                Button("＋ " + tx.newDeck) { vm.goNewDeck() }.primary()
                if !vm.q.libToast.isEmpty { Text(vm.q.libToast).font(Theme.body(12.5)).foregroundStyle(Theme.ember) }
                if vm.decks.isEmpty {
                    Text(tx.noDecks).font(Theme.body(14)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).lineSpacing(3)
                        .padding(22).frame(maxWidth: .infinity)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundStyle(Theme.line))
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 10)], spacing: 10) {
                        ForEach(vm.decks) { d in DeckRow(d: d) }
                    }
                }
            }
        }
    }
}

struct DeckRow: View {
    let d: SavedDeck
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        if let c = GameData.shared.cls(d.cls) {
            let ok = d.cards.count == Decks.size, arm = vm.q.delArm == d.id
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ClassPortrait(c: c, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(d.name).font(Theme.display(18, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch).lineLimit(1)
                        Text("\(tx.name(c.names)) · \(ok ? tx.cardsN(d.cards.count) : tx.notReady(d.cards.count))")
                            .font(Theme.body(12.5)).foregroundStyle(ok ? Theme.muted : Theme.ember)
                    }
                    Spacer()
                }
                HStack(spacing: 6) {
                    Button(tx.playDeck) { vm.playSaved(d.id) }.primary(compact: true).disabled(!ok).opacity(ok ? 1 : 0.45)
                    Button(tx.editShort) { vm.q.delArm = nil; vm.openBuilder(cls: nil, id: d.id) }.ghost(compact: true)
                    Button(arm ? tx.confirmDelete : tx.deleteDeck) { vm.deleteDeck(d.id) }.ghost(compact: true, danger: arm)
                }
            }
            .padding(12)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            .overlay(alignment: .top) { Rectangle().fill(Color(hex: c.color)).frame(height: 3).clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)).padding(.horizontal, 1) }
        }
    }
}

struct QClassView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        VStack(spacing: 6) {
            NavRow(items: [vm.q.returnToOnline ? ("← " + tx.modeOnline, { vm.goOnline() }) : ("← " + tx.myDecks, { vm.goDecks() }), ("⌂ " + tx.toMenu, { vm.goMenu() })])
            Page(title: tx.pickClassNew, subtitle: tx.qClassSub(Decks.size), centered: false) {
                ClassGrid { vm.openBuilder(cls: $0) }
            }
        }
    }
}

struct DiffView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        VStack(spacing: 6) {
            NavRow(items: [("← " + tx.editDeck, { vm.go(.build) }), ("⌂ " + tx.toMenu, { vm.goMenu() })])
            Page(title: tx.diffTitle, subtitle: tx.diffSub) {
                VStack(spacing: 10) {
                    ForEach(Difficulty.allCases) { d in
                        ModeButton(title: tx.diff(d), sub: tx.diffDesc(d), color: Color(hex: d.colorHex)) { vm.startQuick(d) }
                    }
                }
                .frame(maxWidth: 440)
            }
        }
    }
}

struct QResultView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        if let s = vm.state {
            let won = s.result == .win
            Page(title: won ? tx.qWin : tx.qLose, subtitle: tx.qVs(tx.className(s.ecls ?? ""), tx.diff(s.diff ?? .normal))) {
                Text(tx.record(vm.q.w, vm.q.l)).font(Theme.body(15)).foregroundStyle(Theme.muted)
                HStack(spacing: 10) {
                    Button(tx.rematch) { vm.startQuick(vm.q.diff) }.primary()
                    Button(tx.editDeck) { vm.go(.build) }.ghost()
                    Button(tx.toMenu) { vm.newRun() }.ghost()
                }
            }
        }
    }
}

// MARK: - Gallery

struct GalleryView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, gd = GameData.shared
        let sort: (Card, Card) -> Bool = { a, b in (a.rarity == "t" ? 1 : 0, a.cost) < (b.rarity == "t" ? 1 : 0, b.cost) }
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(tx.galTitle).font(Theme.display(26, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                Spacer()
                Button(tx.back) { vm.closeGallery() }.ghost(compact: true)
            }
            .padding(.top, 6)
            Text(tx.galSub(gd.cards.count)).font(Theme.body(13)).foregroundStyle(Theme.muted)
            ForEach([(tx.minions, gd.cards.filter(\.isMinion)), (tx.spells, gd.cards.filter { !$0.isMinion })], id: \.0) { title, list in
                Text(title).font(Theme.body(12, .heavy)).tracking(2).textCase(.uppercase).foregroundStyle(Theme.gold).padding(.top, 14)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 22) {
                    ForEach(list.sorted(by: sort)) { c in
                        VStack(spacing: 8) {
                            CardView(card: c, size: .big).onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = c.id }
                            Text([tx.rarity(c.rarity), tx.costN(c.cost), c.race.map(tx.race)].compactMap { $0 }.joined(separator: " · "))
                                .font(Theme.body(11, .heavy)).tracking(1).textCase(.uppercase).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                            Text(tx.name(c.flavor)).font(Theme.body(12.5)).italic().foregroundStyle(Color(hex: "#c4b9c0")).multilineTextAlignment(.center).frame(maxWidth: 190)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Online

struct OnlineView: View {
    @Environment(GameVM.self) private var vm
    @FocusState private var codeFocused: Bool
    var body: some View {
        let tx = vm.tx, cur = vm.curOnlineDeck, busy = vm.o.net != .idle
        VStack(spacing: 6) {
            NavRow(items: [("⌂ " + tx.toMenu, { vm.goMenu() })])
            Page(title: tx.modeOnline, subtitle: tx.onSub, centered: false) {
                if let cur {
                    Text(tx.onDeck).font(Theme.body(12)).foregroundStyle(Theme.muted)
                    FlowChips {
                        ForEach(vm.onlineDecks) { d in
                            Chip(text: "\(d.name) · \(tx.className(d.cls))", on: d.id == cur.id, accent: Color(hex: GameData.shared.cls(d.cls)?.color ?? "#888")) { vm.selectOnlineDeck(d.id) }.disabled(busy)
                        }
                        Chip(text: "＋ " + tx.newDeck, on: false) { vm.q.returnToOnline = true; vm.goNewDeck() }.disabled(busy)
                        Chip(text: "✎ " + tx.editDeck, on: false) { vm.q.returnToOnline = true; vm.openBuilder(cls: nil, id: cur.id) }.disabled(busy)
                    }
                }
                if !vm.o.err.isEmpty { Text(vm.o.err).font(Theme.body(13)).foregroundStyle(Theme.ember).multilineTextAlignment(.center) }
                if !vm.backend.isCloud {
                    Text(tx.errNoBackend).font(Theme.body(13)).foregroundStyle(Theme.ember).multilineTextAlignment(.center)
                } else if vm.backend.auth.account?.isAnonymous == true {
                    Text(tx.errSignIn).font(Theme.body(13)).foregroundStyle(Theme.ember).multilineTextAlignment(.center)
                    Button(tx.settings) { vm.showSettings = true }.ghost(compact: true)
                } else if cur == nil {
                    Text(tx.onNoDecks).font(Theme.body(14)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).lineSpacing(3)
                        .padding(22).frame(maxWidth: .infinity).background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                    Button("＋ " + tx.newDeck) { vm.q.returnToOnline = true; vm.goNewDeck() }.primary()
                } else {
                    switch vm.o.net {
                    case .idle:
                        Button(tx.findMatch) { vm.findMatch() }.primary()
                        Text(tx.orJoin).font(Theme.body(12)).foregroundStyle(Theme.muted).padding(.top, 4)
                        Button(tx.createRoom) { vm.createRoom() }.ghost()
                        HStack(spacing: 8) {
                            TextField(tx.codePh, text: Binding(get: { vm.o.code }, set: { vm.o.code = String($0.filter(\.isNumber).prefix(6)) }))
                                .keyboardType(.numberPad).focused($codeFocused)
                                .font(Theme.body(15, .semibold)).foregroundStyle(Theme.parch)
                                .padding(.horizontal, 11).padding(.vertical, 9)
                                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                                .onSubmit { vm.joinTyped() }
                            Button(tx.joinRoom) { codeFocused = false; vm.joinTyped() }.primary(compact: true)
                        }
                        .frame(maxWidth: 340)
                    case .searching(let s):
                        RoomBox {
                            ProgressView().tint(Theme.gold)
                            Text(tx.searchingFor(s)).font(Theme.body(14)).foregroundStyle(Theme.ink).monospacedDigit()
                            Button(tx.cancel) { vm.cancelNet() }.ghost(compact: true)
                        }
                    case .hosting(let code):
                        RoomBox {
                            Text(tx.roomCode).font(Theme.body(12)).foregroundStyle(Theme.muted)
                            Text(code.map { "\($0.prefix(3)) \($0.suffix(3))" } ?? "··· ···")
                                .font(.system(size: 40, weight: .bold, design: .serif)).tracking(4).foregroundStyle(Theme.gold).monospacedDigit()
                                .textSelection(.enabled)
                            Text(code == nil ? tx.loadingNet : tx.waitFriend).font(Theme.body(14)).foregroundStyle(Theme.ink)
                            HStack(spacing: 10) {
                                if let code {
                                    ShareLink(item: tx.inviteText(code)) { Text(tx.shareInvite) }.primary(compact: true)
                                }
                                Button(tx.cancel) { vm.cancelNet() }.ghost(compact: true)
                            }
                        }
                    case .joining:
                        RoomBox {
                            ProgressView().tint(Theme.gold)
                            Text(tx.connecting(vm.o.code)).font(Theme.body(14)).foregroundStyle(Theme.ink)
                            Button(tx.cancel) { vm.cancelNet() }.ghost(compact: true)
                        }
                    case .live:
                        RoomBox { ProgressView().tint(Theme.gold); Text(tx.foundMatch).font(Theme.body(14)).foregroundStyle(Theme.ink) }
                    }
                }
            }
        }
    }
}

struct RoomBox<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 8) { content }
            .padding(16).frame(maxWidth: 420)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}

struct Chip: View {
    let text: String
    let on: Bool
    var accent: Color? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(Theme.body(12.5, .bold)).foregroundStyle(on ? Theme.parch : Theme.muted).lineLimit(1)
                .padding(.horizontal, 11).padding(.vertical, 6)
                .background(on ? Theme.line : Theme.panel, in: Capsule())
                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                .overlay(alignment: .leading) { if let accent { Capsule().fill(accent).frame(width: 3).padding(.vertical, 6).padding(.leading, 1) } }
        }
        .buttonStyle(.plain)
    }
}

/// Wrapping row of chips.
struct FlowChips<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        FlowLayout(spacing: 5) { content }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 5
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > w && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: w, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.width && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), proposal: .unspecified)
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

struct OResultView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        if let s = vm.state {
            let r = s.result
            Page(title: r == .win ? tx.qWin : r == .lose ? tx.qLose : tx.oDraw, subtitle: tx.oVs(tx.className(s.ecls ?? ""))) {
                if let why = vm.oResultWhy { Text(why).font(Theme.body(14)).foregroundStyle(Theme.muted) }
                Text(tx.record(vm.o.w, vm.o.l)).font(Theme.body(15)).foregroundStyle(Theme.muted)
                if vm.o.foeAgain && !vm.o.again { Text(tx.foeAgain).font(Theme.body(13)).foregroundStyle(Theme.ember) }
                HStack(spacing: 10) {
                    if vm.match != nil {
                        Button(vm.o.again ? tx.waitAgain : tx.oAgain) { vm.askRematch() }.primary().disabled(vm.o.again).opacity(vm.o.again ? 0.6 : 1)
                    }
                    Button(tx.leaveRoom) { vm.leaveOnline() }.ghost()
                }
            }
        }
    }
}
