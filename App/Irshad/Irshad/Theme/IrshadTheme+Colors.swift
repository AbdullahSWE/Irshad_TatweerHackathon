import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension IrshadTheme {
    enum Colors {
        static let primaryAccent = Color.blue
        static let supportingAccent = Color.indigo
        static let softHighlight = Color.cyan

        static let success = Color.green
        static let warning = Color.orange
        static let secondaryStatus = Color.purple

        static let canvas = Color(.systemBackground)
        static let surface = Color(.systemBackground)
        static let surfaceElevated = Color(.secondarySystemBackground)
        static let surfaceTint = Color.blue.opacity(0.06)
        static let indigoTint = Color.indigo.opacity(0.05)

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
                Color.blue.opacity(0.22),
                Color.indigo.opacity(0.14),
                Color.cyan.opacity(0.08)
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
        static let voiceHalo = Color.blue.opacity(0.24)
        static let listeningHalo = Color.cyan.opacity(0.18)

        private static let backgroundTop = adaptiveColor(light: .white, dark: .systemBackground)
        private static let backgroundMiddle = adaptiveColor(
            light: .systemBlue.withAlphaComponent(0.055),
            dark: .systemBlue.withAlphaComponent(0.13)
        )
        private static let backgroundBottom = adaptiveColor(light: .white, dark: .systemBackground)
        private static let voiceRadialCenter = adaptiveColor(light: .white, dark: .secondarySystemBackground)
        private static let voiceRadialBlue = adaptiveColor(
            light: .systemBlue.withAlphaComponent(0.18),
            dark: .systemBlue.withAlphaComponent(0.28)
        )
        private static let voiceRadialIndigo = adaptiveColor(
            light: .systemIndigo.withAlphaComponent(0.10),
            dark: .systemIndigo.withAlphaComponent(0.20)
        )

        private static let darkBackgroundTop = Color(.systemBackground)
        private static let darkBackgroundMiddle = Color.blue.opacity(0.13)
        private static let darkBackgroundBottom = Color(.systemBackground)
        private static let darkVoiceRadialCenter = Color(.secondarySystemBackground)
        private static let darkVoiceRadialBlue = Color.blue.opacity(0.28)
        private static let darkVoiceRadialIndigo = Color.indigo.opacity(0.20)
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
