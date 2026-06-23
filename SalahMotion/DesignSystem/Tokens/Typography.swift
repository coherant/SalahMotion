import SwiftUI

// MARK: - Typography
//
// Three fonts, three roles — never substitute:
//   Display  → Cormorant Garamond (app name, screen titles, prayer names, large numerals)
//   UI       → Manrope            (body, buttons, labels, captions, eyebrows)
//   Arabic   → Amiri              (ALL Arabic text, always RTL)
//
// Font files live in SalahMotion/Resources/Fonts/
// Registration: FontRegistrar.registerAll() called once in SalahMotionApp.init()

enum Typography {

    // MARK: - Family names (PostScript)

    private enum PS {
        // Cormorant Garamond — 500/600 only (spec §0)
        static let displayM  = "CormorantGaramond-Medium"
        static let displaySB = "CormorantGaramond-SemiBold"

        // Manrope — 400/500/600/700 (spec §0)
        static let uiR  = "Manrope-Regular"
        static let uiM  = "Manrope-Medium"
        static let uiSB = "Manrope-SemiBold"
        static let uiB  = "Manrope-Bold"

        // Amiri — 400 only (spec §0)
        static let arR = "Amiri-Regular"
    }

    // MARK: - Base constructors

    static func display(_ size: CGFloat, weight: DisplayWeight = .regular) -> Font {
        Font.custom(weight.ps, size: size)
    }

    static func ui(_ size: CGFloat, weight: UIWeight = .regular) -> Font {
        Font.custom(weight.ps, size: size)
    }

    static func arabic(_ size: CGFloat) -> Font {
        Font.custom(PS.arR, size: size)
    }

    // MARK: - Weight shorthands

    enum DisplayWeight {
        case regular, medium, semibold
        var ps: String {
            switch self {
            case .regular:  return PS.displayM   // no Regular file — fall to Medium
            case .medium:   return PS.displayM
            case .semibold: return PS.displaySB
            }
        }
    }

    enum UIWeight {
        case regular, medium, semibold, bold
        var ps: String {
            switch self {
            case .regular:  return PS.uiR
            case .medium:   return PS.uiM
            case .semibold: return PS.uiSB
            case .bold:     return PS.uiB
            }
        }
    }

    // MARK: - Semantic display tokens (Cormorant Garamond)

    static var appName:        Font { display(32, weight: .semibold) }
    static var screenTitle:    Font { display(24, weight: .semibold) }
    static var sectionTitle:   Font { display(20, weight: .semibold) }
    static var prayerNameLg:   Font { display(32, weight: .semibold) }
    static var prayerName:     Font { display(28, weight: .semibold) }
    static var prayerNameSub:  Font { display(28, weight: .regular)  }
    static var pullQuote:      Font { display(18, weight: .medium)   }
    static var bodyDisplay:    Font { display(16, weight: .regular)  }
    static var recitation:     Font { display(14, weight: .regular)  }  // italic applied at call site
    static var captionDisplay: Font { display(12, weight: .regular)  }

    // MARK: - Semantic UI tokens (Manrope)

    static var body:       Font { ui(15)                       }
    static var bodyMed:    Font { ui(15, weight: .medium)      }
    static var bodySemi:   Font { ui(15, weight: .semibold)    }
    static var button:     Font { ui(17, weight: .semibold)    }
    static var buttonSm:   Font { ui(15, weight: .semibold)    }
    static var label:      Font { ui(13, weight: .medium)      }
    static var labelSm:    Font { ui(11, weight: .medium)      }
    static var caption:    Font { ui(12)                       }
    static var captionMed: Font { ui(12, weight: .medium)      }
    static var eyebrow:    Font { ui(11, weight: .semibold)    }  // use with .eyebrowStyle()

    // MARK: - Semantic Arabic tokens (Amiri + RTL)

    static var arabicDisplay:  Font { arabic(32) }
    static var arabicTitle:    Font { arabic(28)              }
    static var arabicBody:     Font { arabic(18)              }
    static var arabicOrb:      Font { arabic(28)              }
    static var arabicLabel:    Font { arabic(14)              }
    static var arabicCaption:  Font { arabic(11)              }
    static var arabicSub:      Font { arabic(13)              }
}

// MARK: - Eyebrow modifier
// UPPERCASE + 2.5pt tracking + Manrope semibold

struct EyebrowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.eyebrow)
            .textCase(.uppercase)
            .tracking(2.5)
    }
}

extension View {
    func eyebrowStyle() -> some View { modifier(EyebrowStyle()) }
}

// MARK: - Arabic text modifier
// Applies Amiri font + RTL layout direction

struct ArabicTextStyle: ViewModifier {
    var size: CGFloat
    func body(content: Content) -> some View {
        content
            .font(Typography.arabic(size))
            .environment(\.layoutDirection, .rightToLeft)
    }
}

extension View {
    func arabicStyle(size: CGFloat) -> some View {
        modifier(ArabicTextStyle(size: size))
    }
}
