import SwiftUI

struct CurrentPromptView: View {
    var currentPrompt: String?
    var framingMessage: String?
    var currentAssistantMessage: String?
    var language: AppLanguage = .en
    var isServiceBusy: Bool
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
            if isServiceBusy {
                ProgressView()
                    .controlSize(.small)
                    .tint(IrshadTheme.Colors.primaryAccent)
                    .accessibilityLabel(Text(updatingAccessibilityLabel))
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
        .animation(IrshadTheme.Animations.progressTransition, value: isServiceBusy)
    }

    private var supportingMessage: String? {
        guard isServiceBusy else {
            return nil
        }

        switch language {
        case .ar:
            return "نبقي خطوتك الحالية كما هي أثناء التحديث."
        case .en:
            return "We will keep your current step while updating."
        }
    }

    private var fallbackMessage: String {
        switch (journeyStatus, language) {
        case (.empty, .ar):
            "أخبر إرشاد بما تريد بناءه في الإمارات."
        case (.empty, .en):
            "Tell Irshad what you want to build in the UAE."
        case (.preparing, .ar):
            "نجهز رحلتك."
        case (.preparing, .en):
            "Preparing your journey."
        case (.collecting, .ar):
            "إرشاد جاهز للتفصيل التالي."
        case (.collecting, .en):
            "Irshad is ready for the next detail."
        case (.processing, .ar):
            "نراجع إجاباتك."
        case (.processing, .en):
            "Reviewing your answers."
        case (.gateOpen, .ar):
            "مدخلاتك جاهزة للإرشاد."
        case (.gateOpen, .en):
            "Your input is ready for guidance."
        case (.showingResults, .ar):
            "إرشادك جاهز للمراجعة."
        case (.showingResults, .en):
            "Your guidance is ready to review."
        case (.complete, .ar):
            "اكتملت خطتك."
        case (.complete, .en):
            "Your plan is complete."
        case (.partial, .ar):
            "بعض الإرشادات جاهزة، وما زالت هناك تفاصيل قليلة معلقة."
        case (.partial, .en):
            "Some guidance is ready, and a few details are still pending."
        case (.failed, .ar):
            "هناك ما يحتاج انتباهك. خطوتك الحالية ما زالت محفوظة."
        case (.failed, .en):
            "Something needs your attention. Your current step is still saved."
        }
    }

    private var updatingAccessibilityLabel: String {
        switch language {
        case .ar:
            return "جار تحديث الرحلة"
        case .en:
            return "Updating the journey"
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
        isServiceBusy: true,
        journeyStatus: .collecting
    )
    .padding()
}
