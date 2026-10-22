import SwiftUI
import AuthenticationServices
import CryptoKit

/// Chooses between the sign-in screen and the game, and hosts the global overlays.
struct RootView: View {
    @Environment(GameVM.self) private var vm
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if vm.screen == .duel {
                SceneBackdrop(name: vm.scene).transition(.opacity).id(vm.scene)
            } else {
                RadialGradient(colors: [Color(hex: "#2a2030"), .clear], center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0, endRadius: 420).ignoresSafeArea()
            }
            if !reduceMotion { Embers().ignoresSafeArea() }
            switch vm.backend.auth {
            case .loading: ProgressView().tint(Theme.gold)
            case .signedOut: SignInView()
            case .signedIn: GameRoot()
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: vm.lang == .zh ? "zh-Hans" : vm.lang == .ja ? "ja" : "en"))
        .onAppear { vm.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { _, n in vm.reduceMotion = n }
        .onChange(of: scenePhase) { _, p in if p == .active, vm.match != nil { Task { await vm.match?._beat() } } }
        .sheet(isPresented: Binding(get: { vm.showSettings }, set: { vm.showSettings = $0 })) { SettingsView() }
    }
}

struct GameRoot: View {
    @Environment(GameVM.self) private var vm
    var body: some View {
        ZStack {
            if vm.screen == .duel {
                GeometryReader { g in
                    let hm = HandMetrics(size: g.size, bottomInset: g.safeAreaInsets.bottom)
                    ZStack(alignment: .topLeading) {
                        DuelView(hm: hm).padding(.vertical, hm.pad)
                        HandLayer(hm: hm, origin: g.frame(in: .global).origin).zIndex(10)
                        if let c = vm.infoCard, vm.state?.mulligan != true {
                            CardInfoPanel(card: c, hm: hm).padding(.leading, hm.heroX + 48).padding(.top, 4).zIndex(15).id(c.id)
                        }
                        if vm.state?.mulligan == true { MulliganView().zIndex(20) }
                        if vm.choice != nil { ChoiceView().zIndex(21) }
                    }
                    .animation(.easeOut(duration: 0.18), value: vm.infoCard?.id)
                }
            } else {
                Group {
                    switch vm.screen {
                    case .intro: IntroView()
                    case .classPick: ClassPickView()
                    case .talents: TalentScreen()
                    case .duel: EmptyView()
                    case .reward: RewardView()
                    case .lost: LostView()
                    case .champ: ChampView()
                    case .decks: DecksView()
                    case .qclass: QClassView()
                    case .build: BuilderView()
                    case .diff: DiffView()
                    case .qtalents: QTalentScreen()
                    case .qresult: QResultView()
                    case .gallery: GalleryView()
                    case .online: OnlineView()
                    case .oresult: OResultView()
                    }
                }
                .id(vm.screen)
                if vm.showRules { RulesOverlay().zIndex(40) }
            }
            FXLayer()
            if let r = vm.reveal { VStack { RevealView(r: r).padding(.top, 60); Spacer() }.transition(.opacity).id(r.id) }
            if let b = vm.banner { BannerView(banner: b).transition(.opacity) }
            if vm.o.slow {
                VStack { Text(vm.tx.netSlow).font(Theme.body(12.5)).foregroundStyle(Theme.parch).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(hex: "#3a1f1a"), in: Capsule()).overlay(Capsule().stroke(Theme.ember, lineWidth: 1)); Spacer() }
            }
            if vm.showLog { LogView().zIndex(40) }
            if vm.showTalentPanel { TalentsOverlay().zIndex(40) }
            if let k = vm.zoomCard { CardZoom(key: k).zIndex(50) }
            if let h = vm.peekItem { PeekView(h: h).zIndex(50) }
        }
        .animation(.easeOut(duration: 0.2), value: vm.zoomCard)
        .animation(.easeOut(duration: 0.2), value: vm.showLog)
        .animation(.easeOut(duration: 0.2), value: vm.showRules)
        .animation(.easeOut(duration: 0.25), value: vm.screen)
        .animation(.easeOut(duration: 0.2), value: vm.peekItem?.id)
    }
}

struct Pill: View {
    let text: String, color: Color
    var body: some View {
        Text(text).font(Theme.body(12, .heavy)).foregroundStyle(color).monospacedDigit()
            .padding(.horizontal, 9).padding(.vertical, 2).overlay(Capsule().stroke(color, lineWidth: 1.5))
    }
}

// MARK: - Sign in

struct SignInView: View {
    @Environment(GameVM.self) private var vm
    @State private var errMsg = ""
    @State private var working = false
    var body: some View {
        let tx = vm.tx
        VStack(spacing: 18) {
            Spacer()
            Image("AppIconArt").resizable().scaledToFit().frame(width: 96, height: 96).clipShape(RoundedRectangle(cornerRadius: 22))
            Text(tx.brand).font(Theme.display(34, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
            Text(tx.welcome).font(Theme.body(15)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 320)
            AppleSignInButton { payload in
                working = true; errMsg = ""
                do { try await vm.backend.signInWithApple(payload) } catch { errMsg = tx.signInFailed }
                working = false
            } onError: { errMsg = tx.signInFailed }
            .frame(height: 48).frame(maxWidth: 320)
            Button(tx.continueGuest) {
                working = true
                Task { do { try await vm.backend.signInAsGuest() } catch { errMsg = tx.signInFailed }; working = false }
            }
            .ghost()
            Text(tx.guestNote).font(Theme.body(12.5)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 320)
            if !errMsg.isEmpty { Text(errMsg).font(Theme.body(13)).foregroundStyle(Theme.ember) }
            if working { ProgressView().tint(Theme.gold) }
            Spacer()
            Picker(tx.language, selection: Binding(get: { vm.lang }, set: { vm.setLang($0) })) {
                ForEach(Lang.allCases) { l in Text(l.label).tag(l) }
            }
            .pickerStyle(.segmented).frame(maxWidth: 240)
        }
        .padding(24)
    }
}

/// Native Sign in with Apple button producing the credential Firebase needs (nonce-protected).
struct AppleSignInButton: View {
    let onSuccess: (AppleCredentialPayload) async -> Void
    let onError: () -> Void
    @State private var nonce = ""
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            nonce = Self.randomNonce()
            request.requestedScopes = [.fullName]
            request.nonce = Self.sha256(nonce)
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                      let tokenData = cred.identityToken, let token = String(data: tokenData, encoding: .utf8) else { onError(); return }
                let code = cred.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
                let payload = AppleCredentialPayload(idToken: token, rawNonce: nonce, authorizationCode: code, fullName: cred.fullName)
                Task { await onSuccess(payload) }
            case .failure(let e):
                if (e as? ASAuthorizationError)?.code != .canceled { onError() }
            }
        }
        .signInWithAppleButtonStyle(.white)
    }
    static func randomNonce(length: Int = 32) -> String {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).map { _ in chars[Int.random(in: 0..<chars.count)] })
    }
    static func sha256(_ s: String) -> String { SHA256.hash(data: Data(s.utf8)).map { String(format: "%02x", $0) }.joined() }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(GameVM.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var needReauth = false
    @State private var errMsg = ""
    var body: some View {
        let tx = vm.tx
        // One screenful: language, account and about, side by side.
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                HStack {
                    Text(tx.settings).font(Theme.display(20, cjk: vm.lang.isCJK)).foregroundStyle(Theme.parch)
                    Spacer()
                    Button(tx.back) { dismiss() }.primary(compact: true)
                }
                HStack(alignment: .top, spacing: 12) {
                    SettingsBox(title: tx.language) {
                        Picker(tx.language, selection: Binding(get: { vm.lang }, set: { vm.setLang($0) })) {
                            ForEach(Lang.allCases) { l in Text(l.label).tag(l) }
                        }
                        .pickerStyle(.segmented)
                    }
                    accountBox
                    aboutBox
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .alert(tx.deleteAccount, isPresented: $confirmDelete) {
                Button(tx.delete, role: .destructive) { Task { await deleteAccount(reauth: nil) } }
                Button(tx.cancel, role: .cancel) {}
            } message: { Text(tx.deleteAccountSure) }
            .sheet(isPresented: $needReauth) {
                VStack(spacing: 16) {
                    Text(tx.reauthNeeded).multilineTextAlignment(.center).padding()
                    AppleSignInButton { payload in needReauth = false; await deleteAccount(reauth: payload) } onError: { errMsg = tx.signInFailed; needReauth = false }
                        .frame(height: 48).padding(.horizontal, 40)
                }
                .presentationDetents([.medium])
            }
        }
    }
    @ViewBuilder private var accountBox: some View {
        let tx = vm.tx, acct = vm.backend.auth.account, prof = vm.backend.profile
        SettingsBox(title: tx.account) {
            if !vm.backend.isCloud {
                Text(tx.offlineMode).font(Theme.body(12)).foregroundStyle(Theme.muted)
            } else if let acct {
                if acct.isAnonymous {
                    Text(tx.guest).font(Theme.body(14, .bold)).foregroundStyle(Theme.parch)
                    Text(tx.guestNote).font(Theme.body(11.5)).foregroundStyle(Theme.muted)
                    AppleSignInButton { payload in
                        do { try await vm.backend.signInWithApple(payload) } catch { errMsg = tx.signInFailed }
                    } onError: { errMsg = tx.signInFailed }
                    .frame(height: 40)
                } else {
                    Text(tx.signedInAs + (acct.name.map { " · \($0)" } ?? "")).font(Theme.body(14, .bold)).foregroundStyle(Theme.parch)
                }
                Text(tx.stats(prof.onlineW, prof.onlineL)).font(Theme.body(12)).foregroundStyle(Theme.muted)
                HStack(spacing: 8) {
                    Button(tx.signOut) { try? vm.backend.signOut(); vm.newRun(); dismiss() }.ghost(compact: true)
                    Button(tx.deleteAccount) { confirmDelete = true }.ghost(compact: true, danger: true)
                }
            }
            if !errMsg.isEmpty { Text(errMsg).font(Theme.body(12)).foregroundStyle(Theme.ember) }
        }
    }
    @ViewBuilder private var aboutBox: some View {
        let tx = vm.tx
        let info = Bundle.main.infoDictionary ?? [:]
        let short: String = info["CFBundleShortVersionString"] as? String ?? ""
        let build: String = info["CFBundleVersion"] as? String ?? ""
        SettingsBox(title: tx.brand) {
            Link(tx.privacy, destination: URL(string: "https://ruinaccord.hermes-eris.com/privacy.html")!).font(Theme.body(13, .bold)).foregroundStyle(Color(hex: "#9fc4ee"))
            Text("Version \(short) (\(build))").font(Theme.body(12)).foregroundStyle(Theme.muted)
        }
    }
    private func deleteAccount(reauth: AppleCredentialPayload?) async {
        do {
            try await vm.backend.deleteAccount(reauth: reauth)
            vm.newRun(); dismiss()
        } catch BackendError.requiresRecentLogin { needReauth = true } catch { errMsg = vm.tx.signInFailed }
    }
}

/// A titled box on the settings screen.
struct SettingsBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.body(11, .heavy)).tracking(1.5).textCase(.uppercase).foregroundStyle(Theme.gold)
            content
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}
