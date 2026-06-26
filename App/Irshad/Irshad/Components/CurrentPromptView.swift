import SwiftUI

struct CurrentPromptView: View {
    var currentPrompt: String?
    var framingMessage: String?
    var currentAssistantMessage: String?
    var isBackendBusy: Bool
    var journeyStatus: JourneyStatus

    private var displayMessage: String {
        if let currentPrompt = normalized(currentPrompt) {
            return currentPrompt
        }

        if let framingMessage = normalized(framingMessage) {
            return framingMessage
        }

        if let currentAssistantMessage = normalized(currentAssistantMessage) {
            return currentAssistantMessage
        }

        return fallbackMessage
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingStandard) {
            if isBackendBusy {
                ProgressView()
                    .controlSize(.small)
                    .tint(IrshadTheme.Colors.primaryAccent)
                    .accessibilityLabel(Text("Updating journey"))
            }

            Text(displayMessage)
                .font(IrshadTheme.Typography.primaryBody)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if let supportingMessage {
                Text(supportingMessage)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
        .padding(.vertical, IrshadTheme.Layout.spacingSection)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface.opacity(0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .combine)
        .transition(IrshadTheme.Animations.cardRevealTransition)
        .animation(IrshadTheme.Animations.cardReveal, value: displayMessage)
        .animation(IrshadTheme.Animations.progressTransition, value: isBackendBusy)
    }

    private var supportingMessage: String? {
        guard isBackendBusy else {
            return nil
        }

        return "Keeping your current step in place while Irshad updates."
    }

    private var fallbackMessage: String {
        switch journeyStatus {
        case .empty:
            "Tell Irshad what you want to build in the UAE."
        case .preparing:
            "Preparing your journey."
        case .collecting:
            "Irshad is ready for the next detail."
        case .processing:
            "Reviewing your answers."
        case .gateOpen:
            "Your inputs are ready for guidance."
        case .showingResults:
            "Your guidance is ready to review."
        case .complete:
            "Your plan is complete."
        case .partial:
            "Some guidance is ready, with a few details still pending."
        case .failed:
            "Something needs attention. Your current step is still here."
        }
    }

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    CurrentPromptView(
        currentPrompt: "What kind of business are you planning to start?",
        framingMessage: nil,
        currentAssistantMessage: nil,
        isBackendBusy: true,
        journeyStatus: .collecting
    )
    .padding()
}
