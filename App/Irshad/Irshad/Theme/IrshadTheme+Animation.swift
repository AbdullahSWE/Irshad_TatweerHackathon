import SwiftUI

extension IrshadTheme {
    enum Animations {
        static let listeningPulse = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
        static let listeningPulseReduced = Animation.linear(duration: 0.01)

        static let waveformResponse = Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)
        static let waveformResponseReduced = Animation.linear(duration: 0.01)

        static let progressTransition = Animation.easeInOut(duration: 0.30)
        static let orbMotion = Animation.easeInOut(duration: 4.2).repeatForever(autoreverses: true)
        static let orbMotionReduced = Animation.linear(duration: 0.01)

        static let cardReveal = Animation.easeOut(duration: 0.32)
        static let cardRevealTransition = AnyTransition.opacity.combined(with: .move(edge: .bottom))

        static let buttonFeedback = Animation.spring(
            response: 0.28,
            dampingFraction: 0.82,
            blendDuration: 0.08
        )

        static let reducedMotion = Animation.linear(duration: 0.01)
        static let staticState = Animation.linear(duration: 0.01)
    }
}

