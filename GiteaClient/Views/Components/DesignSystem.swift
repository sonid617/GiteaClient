import SwiftUI

// MARK: - Design System Colors

extension Color {
    static let appBg = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.090, green: 0.098, blue: 0.102, alpha: 1) // #17191A
            : UIColor(red: 0.961, green: 0.957, blue: 0.949, alpha: 1) // #F5F4F2
    })
    static let appCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.129, green: 0.137, blue: 0.145, alpha: 1) // #212325
            : UIColor.white
    })
    static let appCardAlt = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.149, green: 0.157, blue: 0.165, alpha: 1) // #26282A
            : UIColor(red: 0.941, green: 0.937, blue: 0.925, alpha: 1) // #F0EFEC
    })
    static let appSep = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.09)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let appBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.07)
    })
    static let appText2 = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.604, green: 0.604, blue: 0.620, alpha: 1)
            : UIColor(red: 0.424, green: 0.424, blue: 0.439, alpha: 1)
    })
    static let appText3 = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.424, green: 0.424, blue: 0.439, alpha: 1)
            : UIColor(red: 0.627, green: 0.627, blue: 0.647, alpha: 1)
    })
    static let appOpen = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.243, green: 0.796, blue: 0.467, alpha: 1) // #3ECB77
            : UIColor(red: 0.133, green: 0.647, blue: 0.349, alpha: 1) // #22A559
    })
    static let appDanger = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.945, green: 0.447, blue: 0.459, alpha: 1) // #F17275
            : UIColor(red: 0.898, green: 0.282, blue: 0.302, alpha: 1) // #E5484D
    })
    static let appWarn = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.961, green: 0.651, blue: 0.137, alpha: 1) // #F5A623
            : UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1) // #F59E0B
    })
}

// MARK: - Avatar Colors (same palette as design)

private let avatarPalette: [Color] = [
    Color(red: 0.388, green: 0.400, blue: 0.945),
    Color(red: 0.925, green: 0.282, blue: 0.600),
    Color(red: 0.961, green: 0.620, blue: 0.043),
    Color(red: 0.086, green: 0.639, blue: 0.165),
    Color(red: 0.055, green: 0.647, blue: 0.914),
    Color(red: 0.937, green: 0.267, blue: 0.267),
    Color(red: 0.545, green: 0.361, blue: 0.969),
    Color(red: 0.078, green: 0.722, blue: 0.651),
]

func avatarColor(for login: String) -> Color {
    var h: UInt32 = 0
    for c in login.unicodeScalars { h = (h &* 31) &+ c.value }
    return avatarPalette[Int(h) % avatarPalette.count]
}

// MARK: - Language Colors

func languageColor(_ lang: String?) -> Color {
    guard let lang else { return Color.appText3 }
    switch lang {
    case "Swift":       return Color(red: 0.941, green: 0.318, blue: 0.220)
    case "Go":          return Color(red: 0.000, green: 0.678, blue: 0.847)
    case "TypeScript":  return Color(red: 0.192, green: 0.471, blue: 0.776)
    case "JavaScript":  return Color(red: 0.945, green: 0.878, blue: 0.353)
    case "Python":      return Color(red: 0.216, green: 0.447, blue: 0.647)
    case "HCL":         return Color(red: 0.518, green: 0.310, blue: 0.729)
    case "Kotlin":      return Color(red: 0.416, green: 0.306, blue: 0.804)
    case "Rust":        return Color(red: 0.659, green: 0.286, blue: 0.173)
    case "Ruby":        return Color(red: 0.702, green: 0.102, blue: 0.102)
    case "C++":         return Color(red: 0.361, green: 0.533, blue: 0.643)
    default:            return Color(red: 0.420, green: 0.420, blue: 0.440)
    }
}

// MARK: - Card modifier

struct DesignCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func designCard() -> some View { modifier(DesignCard()) }
}

// MARK: - Section header

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color.appText2)
            .tracking(0.4)
            .padding(.leading, 2)
    }
}
