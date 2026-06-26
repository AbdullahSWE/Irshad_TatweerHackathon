import SwiftUI

extension IrshadTheme {
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    enum Layout {
        static let baseUnit: CGFloat = 4
        static let spacingTight: CGFloat = 8
        static let spacingStandard: CGFloat = 12
        static let spacingComfortable: CGFloat = 16
        static let spacingSection: CGFloat = 24
        static let spacingMajor: CGFloat = 32

        static let outerMarginCompact: CGFloat = 20
        static let outerMarginRegular: CGFloat = 24

        static let controlRadius: CGFloat = 16
        static let cardRadius: CGFloat = 24
        static let largeRadius: CGFloat = 32

        static let minimumTapTarget: CGFloat = 44
        static let voiceButtonSize: CGFloat = 96
        static let voiceButtonExpandedSize: CGFloat = 128
        static let bottomDockHeight: CGFloat = 132

        static let phaseDotSize: CGFloat = 10
        static let phaseStepperHeight: CGFloat = 46
        static let statusPillHeight: CGFloat = 30
        static let waveformHeight: CGFloat = 52

        static let cardHorizontalPadding: CGFloat = 16
        static let cardVerticalPadding: CGFloat = 18
        static let bannerPadding: CGFloat = 16
    }

    enum Shadows {
        static let ambientBlueShadow = Shadow(
            color: Colors.primaryAccent.opacity(0.16),
            radius: 34,
            x: 0,
            y: 18
        )

        static let floatingControlShadow = Shadow(
            color: Color.black.opacity(0.14),
            radius: 18,
            x: 0,
            y: 10
        )

        static let cardShadow = Shadow(
            color: Color.black.opacity(0.08),
            radius: 20,
            x: 0,
            y: 10
        )

        static let voiceHaloShadow = Shadow(
            color: Colors.primaryAccent.opacity(0.26),
            radius: 30,
            x: 0,
            y: 0
        )
    }
}

extension View {
    func irshadShadow(_ shadow: IrshadTheme.Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

