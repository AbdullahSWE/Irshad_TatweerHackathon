import SwiftUI

/// Share / copy affordances for a finished plan. Exposes a primary "Share plan"
/// action and a secondary "Copy summary" action. Both are disabled with a clear
/// fallback note when no plan content is available, so the user never taps a
/// share that produces nothing.
///
/// The toolbar never builds the exported text itself — it only triggers the
/// ViewModel, which supplies a `SharePayload` that keeps every uncertainty label
/// intact.
struct PlanShareToolbar: View {
    var viewModel: JourneyViewModel

    /// A plan exists to share when either the live final plan or a reopened saved
    /// plan is present.
    private var plan: FinalPlan? {
        viewModel.finalPlan ?? viewModel.savedPlanSummary?.plan
    }

    private var isAvailable: Bool {
        plan != nil
    }

    private var isPreparing: Bool {
        viewModel.isBackendBusy && viewModel.sharePayload == nil
    }

    private var isSummaryCopied: Bool {
        guard let action = plan?.nextAction, !action.isEmpty else { return false }
        return viewModel.copiedItemID == action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                Button {
                    viewModel.shareFinalPlan()
                } label: {
                    Label(isPreparing ? "Preparing…" : "Share plan", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(DynamicCardPrimaryButtonStyle())
                .disabled(!isAvailable || isPreparing)
                .accessibilityLabel(Text("Share plan"))
                .accessibilityHint(Text("Shares the plan with uncertainty labels preserved."))

                Button {
                    viewModel.copyFinalPlanSummary()
                } label: {
                    Label(
                        isSummaryCopied ? "Copied" : "Copy summary",
                        systemImage: isSummaryCopied ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(DynamicCardSecondaryButtonStyle())
                .disabled(!isAvailable)
                .accessibilityLabel(Text(isSummaryCopied ? "Summary copied" : "Copy summary"))
            }
            .opacity(isAvailable ? 1 : 0.5)

            if !isAvailable {
                Text("Share and copy unlock once your plan is ready.")
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .animation(IrshadTheme.Animations.buttonFeedback, value: isSummaryCopied)
    }
}
