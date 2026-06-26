import SwiftUI

struct VoiceWaveformView: View {
    var levels: [CGFloat]
    var isActive: Bool
    var barCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    init(levels: [CGFloat] = [], isActive: Bool = false, barCount: Int = 18) {
        self.levels = levels
        self.isActive = isActive
        self.barCount = max(6, barCount)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(barGradient(for: index))
                    .frame(width: 5, height: height(for: index))
                    .opacity(isActive ? 1 : 0.62)
            }
        }
        .frame(height: IrshadTheme.Layout.waveformHeight)
        .animation(reduceMotion ? IrshadTheme.Animations.waveformResponseReduced : IrshadTheme.Animations.waveformResponse, value: phase)
        .onAppear {
            phase = isActive
        }
        .onChange(of: isActive) { _, newValue in
            phase = newValue
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Voice waveform"))
        .accessibilityValue(Text(isActive ? "Listening activity visible" : "Idle"))
    }

    private func height(for index: Int) -> CGFloat {
        let normalized = normalizedLevel(for: index)
        let motionBoost = isActive && !reduceMotion ? placeholderMotion(for: index) : 0
        let value = min(max(normalized + motionBoost, 0.12), 1)
        return 8 + value * (IrshadTheme.Layout.waveformHeight - 12)
    }

    private func normalizedLevel(for index: Int) -> CGFloat {
        guard !levels.isEmpty else {
            let center = CGFloat(barCount - 1) / 2
            let distance = abs(CGFloat(index) - center) / max(center, 1)
            return 0.28 + (1 - distance) * 0.36
        }

        let sourceIndex = min(index, levels.count - 1)
        return min(max(levels[sourceIndex], 0), 1)
    }

    private func placeholderMotion(for index: Int) -> CGFloat {
        let wave = sin(CGFloat(index) * 0.72 + (phase ? .pi : 0))
        return (wave + 1) * 0.13
    }

    private func barGradient(for index: Int) -> LinearGradient {
        let highlight = index.isMultiple(of: 3) ? IrshadTheme.Colors.softHighlight : IrshadTheme.Colors.primaryAccent
        return LinearGradient(
            colors: [
                highlight.opacity(isActive ? 0.92 : 0.45),
                IrshadTheme.Colors.supportingAccent.opacity(isActive ? 0.72 : 0.34)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
