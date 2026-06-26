import SwiftUI

/// Scannable summary of the service analysis: matched activity, setup cost
/// estimate, candidate license names, confidence, and unverified items.
struct AnalysisSummaryCardView: View {
    var viewModel: JourneyViewModel

    private var summary: AnalysisSummary? {
        viewModel.analysisSummary
    }

    private var state: OutputStageState {
        if viewModel.recoverableError != nil && summary == nil {
            return .error
        }
        guard let summary else {
            return viewModel.isServiceBusy ? .loading : .empty
        }
        return summary.unverified.isEmpty ? .success : .partial
    }

    var body: some View {
        OutputStageContainerView(
            title: "Activity analysis",
            subtitle: "What Irshad understood about your business",
            systemImage: "sparkles.rectangle.stack",
            state: state,
            hasContent: summary != nil,
            loadingLabel: "Analyzing…",
            emptyLabel: "Analysis appears once enough business details are captured.",
            partialNote: "Some items below still need confirmation.",
            recoverableError: viewModel.recoverableError,
            onRetry: { viewModel.retryCurrentStep() }
        ) {
            if let summary {
                content(for: summary)
            }
        }
    }

    @ViewBuilder
    private func content(for summary: AnalysisSummary) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            if !summary.matchedActivities.isEmpty {
                VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                    Text("Matched activity")
                        .font(IrshadTheme.Typography.statusMicrocopy)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)

                    FlowLayout(spacing: IrshadTheme.Layout.spacingTight) {
                        ForEach(summary.matchedActivities) { activity in
                            StatusPill(activity.label, systemImage: "checkmark.seal.fill", tone: .secondary)
                        }
                    }
                }
            }

            if let cost = summary.estSetupCostRange, !cost.isEmpty {
                OutputDetailRow(
                    label: "Estimated setup cost",
                    value: cost,
                    systemImage: "banknote",
                    accessory: AnyView(TrustBadge(status: .estimated))
                )
            }

            if !summary.candidateLicenses.isEmpty {
                TextListSection(
                    title: "Candidate licenses",
                    icon: "doc.badge.gearshape",
                    tint: IrshadTheme.Colors.primaryAccent,
                    items: summary.candidateLicenses
                )
            }

            OutputConfidenceView(confidence: summary.confidence ?? viewModel.confidence)

            if !summary.unverified.isEmpty {
                TextListSection(
                    title: "Still unverified",
                    icon: "exclamationmark.triangle.fill",
                    tint: IrshadTheme.Colors.warning,
                    items: summary.unverified
                )
            }

            OutputFactList(title: "Captured evidence", facts: viewModel.estimatedFacts)
        }
    }
}
