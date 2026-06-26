import CoreText
import Foundation

enum FontRegistrar {
    private static let bundledFonts = [
        "BricolageGrotesque-Regular",
        "BricolageGrotesque-Medium",
        "BricolageGrotesque-SemiBold",
        "BricolageGrotesque-Bold"
    ]

    static func registerBundledFonts() {
        bundledFonts.forEach { fontName in
            let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: fontName, withExtension: "ttf")

            guard let fontURL else {
                return
            }

            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
