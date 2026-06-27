import Combine
import SwiftUI

struct ResultLoadingProgressView: View {
    let title: String
    let systemImage: String
    let messages: [String]
    var duration: TimeInterval = 8.0
    var reduceMotion: Bool

    @State private var startedAt = Date()
    @State private var progress = 0.0
    @State private var messageIndex = 0

    private let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    private var currentMessage: String {
        guard !messages.isEmpty else { return "Preparing your recommendation" }
        return messages[min(messageIndex, messages.count - 1)]
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
            circularProgress

            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                Label(title, systemImage: systemImage)
                    .font(IrshadTheme.Typography.cardTitle)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .labelStyle(.titleAndIcon)

                Text(currentMessage)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(reduceMotion ? .identity : .opacity)
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: .infinity)

            ProgressView(value: progress, total: 1)
                .progressViewStyle(.linear)
                .tint(IrshadTheme.Colors.primaryAccent)
                .accessibilityHidden(true)

            StatusPill("Preparing", tone: .active, showsSpinner: !reduceMotion)
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .irshadShadow(IrshadTheme.Shadows.cardShadow)
        .onAppear(perform: restart)
        .onReceive(timer) { now in
            updateProgress(at: now)
        }
        .animation(reduceMotion ? nil : IrshadTheme.Animations.progressTransition, value: progress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(currentMessage))
    }

    private var circularProgress: some View {
        ZStack {
            Circle()
                .stroke(IrshadTheme.Colors.progressTrack, lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    IrshadTheme.Colors.primaryAccent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                .symbolEffect(.pulse, options: .repeating, value: !reduceMotion)
                .accessibilityHidden(true)
        }
        .frame(width: 142, height: 142)
        .accessibilityHidden(true)
    }

    private func restart() {
        startedAt = Date()
        progress = 0
        messageIndex = 0
    }

    private func updateProgress(at now: Date) {
        let elapsed = now.timeIntervalSince(startedAt)
        let normalized = min(max(elapsed / duration, 0), 1)
        progress = normalized

        guard !messages.isEmpty else { return }
        let nextIndex = min(Int(elapsed / (duration / Double(messages.count))), messages.count - 1)
        guard nextIndex != messageIndex else { return }

        if reduceMotion {
            messageIndex = nextIndex
        } else {
            withAnimation(IrshadTheme.Animations.cardReveal) {
                messageIndex = nextIndex
            }
        }
    }
}

#Preview {
    ResultLoadingProgressView(
        title: "Finding your license",
        systemImage: "doc.badge.gearshape",
        messages: [
            "Checking license fit",
            "Comparing official requirements",
            "Matching your business activity",
            "Preparing the best option"
        ],
        reduceMotion: false
    )
    .padding()
    .background(IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea())
}
