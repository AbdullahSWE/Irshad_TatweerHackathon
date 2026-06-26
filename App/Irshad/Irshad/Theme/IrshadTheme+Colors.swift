import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension IrshadTheme {
    enum Colors {
        static let primaryAccent = Color(red: 0.05, green: 0.32, blue: 0.72)
        static let supportingAccent = Color(red: 0.04, green: 0.49, blue: 0.82)
        static let softHighlight = Color(red: 0.43, green: 0.72, blue: 0.96)

        static let success = Color.green
        static let warning = Color.orange
        static let secondaryStatus = Color(red: 0.39, green: 0.57, blue: 0.50)

        static let canvas = Color(.systemBackground)
        static let surface = Color(.systemBackground)
        static let surfaceElevated = Color(.secondarySystemBackground)
        static let surfaceTint = primaryAccent.opacity(0.07)
        static let indigoTint = supportingAccent.opacity(0.06)

        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(.tertiaryLabel)
        static let separator = Color(.separator).opacity(0.45)
        static let progressTrack = Color(.tertiaryLabel).opacity(0.35)

        static let verifiedTint = Color.green.opacity(0.12)
        static let estimatedTint = Color.blue.opacity(0.11)
        static let unverifiedTint = Color.orange.opacity(0.12)
        static let missingTint = Color.red.opacity(0.10)
        static let unknownTint = Color.gray.opacity(0.12)

        static let appBackgroundGradient = LinearGradient(
            gradient: Gradient(colors: [
                backgroundTop,
                backgroundMiddle,
                backgroundBottom
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let activeVoiceRadialGradient = RadialGradient(
            gradient: Gradient(colors: [
                voiceRadialCenter,
                voiceRadialBlue,
                voiceRadialIndigo
            ]),
            center: .center,
            startRadius: 4,
            endRadius: 168
        )

        static let analysisGlowGradient = LinearGradient(
            gradient: Gradient(colors: [
                primaryAccent.opacity(0.18),
                supportingAccent.opacity(0.12),
                softHighlight.opacity(0.08)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let appBackgroundGradientDark = LinearGradient(
            gradient: Gradient(colors: [
                darkBackgroundTop,
                darkBackgroundMiddle,
                darkBackgroundBottom
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let activeVoiceRadialGradientDark = RadialGradient(
            gradient: Gradient(colors: [
                darkVoiceRadialCenter,
                darkVoiceRadialBlue,
                darkVoiceRadialIndigo
            ]),
            center: .center,
            startRadius: 4,
            endRadius: 168
        )

        static let analysisGlowGradientDark = LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.34),
                Color.indigo.opacity(0.22),
                Color.cyan.opacity(0.14)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let glassSurface = Color(.systemBackground).opacity(0.82)
        static let elevatedGlassSurface = Color(.secondarySystemBackground).opacity(0.88)
        static let voiceHalo = primaryAccent.opacity(0.22)
        static let listeningHalo = softHighlight.opacity(0.20)

        private static let backgroundTop = adaptiveColor(light: .white, dark: .systemBackground)
        private static let backgroundMiddle = adaptiveColor(
            light: UIColor(red: 0.43, green: 0.72, blue: 0.96, alpha: 0.12),
            dark: UIColor(red: 0.04, green: 0.49, blue: 0.82, alpha: 0.16)
        )
        private static let backgroundBottom = adaptiveColor(light: .white, dark: .systemBackground)
        private static let voiceRadialCenter = adaptiveColor(light: .white, dark: .secondarySystemBackground)
        private static let voiceRadialBlue = adaptiveColor(
            light: UIColor(red: 0.05, green: 0.32, blue: 0.72, alpha: 0.18),
            dark: UIColor(red: 0.04, green: 0.49, blue: 0.82, alpha: 0.28)
        )
        private static let voiceRadialIndigo = adaptiveColor(
            light: UIColor(red: 0.43, green: 0.72, blue: 0.96, alpha: 0.16),
            dark: UIColor(red: 0.43, green: 0.72, blue: 0.96, alpha: 0.20)
        )

        private static let darkBackgroundTop = Color(.systemBackground)
        private static let darkBackgroundMiddle = supportingAccent.opacity(0.14)
        private static let darkBackgroundBottom = Color(.systemBackground)
        private static let darkVoiceRadialCenter = Color(.secondarySystemBackground)
        private static let darkVoiceRadialBlue = primaryAccent.opacity(0.28)
        private static let darkVoiceRadialIndigo = softHighlight.opacity(0.20)
    }
}

private func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
    #if canImport(UIKit)
    Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? dark : light
    })
    #else
    Color.white
    #endif
}
