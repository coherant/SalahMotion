import SwiftUI

// MARK: - Fixed setup screen tokens (from docs/features/prayer-setup/SPEC.md)
// These are constant regardless of prayer time.

enum DesignTokens {
    static let ink:          Color = Color(hex: "#f4f1fa")
    static let muted:        Color = Color(hex: "#b8b2c8")
    static let faint:        Color = Color(hex: "#847e98")
    static let cardBg:       Color = Color(white: 1, opacity: 0.035)
    static let cardBorder:   Color = Color(white: 1, opacity: 0.07)
    static let darkOnAccent: Color = Color(hex: "#16142a")

    // Setup screen dark ground (constant — accent glow layered on top in the view)
    static let setupGround = LinearGradient(
        stops: [
            .init(color: Color(hex: "#181426"), location: 0.00),
            .init(color: Color(hex: "#131120"), location: 0.58),
            .init(color: Color(hex: "#0f0d18"), location: 1.00),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Neutral fallback (no accent glow — used as Option A)
    static let setupGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "#1a1730"), location: 0.00),
            .init(color: Color(hex: "#131120"), location: 0.60),
            .init(color: Color(hex: "#100e1b"), location: 1.00),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Composer sheet background themed — accent tint fading into dark
    static func sheetGradient(accent: Color) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: accent.opacity(0.16), location: 0.00),
                .init(color: Color(hex: "#1b1730"),  location: 0.42),
                .init(color: Color(hex: "#16142a"),  location: 1.00),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Hex color convenience

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double(rgb & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
