import SwiftUI

/// Centred block with a serif title and a muted subtitle (result screens).
struct Page<Content: View>: View {
    var title: String
    var subtitle: String? = nil
    var centered = true
    @ViewBuilder var content: Content
    @Environment(GameVM.self) private var vm
    var body: some View {
        VStack(spacing: 14) {
            if centered { Spacer(minLength: 0) }
            Text(title).font(Theme.display(28, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch).multilineTextAlignment(.center)
            if let subtitle { Text(subtitle).font(Theme.body(14)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 460) }
            content
            if centered { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

/// Adventure progress: the eight duels as dots.
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
        .accessibilityLabel(Text(vm.tx.duelOf(vm.run.stage + 1, n)))
    }
}

/// A big mode tile on the menu.
struct ModeTile: View {
    let title: String, sub: String, foot: String, color: Color, icon: String
    var width: CGFloat = 156
    let action: () -> Void
    @Environment(GameVM.self) private var vm
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: icon).font(.system(size: 26, weight: .bold)).foregroundStyle(color)
                Text(title).font(Theme.display(19, cjk: vm.lang.isCJK)).foregroundStyle(color.mixed(with: .white, 0.55))
                Text(sub).font(Theme.body(11.5)).foregroundStyle(Theme.muted).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text(foot).font(Theme.body(10.5, .bold)).foregroundStyle(color)
            }
            .padding(14)
            .frame(width: width, height: 192, alignment: .topLeading)
            .background(LinearGradient(colors: [color.opacity(0.28), Color(hex: "#120c14").opacity(0.95)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.85), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .multilineTextAlignment(.leading)
    }
}

// MARK: - Menu

struct IntroView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, prof = vm.backend.profile, acct = vm.backend.auth.account
        ScreenShell {
            ZStack(alignment: .topLeading) {
                // account and settings, top right
                HStack(spacing: 8) {
                    Text((acct?.isAnonymous == false ? tx.accountApple : tx.guest) + " · " + tx.statsShort(prof.onlineW, prof.onlineL))
                        .font(Theme.body(11.5)).foregroundStyle(Theme.muted).lineLimit(1)
                        .padding(.horizontal, 12).frame(height: 32)
                        .background(Color.black.opacity(0.45), in: Capsule()).overlay(Capsule().stroke(Theme.gold.opacity(0.35), lineWidth: 1))
                    Button { vm.showSettings = true } label: {
                        Image(systemName: "gearshape.fill").font(.system(size: 17, weight: .bold)).foregroundStyle(Color(hex: "#9fc4ee"))
                            .frame(width: 44, height: 44)
                            .background(LinearGradient(colors: [Color(hex: "#1e2a44"), Color(hex: "#111726")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#4a6a9a"), lineWidth: 1))
                    }
                    .buttonStyle(.plain).accessibilityLabel(Text(tx.settings))
                }
                .frame(maxWidth: .infinity, alignment: .trailing).padding(.top, 10).padding(.trailing, 14)

                GeometryReader { g in
                    let tileW = min(156, (g.size.width - 56 - 24 - 200) / 3 - 10)
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tx.brand).font(.system(size: 40, weight: .regular, design: .serif)).foregroundStyle(Color(hex: "#f3e2c2")).lineLimit(1).minimumScaleFactor(0.7)
                            Text(tx.introTitle).font(Theme.body(13, .bold)).tracking(1.5).foregroundStyle(Theme.gold).fixedSize(horizontal: false, vertical: true)
                            Text(tx.introBlurb).font(Theme.body(11.5)).foregroundStyle(Theme.muted).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 10) {
                            ModeTile(title: tx.modeCamp, sub: tx.modeCampSub, foot: tx.statsShort(prof.campClears, nil), color: Theme.ember, icon: "crown.fill", width: tileW) { vm.goClass() }
                            ModeTile(title: tx.modeQuick, sub: tx.modeQuickSub, foot: tx.statsShort(prof.quickW, prof.quickL), color: Theme.arcane, icon: "bolt.fill", width: tileW) { vm.goDecks() }
                            ModeTile(title: tx.modeOnline, sub: tx.modeOnlineSub, foot: tx.statsShort(prof.onlineW, prof.onlineL), color: Theme.kelp, icon: "globe", width: tileW) { vm.goOnline() }
                        }
                    }
                    .padding(.leading, 36).padding(.trailing, 20).padding(.top, 74)
                }

                HStack(spacing: 10) {
                    Button(tx.myDecks) { vm.goDecks() }.ghost()
                    Button(tx.cardsBtn) { vm.openGallery() }.ghost()
                    Button(tx.rulesBtn) { vm.showRules = true }.ghost()
                    Spacer()
                    Text("v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")).font(Theme.body(10.5)).foregroundStyle(Color(hex: "#8a7f8e"))
                }
                .padding(.horizontal, 36).padding(.bottom, 22)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

/// The rules, as a panel over the menu.
struct RulesOverlay: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { vm.showRules = false }
            VStack(alignment: .leading, spacing: 8) {
                Text(tx.rulesBtn).font(Theme.display(18, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], alignment: .leading, spacing: 6) {
                    ForEach(Array((tx.rules + [tx.lpHint]).enumerated()), id: \.offset) { _, r in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Circle().fill(Theme.ember).frame(width: 6, height: 6).offset(y: -2)
                            RichText(text: r, font: Theme.body(12), color: Theme.ink).lineSpacing(2)
                        }
                    }
                }
                HStack { Spacer(); Button(tx.closeLbl) { vm.showRules = false }.primary(compact: true) }
            }
            .padding(16)
            .frame(maxWidth: 700)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold.opacity(0.6), lineWidth: 1))
            .padding(20)
        }
        .transition(.opacity)
    }
}

// MARK: - Classes (adventure and new deck)

struct ClassPickView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: "glade") {
            VStack(spacing: 4) {
                BarRow(back: (tx.toMenu, { vm.goMenu() }), title: tx.classTitle, subtitle: tx.classSub(tx.oppName(0))) { RouteRow() }
                ClassRow { vm.pickClass($0) }
            }
        }
    }
}

struct QClassView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: "glade") {
            VStack(spacing: 4) {
                BarRow(back: vm.q.returnToOnline ? (tx.modeOnline, { vm.goOnline() }) : (tx.myDecks, { vm.goDecks() }), title: tx.pickClassNew, subtitle: tx.qClassSub(Decks.size))
                ClassRow { vm.openBuilder(cls: $0) }
            }
        }
    }
}

/// The six classes in one row, sized to the width.
struct ClassRow: View {
    let pick: (String) -> Void
    var body: some View {
        GeometryReader { g in
            let n = CGFloat(GameData.shared.classes.count)
            let w = min(136, (g.size.width - 24 - (n - 1) * 10) / n), h = min(300, g.size.height - 12)
            HStack(spacing: 10) {
                ForEach(GameData.shared.classes) { c in ClassTile(c: c, width: w, height: h) { pick(c.id) } }
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

// MARK: - Adventure results

struct RewardView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: vm.scene) {
            VStack(spacing: 4) {
                BarRow(title: tx.defeated(tx.oppName(vm.run.stage)), subtitle: vm.advPacks != nil ? tx.packText(vm.run.deck.count, tx.oppName(vm.run.stage + 1)) : tx.rewardText(vm.run.deck.count, tx.oppName(vm.run.stage + 1))) {
                    RouteRow()
                    Button(tx.skip) { vm.skipReward() }.ghost(compact: true)
                }
                if let packs = vm.advPacks {
                    PackRow(packs: packs).padding(.horizontal, 16).frame(maxHeight: .infinity)
                } else {
                    HStack(spacing: 14) {
                        ForEach(Array(vm.picks.enumerated()), id: \.offset) { i, k in
                            if let c = GameData.shared.card(k) {
                                Button { vm.pickReward(i) } label: { CardView(card: c, size: .big) }.buttonStyle(.plain)
                                    .onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = k }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

struct LostView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: vm.scene) {
            Page(title: tx.lostTitle, subtitle: tx.lostText(tx.oppName(vm.run.stage))) {
                HStack(spacing: 10) {
                    Button(tx.retry) { vm.goStage() }.primary()
                    Button(tx.newRun) { vm.newRun() }.ghost()
                }
            }
        }
    }
}

struct ChampView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: "dawn") {
            Page(title: tx.champTitle, subtitle: tx.champText(vm.run.deck.count)) {
                Button(tx.again) { vm.newRun() }.primary()
            }
        }
    }
}

// MARK: - Decks

struct DecksView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell {
            VStack(spacing: 4) {
                BarRow(back: (tx.toMenu, { vm.goMenu() }), title: tx.myDecks, subtitle: vm.q.delArm != nil ? tx.confirmDelete : vm.q.libToast.isEmpty ? tx.myDecksSub : vm.q.libToast)
                PagedGrid(items: vm.decks.map(DeckOrNew.deck) + [DeckOrNew.new], cellWidth: 118, cellHeight: 300, rows: 1, hGap: 12) { it, _ in
                    switch it {
                    case .deck(let d): DeckStandee(d: d)
                    case .new:
                        Button { vm.goNewDeck() } label: {
                            VStack(spacing: 10) {
                                Text("+").font(.system(size: 30, weight: .light)).foregroundStyle(Theme.gold)
                                    .frame(width: 48, height: 48).overlay(Circle().stroke(Theme.gold, lineWidth: 1.5))
                                Text(tx.newDeck).font(Theme.body(14, .heavy)).foregroundStyle(Theme.parch)
                                Text(tx.qClassSub(Decks.size)).font(Theme.body(10.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 10)
                            }
                            .frame(width: 118, height: 300)
                            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5])).foregroundStyle(Theme.gold))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

enum DeckOrNew: Identifiable {
    case deck(SavedDeck), new
    var id: String { if case .deck(let d) = self { return d.id }; return "new" }
}

/// A saved deck as a standing tile with its own Play / Edit / Delete.
struct DeckStandee: View {
    let d: SavedDeck
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx, gd = GameData.shared
        if let c = gd.cls(d.cls) {
            let ok = d.cards.count == Decks.size, arm = vm.q.delArm == d.id, col = Color(hex: c.color)
            let pages = gd.talentPages(d.cls)
            let talSummary = pages.map { pg in "\(tx.name(pg.names)) \(d.talents.filter { gd.talentPage(of: $0)?.id == pg.id }.count)" }.joined(separator: " · ")
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RadialGradient(colors: [Color(hex: "#3a3046"), Color(hex: "#140f18")], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 80)
                    Image(c.artName).resizable().scaledToFill().frame(width: 115, height: 112).clipped()
                }
                .frame(width: 115, height: 112)
                Text(d.name).font(Theme.body(13.5, .heavy)).foregroundStyle(Theme.parch).lineLimit(1).padding(.horizontal, 9).padding(.top, 7)
                Text("\(tx.name(c.names)) · \(ok ? tx.cardsN(d.cards.count) : tx.notReady(d.cards.count))").font(Theme.body(10)).foregroundStyle(ok ? col.mixed(with: .white, 0.5) : Theme.ember).lineLimit(2).padding(.horizontal, 9).padding(.top, 2)
                if !pages.isEmpty { Text("✦ " + talSummary).font(Theme.body(9.5)).foregroundStyle(Theme.gold).lineLimit(1).minimumScaleFactor(0.8).padding(.horizontal, 9).padding(.top, 2) }
                Spacer(minLength: 0)
                VStack(spacing: 5) {
                    Button(tx.playDeck) { vm.playSaved(d.id) }.primary(compact: true).disabled(!ok).opacity(ok ? 1 : 0.4).frame(maxWidth: .infinity)
                    HStack(spacing: 5) {
                        IconButton(symbol: "pencil", label: tx.editShort) { vm.q.delArm = nil; vm.openBuilder(cls: nil, id: d.id) }.frame(maxWidth: .infinity)
                        IconButton(symbol: arm ? "trash.fill" : "trash", label: arm ? tx.confirmDelete : tx.deleteDeck, primary: arm, danger: true) { vm.deleteDeck(d.id) }.frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 7).padding(.bottom, 8)
            }
            .frame(width: 118, height: 300, alignment: .topLeading)
            .background(LinearGradient(colors: [col.opacity(0.22), Color(hex: "#120c14").opacity(0.96)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(col, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 8, y: 6)
        }
    }
}

// MARK: - Quick match

struct DiffView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: "warfront") {
            VStack(spacing: 4) {
                BarRow(back: (tx.editDeck, { vm.go(.build) }), title: tx.diffTitle, subtitle: tx.diffSub)
                HStack(spacing: 14) {
                    ForEach(Difficulty.allCases) { d in
                        ModeTile(title: tx.diff(d), sub: tx.diffDesc(d), foot: "", color: Color(hex: d.colorHex), icon: d == .easy ? "leaf.fill" : d == .normal ? "shield.fill" : "flame.fill") { vm.pickDifficulty(d) }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

struct QResultView: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        let tx = vm.tx
        ScreenShell(scene: vm.scene) {
            if let s = vm.state {
                let won = s.result == .win
                Page(title: won ? tx.qWin : tx.qLose, subtitle: tx.qVs(tx.className(s.ecls ?? ""), tx.diff(s.diff ?? .normal))) {
                    Text(tx.record(vm.q.w, vm.q.l)).font(Theme.body(14)).foregroundStyle(Theme.muted)
                    HStack(spacing: 10) {
                        Button(tx.rematch) { vm.startQuick(vm.q.diff) }.primary()
                        Button(tx.editDeck) { vm.go(.build) }.ghost()
                        Button(tx.toMenu) { vm.newRun() }.ghost()
                    }
                }
            }
        }
    }
}

// MARK: - Gallery

struct GalleryView: View {
    @Environment(GameVM.self) private var vm
    @State private var type = "all"
    @State private var cost = -1
    @State private var cls = "all"
    var body: some View {
        let tx = vm.tx, gd = GameData.shared
        let list = gd.cards.filter { c in
            c.rarity != "t" && (type == "all" || (type == "m") == c.isMinion) && (cost < 0 || (cost == 7 ? c.cost >= 7 : c.cost == cost)) && (cls == "all" || c.cls == cls || (cls == "neutral" && c.cls == nil))
        }.sorted { a, b in a.cost != b.cost ? a.cost < b.cost : tx.name(a.names) < tx.name(b.names) }
        ScreenShell(scene: "glade") {
            VStack(spacing: 2) {
                BarRow(back: (tx.back, { vm.closeGallery() }), title: tx.galTitle, subtitle: tx.galSub(gd.cards.filter { $0.rarity != "t" }.count)) {
                    HStack(spacing: 4) {
                        Tag(text: tx.typeAll, on: type == "all") { type = "all" }
                        Tag(symbol: "person.fill", label: tx.minions, on: type == "m") { type = "m" }
                        Tag(symbol: "sparkles", label: tx.spells, on: type == "s") { type = "s" }
                        Rectangle().fill(Theme.line).frame(width: 1, height: 18).padding(.horizontal, 3)
                        Menu {
                            Button(tx.typeAll) { cost = -1 }
                            ForEach(0..<8, id: \.self) { n in Button(n == 7 ? "7+" : "\(n)") { cost = n } }
                        } label: { Tag(text: cost < 0 ? "" : cost == 7 ? "7+" : "\(cost)", symbol: "hexagon.fill", label: tx.costLbl, on: cost >= 0) {} }
                        Menu {
                            Button(tx.typeAll) { cls = "all" }
                            Button(tx.neutralCards) { cls = "neutral" }
                            ForEach(gd.classes) { c in Button(tx.name(c.names)) { cls = c.id } }
                        } label: { Tag(text: cls == "all" ? "" : cls == "neutral" ? tx.neutralCards : tx.className(cls), symbol: "shield.fill", label: tx.classCards, on: cls != "all") {} }
                    }
                }
                PagedGrid(items: list, cellWidth: 96, cellHeight: 150, rows: 2, hGap: 6, vGap: 14) { c, s in
                    CardView(card: c, size: .fit(9.6 * s)).onLongPressGesture(minimumDuration: 0.43) { vm.zoomCard = c.id }
                }
            }
        }
    }
}

// MARK: - Online

struct OnlineView: View {
    @Environment(GameVM.self) private var vm
    @FocusState private var codeFocused: Bool
    var body: some View {
        let tx = vm.tx, cur = vm.curOnlineDeck, busy = vm.o.net != .idle
        ScreenShell(scene: "dawn") {
            VStack(spacing: 4) {
                BarRow(back: (tx.toMenu, { vm.goMenu() }), title: tx.modeOnline, subtitle: tx.onSub) {
                    if vm.backend.auth.account?.isAnonymous == true { Button(tx.settings) { vm.showSettings = true }.ghost(compact: true) }
                }
                if !vm.backend.isCloud {
                    Page(title: tx.modeOnline, subtitle: tx.errNoBackend) { EmptyView() }
                } else if vm.backend.auth.account?.isAnonymous == true {
                    Page(title: tx.modeOnline, subtitle: tx.errSignIn) { Button(tx.settings) { vm.showSettings = true }.primary() }
                } else if cur == nil {
                    Page(title: tx.modeOnline, subtitle: tx.onNoDecks) { Button("＋ " + tx.newDeck) { vm.q.returnToOnline = true; vm.goNewDeck() }.primary() }
                } else {
                    HStack(alignment: .top, spacing: 14) {
                        // left: the deck to play with
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tx.onDeck).font(Theme.body(12, .heavy)).tracking(1).foregroundStyle(Theme.gold)
                            FlowChips {
                                ForEach(vm.onlineDecks) { d in
                                    Chip(text: "\(d.name) · \(tx.className(d.cls))", on: d.id == cur?.id, accent: Color(hex: GameData.shared.cls(d.cls)?.color ?? "#888")) { vm.selectOnlineDeck(d.id) }.disabled(busy)
                                }
                                Chip(text: "＋ " + tx.newDeck, on: false) { vm.q.returnToOnline = true; vm.goNewDeck() }.disabled(busy)
                                if let cur { Chip(text: "✎ " + tx.editDeck, on: false) { vm.q.returnToOnline = true; vm.openBuilder(cls: nil, id: cur.id) }.disabled(busy) }
                            }
                            if !vm.o.err.isEmpty { Text(vm.o.err).font(Theme.body(12)).foregroundStyle(Theme.ember) }
                            Spacer(minLength: 0)
                        }
                        .padding(14).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Theme.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                        // right: match or room
                        VStack(spacing: 10) {
                            switch vm.o.net {
                            case .idle:
                                Button(tx.findMatch) { vm.findMatch() }.primary(glow: true)
                                Text(tx.orJoin).font(Theme.body(12)).foregroundStyle(Theme.muted)
                                Button(tx.createRoom) { vm.createRoom() }.ghost()
                                HStack(spacing: 8) {
                                    TextField(tx.codePh, text: Binding(get: { vm.o.code }, set: { vm.o.code = String($0.filter(\.isNumber).prefix(6)) }))
                                        .keyboardType(.numberPad).focused($codeFocused)
                                        .font(Theme.body(15, .semibold)).foregroundStyle(Theme.parch)
                                        .padding(.horizontal, 11).frame(height: 40)
                                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                                        .onSubmit { vm.joinTyped() }
                                    Button(tx.joinRoom) { codeFocused = false; vm.joinTyped() }.primary(compact: true)
                                }
                                .frame(maxWidth: 300)
                            case .searching(let s):
                                ProgressView().tint(Theme.gold)
                                Text(tx.searchingFor(s)).font(Theme.body(14)).foregroundStyle(Theme.ink).monospacedDigit()
                                Button(tx.cancel) { vm.cancelNet() }.ghost(compact: true)
                            case .hosting(let code):
                                Text(tx.roomCode).font(Theme.body(12)).foregroundStyle(Theme.muted)
                                Text(code.map { "\($0.prefix(3)) \($0.suffix(3))" } ?? "··· ···")
                                    .font(.system(size: 38, weight: .bold, design: .serif)).tracking(4).foregroundStyle(Theme.gold).monospacedDigit().textSelection(.enabled)
                                Text(code == nil ? tx.loadingNet : tx.waitFriend).font(Theme.body(13)).foregroundStyle(Theme.ink)
                                HStack(spacing: 10) {
                                    if let code { ShareLink(item: tx.inviteText(code)) { Text(tx.shareInvite) }.primary(compact: true) }
                                    Button(tx.cancel) { vm.cancelNet() }.ghost(compact: true)
                                }
                            case .joining:
                                ProgressView().tint(Theme.gold)
                                Text(tx.connecting(vm.o.code)).font(Theme.body(14)).foregroundStyle(Theme.ink)
                                Button(tx.cancel) { vm.cancelNet() }.ghost(compact: true)
                            case .live:
                                ProgressView().tint(Theme.gold); Text(tx.foundMatch).font(Theme.body(14)).foregroundStyle(Theme.ink)
                            }
                        }
                        .padding(14).frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                    }
                    .padding(.horizontal, 14).padding(.bottom, 12)
                }
            }
        }
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
                .padding(.horizontal, 11).frame(height: 32)
                .background(on ? Theme.line : Theme.panel, in: Capsule())
                .overlay(Capsule().stroke(on ? Theme.gold.opacity(0.7) : Theme.line, lineWidth: 1))
                .overlay(alignment: .leading) { if let accent { Capsule().fill(accent).frame(width: 3).padding(.vertical, 7).padding(.leading, 1) } }
        }
        .buttonStyle(.plain)
    }
}

/// Wrapping row of chips.
struct FlowChips<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { FlowLayout(spacing: 6) { content } }
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
        ScreenShell(scene: vm.scene) {
            if let s = vm.state {
                let r = s.result
                Page(title: r == .win ? tx.qWin : r == .lose ? tx.qLose : tx.oDraw, subtitle: tx.oVs(tx.className(s.ecls ?? ""))) {
                    if let why = vm.oResultWhy { Text(why).font(Theme.body(14)).foregroundStyle(Theme.muted) }
                    Text(tx.record(vm.o.w, vm.o.l)).font(Theme.body(14)).foregroundStyle(Theme.muted)
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
}
