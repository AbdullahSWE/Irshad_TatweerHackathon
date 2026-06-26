import SwiftUI

struct ProcessingOrbView: View {
    var symbolName: String
    var title: String
    var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbit = false

    init(symbolName: String = "sparkles", title: String = "Processing", isActive: Bool = true) {
        self.symbolName = symbolName
        self.title = title
        self.isActive = isActive
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(IrshadTheme.Colors.primaryAccent.opacity(0.12), lineWidth: 1)
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(orbit ? 8 : -8))

            Circle()
                .trim(from: 0.08, to: 0.34)
                .stroke(
                    IrshadTheme.Colors.softHighlight.opacity(isActive ? 0.75 : 0.32),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(orbit && !reduceMotion ? 168 : 18))

            Circle()
                .fill(IrshadTheme.Colors.activeVoiceRadialGradient)
                .frame(width: 96, height: 96)
                .overlay {
                    Circle()
                        .stroke(IrshadTheme.Colors.primaryAccent.opacity(0.22), lineWidth: 1)
                }
                .irshadShadow(IrshadTheme.Shadows.voiceHaloShadow)

            Image(systemName: symbolName)
                .font(.system(size: 30, weight: .semibold))
                .symbolEffect(.pulse, options: .repeating, value: isActive && !reduceMotion)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            IrshadTheme.Colors.primaryAccent,
                            IrshadTheme.Colors.softHighlight
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 148, height: 148)
        .opacity(isActive ? 1 : 0.78)
        .animation(reduceMotion ? IrshadTheme.Animations.orbMotionReduced : IrshadTheme.Animations.orbMotion, value: orbit)
        .onAppear {
            orbit = isActive
        }
        .onChange(of: isActive) { _, newValue in
            orbit = newValue
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isActive ? "Thinking" : "Idle"))
    }
}
