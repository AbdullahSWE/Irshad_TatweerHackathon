import SwiftUI

struct IrshadBackgroundView: View {
    var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    init(isActive: Bool = false) {
        self.isActive = isActive
    }

    var body: some View {
        ZStack {
            IrshadTheme.Colors.appBackgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(IrshadTheme.Colors.primaryAccent.opacity(isActive ? 0.15 : 0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 54)
                .offset(x: -118, y: -210)
                .opacity(pulse ? 0.95 : 0.68)

            Circle()
                .fill(IrshadTheme.Colors.softHighlight.opacity(isActive ? 0.16 : 0.07))
                .frame(width: 230, height: 230)
                .blur(radius: 48)
                .offset(x: 128, y: 120)
                .opacity(pulse ? 0.72 : 0.52)

            RoundedRectangle(cornerRadius: IrshadTheme.Layout.largeRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceTint.opacity(isActive ? 1 : 0.72))
                .frame(width: 220, height: 360)
                .rotationEffect(.degrees(-18))
                .blur(radius: 62)
                .offset(x: 132, y: -168)
                .opacity(0.62)
        }
        .animation(reduceMotion ? IrshadTheme.Animations.listeningPulseReduced : IrshadTheme.Animations.listeningPulse, value: pulse)
        .onAppear {
            pulse = isActive
        }
        .onChange(of: isActive) { _, newValue in
            pulse = newValue
        }
        .accessibilityHidden(true)
    }
}
