import SwiftUI

// MARK: - Accessibility tokens

extension IrshadTheme {
    enum Accessibility {
        /// Upper bound for Dynamic Type so the largest accessibility sizes
        /// stay usable inside cards, docks, and the phase stepper instead of
        /// clipping or pushing primary actions off-screen.
        static let maxDynamicTypeSize: DynamicTypeSize = .accessibility3

        /// Minimum interactive target (44x44 pt per HIG).
        static let minimumTapTarget = IrshadTheme.Layout.minimumTapTarget

        // User-facing accessibility strings. Kept here so labels/hints stay
        // consistent wherever the same control is reused.
        enum Label {
            static let microphone = "Start voice input"
            static let stopListening = "Stop listening"
            static let retryVoice = "Retry voice input"
            static let sendAnswer = "Send answer"
            static let acceptTranscript = "Use this transcript"
            static let textFallback = "Type your answer instead"
            static let phaseProgress = "Journey progress"
            static let confidenceMeter = "Profile confidence"
            static let copySummary = "Copy summary"
            static let sharePlan = "Share plan"
            static let callNumber = "Call"
            static let openWebsite = "Open website"
            static let checklistItem = "Checklist item"
            static let retryStep = "Retry this step"
            static let cancelOperation = "Cancel"
            static let dismissBanner = "Dismiss"
        }

        enum Hint {
            static let microphone = "Starts listening to your business answer"
            static let stopListening = "Stops recording and prepares the transcript"
            static let retryVoice = "Starts listening again"
            static let sendAnswer = "Submits your answer and continues the journey"
            static let checklistItem = "Marks the step as done or not done"
            static let copySummary = "Copies the text to your clipboard"
            static let sharePlan = "Shares the plan with its trust labels"
        }
    }
}

// MARK: - Dynamic Type aware typography

extension IrshadTheme.Typography {
    // Scalable counterparts of the fixed-size tokens above. `Font.system(size:)`
    // does NOT respond to Dynamic Type; these `.system(_ style:)` fonts do, while
    // staying close to the design sizes. Use these in user-facing copy.
    static let largeTitleDynamic = Font.system(.largeTitle, design: .default).weight(.bold)
    static let sectionTitleDynamic = Font.system(.title, design: .default).weight(.semibold)
    static let stepIndicatorDynamic = Font.system(.title3, design: .default).weight(.semibold)
    static let primaryBodyDynamic = Font.system(.body, design: .default)
    static let cardTitleDynamic = Font.system(.headline, design: .default)
    static let secondaryLabelDynamic = Font.system(.subheadline, design: .default)
    static let statusMicrocopyDynamic = Font.system(.footnote, design: .default).weight(.medium)
}

// MARK: - Reduced motion

extension IrshadTheme.Animations {
    /// Returns `animation` normally, or a near-instant fallback when the user
    /// prefers reduced motion. Use for pulsing / orbiting / waveform motion so
    /// state stays understandable through color, icon, and label instead.
    static func resolved(
        _ animation: Animation,
        reduceMotion: Bool,
        fallback: Animation = reducedMotion
    ) -> Animation {
        reduceMotion ? fallback : animation
    }
}

// MARK: - View helpers

extension View {
    /// Guarantees at least a 44x44 pt hit area and makes the whole frame tappable.
    func irshadMinimumTapTarget(_ size: CGFloat = IrshadTheme.Accessibility.minimumTapTarget) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }

    /// Clamps Dynamic Type so very large accessibility sizes remain laid out.
    func irshadClampedDynamicType(
        _ maxSize: DynamicTypeSize = IrshadTheme.Accessibility.maxDynamicTypeSize
    ) -> some View {
        dynamicTypeSize(...maxSize)
    }

    /// Applies the journey's resolved layout direction (RTL for Arabic).
    func irshadLayoutDirection(_ direction: LayoutDirection) -> some View {
        environment(\.layoutDirection, direction)
    }

    /// Horizontally mirrors a directional glyph for RTL. Apply only to icons
    /// that imply direction (arrows, chevrons); never to neutral symbols.
    @ViewBuilder
    func irshadMirroredForRTL(_ isRTL: Bool) -> some View {
        if isRTL {
            scaleEffect(x: -1, y: 1, anchor: .center)
        } else {
            self
        }
    }

    /// Labels an icon-only control for VoiceOver and keeps the same visible
    /// help text (tooltip) on platforms that show it.
    func irshadIconButtonAccessibility(label: String, hint: String? = nil) -> some View {
        accessibilityLabel(Text(label))
            .accessibilityHint(Text(hint ?? ""))
            .help(label)
    }
}
