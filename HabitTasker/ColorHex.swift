import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RRGGBB
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // AARRGGBB
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 80, 200, 120) // fallback
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

enum AppPalette {
    static let background = Color(hex: "0B0F14")
    static let card = Color(hex: "121A24")
    static let card2 = Color(hex: "0F1620")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)

    static let done = Color(hex: "2ECC71")   // зелёный
    static let empty = Color.white.opacity(0.20)
    static let skip = Color.white.opacity(0.35)
    static let fail = Color(hex: "C0392B")   // красный
    static let todayRing = Color(hex: "F1C40F") // желтая обводка
}

