import SwiftUI

// MARK: - PrayerTime
// Source: docs/design-reference/theme.md

enum PrayerTime: String, CaseIterable, Identifiable {
    case fajr, dhuhr, asr, maghrib, isha
    var id: String { rawValue }

    // Approximate fixed-time mapping — replace with adhan calculation when ready.
    static var current: PrayerTime {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<6:   return .fajr
        case 6..<15:  return .dhuhr
        case 15..<18: return .asr
        case 18..<20: return .maghrib
        default:      return .isha
        }
    }

    var displayName: String {
        switch self {
        case .fajr:    return "Fajr"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }

    var displayTime: String {
        // Prayer instants are absolute UTC; render at the location's wall-clock time.
        Self.timeFormatter.timeZone = PrayerTimesEngine.shared.timeZone
        return Self.timeFormatter.string(from: scheduledDate)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var theme: PrayerTimeTheme {
        switch self {
        case .fajr:
            return PrayerTimeTheme(
                gradientStops: [
                    .init(color: Color(hex: "#0d1430"), location: 0.00),
                    .init(color: Color(hex: "#1c2147"), location: 0.36),
                    .init(color: Color(hex: "#46324f"), location: 0.64),
                    .init(color: Color(hex: "#8a5560"), location: 0.84),
                    .init(color: Color(hex: "#d18d6c"), location: 1.00),
                ],
                isLight:   false,
                ink:       Color(hex: "#f7eef0"),
                muted:     Color(hex: "#d8a9b4"),
                faint:     Color(hex: "#b78996"),
                faintest:  Color(hex: "#7e5f6b"),
                accent:    Color(hex: "#eaa9b2"),
                glow:      Color(hex: "#eaa9b2").opacity(0.85),
                orbA:      Color(hex: "#fce8ec"),
                orbB:      Color(hex: "#eaa9b2"),
                orbInk:    Color(hex: "#3a1e28").opacity(0.55)
            )
        case .dhuhr:
            return PrayerTimeTheme(
                gradientStops: [
                    .init(color: Color(hex: "#8fb8df"), location: 0.00),
                    .init(color: Color(hex: "#bcd6ec"), location: 0.42),
                    .init(color: Color(hex: "#e6eef4"), location: 0.78),
                    .init(color: Color(hex: "#f4efe6"), location: 1.00),
                ],
                isLight:   true,
                ink:       Color(hex: "#22323f"),
                muted:     Color(hex: "#4f6473"),
                faint:     Color(hex: "#6f8593"),
                faintest:  Color(hex: "#9aaeba"),
                accent:    Color(hex: "#d99a2a"),
                glow:      Color(hex: "#d99a2a").opacity(0.70),
                orbA:      Color(hex: "#fff6df"),
                orbB:      Color(hex: "#f0c24e"),
                orbInk:    Color(hex: "#463008").opacity(0.50)
            )
        case .asr:
            return PrayerTimeTheme(
                gradientStops: [
                    .init(color: Color(hex: "#2c3f63"), location: 0.00),
                    .init(color: Color(hex: "#5b5570"), location: 0.42),
                    .init(color: Color(hex: "#9c7158"), location: 0.74),
                    .init(color: Color(hex: "#d59a5c"), location: 1.00),
                ],
                isLight:   false,
                ink:       Color(hex: "#f7ede1"),
                muted:     Color(hex: "#d9b48f"),
                faint:     Color(hex: "#b3906f"),
                faintest:  Color(hex: "#806750"),
                accent:    Color(hex: "#e8b87e"),
                glow:      Color(hex: "#e8b87e").opacity(0.85),
                orbA:      Color(hex: "#fbeeda"),
                orbB:      Color(hex: "#e8b87e"),
                orbInk:    Color(hex: "#3c2816").opacity(0.50)
            )
        case .maghrib:
            return PrayerTimeTheme(
                gradientStops: [
                    .init(color: Color(hex: "#241640"), location: 0.00),
                    .init(color: Color(hex: "#6a2c54"), location: 0.36),
                    .init(color: Color(hex: "#b34440"), location: 0.60),
                    .init(color: Color(hex: "#db6e3a"), location: 0.80),
                    .init(color: Color(hex: "#f2a85a"), location: 1.00),
                ],
                isLight:   false,
                ink:       Color(hex: "#fbeede"),
                muted:     Color(hex: "#e6b095"),
                faint:     Color(hex: "#bd8771"),
                faintest:  Color(hex: "#8a6253"),
                accent:    Color(hex: "#f4a86a"),
                glow:      Color(hex: "#f4a86a").opacity(0.90),
                orbA:      Color(hex: "#ffe9d4"),
                orbB:      Color(hex: "#f4a86a"),
                orbInk:    Color(hex: "#401c1e").opacity(0.50)
            )
        case .isha:
            return PrayerTimeTheme(
                gradientStops: [
                    .init(color: Color(hex: "#201b3a"), location: 0.00),
                    .init(color: Color(hex: "#141224"), location: 0.50),
                    .init(color: Color(hex: "#0b0a14"), location: 1.00),
                ],
                isLight:   false,
                ink:       Color(hex: "#f4f1fa"),
                muted:     Color(hex: "#a39db6"),
                faint:     Color(hex: "#7d7790"),
                faintest:  Color(hex: "#4f4a63"),
                accent:    Color(hex: "#9a86c7"),
                glow:      Color(hex: "#9a86c7").opacity(0.90),
                orbA:      Color(hex: "#d6c9ee"),
                orbB:      Color(hex: "#9a86c7"),
                orbInk:    Color(hex: "#16142a").opacity(0.60)
            )
        }
    }

    // MARK: - Sunrise (not a prayer — used for Fajr waiting label)
    // Hardcoded London approximation — replace with Adhan calculation when ready.
    static var sunriseDisplayTime: String { "4:43 AM" }
    static var sunriseDate: Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 4; c.minute = 43
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: - Prayer times screen properties

    var phase: String {
        switch self {
        case .fajr:    return "Dawn"
        case .dhuhr:   return "Midday"
        case .asr:     return "Afternoon"
        case .maghrib: return "Evening"
        case .isha:    return "Night"
        }
    }

    var arabic: String {
        switch self {
        case .fajr:    return "الفجر"
        case .dhuhr:   return "الظهر"
        case .asr:     return "العصر"
        case .maghrib: return "المغرب"
        case .isha:    return "العشاء"
        }
    }

    // How far the day-progress rail is filled when this prayer is current
    var railFill: Double {
        switch self {
        case .fajr:    return 0.02
        case .dhuhr:   return 0.32
        case .asr:     return 0.52
        case .maghrib: return 0.66
        case .isha:    return 0.84
        }
    }

    // Today's prayer instant from the engine (real, location-based times).
    // Falls back to fixed times only before the engine's first computation.
    var scheduledDate: Date {
        PrayerTimesEngine.shared.date(for: self) ?? fallbackScheduledDate
    }

    // Fixed approximate times — used only as a fallback before computation.
    private var fallbackScheduledDate: Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        switch self {
        case .fajr:    c.hour = 4;  c.minute = 52
        case .dhuhr:   c.hour = 12; c.minute = 21
        case .asr:     c.hour = 15; c.minute = 47
        case .maghrib: c.hour = 18; c.minute = 58
        case .isha:    c.hour = 20; c.minute = 24
        }
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: - Setup screen accent (Column B — restrained wash, not the full in-prayer accent)
    // Source: docs/features/prayer-setup/setup-themed.md §3
    var setupAccent: Color {
        switch self {
        case .fajr:    return Color(hex: "#e8a07e")
        case .dhuhr:   return Color(hex: "#d6a13a")
        case .asr:     return Color(hex: "#e6a85a")
        case .maghrib: return Color(hex: "#f0a05a")
        case .isha:    return Color(hex: "#9a86c7")
        }
    }

    // MARK: - Background gradient view
    // Isha uses radial; all others use multi-stop linear.
    @ViewBuilder
    var backgroundGradient: some View {
        if self == .isha {
            RadialGradient(
                stops: theme.gradientStops,
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 0,
                endRadius: 600
            )
        } else {
            LinearGradient(
                stops: theme.gradientStops,
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - PrayerTimeTheme

struct PrayerTimeTheme {
    let gradientStops: [Gradient.Stop]
    let isLight:  Bool

    // Text ramp
    let ink:      Color   // primary text
    let muted:    Color   // secondary
    let faint:    Color   // tertiary / labels
    let faintest: Color   // ghost

    // Accent
    let accent:   Color
    let glow:     Color   // accent at opacity, for shadows/halos

    // Orb
    let orbA:     Color   // orb gradient light end
    let orbB:     Color   // orb gradient dark end
    let orbInk:   Color   // Arabic text on orb

    // MARK: Backward-compat aliases
    var gradientTop:    Color { gradientStops.first?.color ?? ink }
    var gradientBottom: Color { gradientStops.last?.color  ?? ink }
    var orbGlow:        Color { orbB }
    var textPrimary:    Color { orbInk }

    // Neutral fill/border that works for both light and dark themes
    var neutralFill:   Color { isLight ? Color(hex: "#243250").opacity(0.12) : Color.white.opacity(0.16) }
    var neutralBorder: Color { isLight ? Color(hex: "#243250").opacity(0.30) : Color.white.opacity(0.28) }
}
