import SwiftUI

struct PhaseProgressBar: View {
    let progress: JourneyProgress?
    var isServiceBusy: Bool = false

    private var fractionComplete: CGFloat {
        guard let progress, progress.required > 0 else {
            return 0
        }

        return min(max(CGFloat(progress.filled) / CGFloat(progress.required), 0), 1)
    }

    private var accessibilityValue: String {
        guard let progress, progress.required > 0 else {
            return isServiceBusy ? "Preparing progress" : "No progress yet"
        }

        return "\(progress.filled) of \(progress.required) required details complete"
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(IrshadTheme.Colors.progressTrack)

                Capsule(style: .continuous)
                    .fill(IrshadTheme.Colors.primaryAccent)
                    .frame(width: max(proxy.size.width * fractionComplete, fillMinimumWidth))

                if isServiceBusy && progress == nil {
                    Capsule(style: .continuous)
                        .fill(IrshadTheme.Colors.primaryAccent.opacity(0.28))
                        .frame(width: proxy.size.width * 0.28)
                        .offset(x: proxy.size.width * 0.36)
                        .accessibilityHidden(true)
                }
            }
            .animation(IrshadTheme.Animations.progressTransition, value: fractionComplete)
            .animation(IrshadTheme.Animations.progressTransition, value: isServiceBusy)
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Journey progress"))
        .accessibilityValue(Text(accessibilityValue))
    }

    private var fillMinimumWidth: CGFloat {
        fractionComplete > 0 ? 6 : 0
    }
}

#Preview {
    VStack(spacing: IrshadTheme.Layout.spacingSection) {
        PhaseProgressBar(progress: JourneyProgress(filled: 3, required: 7, stagesDone: 2, stagesTotal: 12))
        PhaseProgressBar(progress: nil, isServiceBusy: true)
    }
    .padding()
}
