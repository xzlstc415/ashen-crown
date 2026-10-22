import SwiftUI

/// The painted places a duel is fought in. Adventure picks by stage; quick and online duels pick at random.
enum Scenes {
    static let all = ["graveyard", "dawn", "warfront", "glade"]
    /// Storm Witch, Goblins, Bandits, Warlord, Dwarves, Conclave, Lich, Ashen King.
    static let byStage = ["dawn", "warfront", "glade", "warfront", "dawn", "glade", "graveyard", "warfront"]
    static func forStage(_ s: Int) -> String { byStage[safe: s] ?? "dawn" }
    static func random() -> String { all.randomElement() ?? "dawn" }
}

/// A scene painting behind the duel, darkened where the cards sit: a wash over the whole picture, a deeper
/// pool over the board column, and shaded edges under the side columns, so gems and rules text keep their contrast.
struct SceneBackdrop: View {
    let name: String
    var body: some View {
        let ink = Color(hex: "#0a0710")
        GeometryReader { g in
            Image("bg_\(name)")
                .resizable()
                .scaledToFill()
                .frame(width: g.size.width, height: g.size.height)
                .clipped()
                .saturation(0.9)
                .overlay(ink.opacity(0.32))
                .overlay(RadialGradient(colors: [ink.opacity(0.62), ink.opacity(0.5), ink.opacity(0)],
                                        center: UnitPoint(x: 0.5, y: 0.5), startRadius: g.size.width * 0.1, endRadius: g.size.width * 0.62))
                .overlay(LinearGradient(stops: [.init(color: ink.opacity(0.7), location: 0), .init(color: ink.opacity(0), location: 0.1),
                                                .init(color: ink.opacity(0), location: 0.9), .init(color: ink.opacity(0.7), location: 1)],
                                        startPoint: .leading, endPoint: .trailing))
                .overlay(LinearGradient(stops: [.init(color: ink.opacity(0.35), location: 0), .init(color: ink.opacity(0), location: 0.2),
                                                .init(color: ink.opacity(0), location: 0.65), .init(color: ink.opacity(0.55), location: 1)],
                                        startPoint: .top, endPoint: .bottom))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
