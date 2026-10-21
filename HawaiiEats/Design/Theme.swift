import SwiftUI

/// Hawaii's landscape palette, light only (Nick's pick, 2026-10-19; no team or university marks): ocean #0A4D68 (8.6:1 on the
/// sand), hibiscus #C8102E (5.6:1, white text on it 5.9:1), sand #FFF6E5, lava #1E1E1E text, and pineapple #FFC845 only as a fill
/// under dark text (white on it is 1.5:1). The names `green`/`gold` are kept from Wisconsin Eats so the shared views read the same;
/// here `green` is ocean, `gold` is pineapple and `pine` is hibiscus.
enum Theme {
    static let green = Color(hex: 0x0A4D68)      // ocean: titles, tint, primary text accents
    static let green2 = Color(hex: 0x0B6584)
    static let gold = Color(hex: 0xFFC845)       // pineapple: fills only
    static let goldSoft = Color(hex: 0xFFE9B0)
    static let goldEdge = Color(hex: 0xC9A033)   // the Hawaii guide cards' border
    static let pine = Color(hex: 0xC8102E)       // hibiscus: chips with white text, the hand-checked pins
    static let ink = Color(hex: 0x1E1E1E)
    static let ink2 = Color(hex: 0x383430)
    static let muted = Color(hex: 0x5C564E)
    static let cream = Color(hex: 0xFFF6E5)
    static let surface = Color(hex: 0xFFFCF5)
    static let surface2 = Color(hex: 0xFBEFD9)
    static let surface3 = Color(hex: 0xF2E2C4)
    static let rule = Color(hex: 0xEEDFC4)
    static let rule2 = Color(hex: 0xD6C3A1)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A small uppercase label: "SHAVE ICE", "JAMES BEARD WINNER".
struct Chip: View {
    enum Style { case gold, green, pine, plain, dashed }
    let text: String
    var style: Style = .plain

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .foregroundStyle(style == .green || style == .pine ? Color.white : style == .dashed ? Theme.muted : Theme.green)
            .background {
                RoundedRectangle(cornerRadius: 5).fill(style == .gold ? Theme.goldSoft : style == .green ? Theme.green : style == .pine ? Theme.pine
                                                       : style == .dashed ? .clear : Theme.surface2)
            }
            .overlay {
                if style == .dashed { RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.rule2, style: StrokeStyle(lineWidth: 1, dash: [3, 2])) }
            }
            .accessibilityLabel(text)
    }
}

/// The island chain, Niʻihau to Hawaiʻi Island, drawn once under the Home header: sand islands on an ocean band (State GIS
/// coastlines, Design/IslandShapes.swift). Height-led: the chain keeps its true shape and sits centred in the band.
struct RidgeLine: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.green))
            let pad: CGFloat = 6
            let h = size.height - 2 * pad, w = min(size.width - 2 * pad, h / IslandShapes.chainAspect)
            let x0 = (size.width - w) / 2, y0 = pad + (h - w * IslandShapes.chainAspect) / 2
            var land = Path()
            for ring in IslandShapes.chain {
                guard let first = ring.first else { continue }
                land.move(to: CGPoint(x: x0 + first.0 * w, y: y0 + first.1 * w))
                for (x, y) in ring.dropFirst() { land.addLine(to: CGPoint(x: x0 + x * w, y: y0 + y * w)) }
                land.closeSubpath()
            }
            ctx.fill(land, with: .color(Theme.cream))
        }
        .accessibilityHidden(true)
    }
}

/// Condensed, heavy display type for titles and big numbers (the system font's compressed width). It scales with the
/// reader's text size, capped at 1.6× so a big number can't swallow its row.
struct DisplayFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .black
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight).width(.compressed))
    }
}

extension View {
    func displayFont(_ size: CGFloat, weight: Font.Weight = .black) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }
}

extension View {
    /// An inline navigation title in the display type. UINavigationBar.appearance() didn't reach every SwiftUI bar on iOS 27
    /// (the Map title went from compressed blue to plain black after a push and pop; place titles were always plain), so the
    /// title is our own view in the bar. The navigation title is still set, for the back button and VoiceOver.
    func inlineTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).displayFont(19, weight: .heavy).foregroundStyle(Theme.green)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}
