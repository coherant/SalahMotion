import CoreText
import Foundation

// Registers custom fonts from the app bundle at launch.
// Font files (.ttf) must be placed in SalahMotion/Resources/Fonts/
//
// Required files — 7 total, matches SPEC.md §0 font roles:
//   CormorantGaramond-Medium.ttf      (500)
//   CormorantGaramond-SemiBold.ttf    (600)
//   Manrope-Regular.ttf               (400)
//   Manrope-Medium.ttf                (500)
//   Manrope-SemiBold.ttf              (600)
//   Manrope-Bold.ttf                  (700)
//   Amiri-Regular.ttf                 (400)
//
// Download from Google Fonts:
//   https://fonts.google.com/specimen/Cormorant+Garamond
//   https://fonts.google.com/specimen/Manrope
//   https://fonts.google.com/specimen/Amiri

enum FontRegistrar {

    static func registerAll() {
        let files = [
            "CormorantGaramond-Medium",
            "CormorantGaramond-SemiBold",
            "Manrope-Regular",
            "Manrope-Medium",
            "Manrope-SemiBold",
            "Manrope-Bold",
            "Amiri-Regular",
        ]

        var missing: [String] = []
        var urls: [URL] = []

        for name in files {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                urls.append(url)
            } else {
                missing.append(name)
            }
        }

        if !urls.isEmpty {
            CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
        }

        if !missing.isEmpty {
            print("[FontRegistrar] ⚠️ Missing font files — falling back to system fonts:")
            missing.forEach { print("  • \($0).ttf") }
        } else {
            print("[FontRegistrar] ✅ All fonts registered")
        }
    }
}
