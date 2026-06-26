import SwiftUI

/// Compact entry point to a saved plan. Surfaces the business title, a short
/// summary, checklist progress, the immediate next action, and a confidence /
/// trust status — then offers continue, share, and copy actions. Tapping the
/// card body reopens the full saved plan.
///
/// When no plan has been saved yet it renders a quiet placeholder rather than an
/// empty card, and the share/copy actions disable themselves.
struct SavedPlanCardView: View {
    var viewModel: JourneyViewModel

    private var summary: SavedPlanSummary? {
        viewModel.savedPlanSummary
    }

    private var plan: FinalPlan? {
        summary?.plan ?? viewModel.finalPlan
    }

    private var shortSummary: String? {
        plan?.metadata.string(for: ["business_summary", "businessSummary", "summary", "business"])
            ?? summary?.session.goalText
    }

    private var checklist: [NextStepChecklistItem] {
        summary?.checklist ?? viewModel.nextStepChecklist
    }

    private var doneCount: Int {
        checklist.filter(\.isDone).count
    }

    var body: some View {
        if let summary {
            card(summary)
        } else {
            placeholder
        }
    }

    private func card(_ summary: SavedPlanSummary) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            Button {
                viewModel.openSavedPlan()
            } label: {
                cardBody(summary)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens the full saved plan."))

            PlanShareToolbar(viewModel: viewModel)

            Button {
                viewModel.continueWithAssistant()
            } label: {
                Label("Continue with assistant", systemImage: "bubble.left.and.text.bubble.right")
                    .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget)
            }
            .buttonStyle(DynamicCardSecondaryButtonStyle())
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .background(cardSurface)
        .irshadShadow(IrshadTheme.Shadows.cardShadow)
        .transition(IrshadTheme.Animations.cardRevealTransition)
        .animation(IrshadTheme.Animations.cardReveal, value: doneCount)
    }

    private func cardBody(_ summary: SavedPlanSummary) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.title)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Saved \(DateFormatting.savedPlanTitleDate(summary.savedAt))")
                        .font(IrshadTheme.Typography.statusMicrocopy)
                        .foregroundStyle(IrshadTheme.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                confidencePill
            }

            if let shortSummary, !shortSummary.isEmpty {
                Text(shortSummary)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            checklistStatus

            if let action = plan?.nextAction, !action.isEmpty {
                InfoBannerView(message: action, systemImage: "arrow.forward.circle.fill", tone: .info)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(summary.title))
    }

    @ViewBuilder
    private var checklistStatus: some View {
        if !checklist.isEmpty {
            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                StatusPill(
                    "\(doneCount) of \(checklist.count) steps done",
                    systemImage: "checklist",
                    tone: doneCount == checklist.count ? .success : .active
                )
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var confidencePill: some View {
        let confidence = plan?.confidence ?? viewModel.confidence
        if let confidence {
            let normalized = min(max(confidence, 0), 1)
            StatusPill(
                confidenceLabel(normalized),
                systemImage: "gauge.with.dots.needle.67percent",
                tone: confidenceTone(normalized)
            )
        } else {
            StatusPill("Confidence pending", systemImage: "gauge.with.dots.needle.67percent", tone: .neutral)
        }
    }

    private func confidenceLabel(_ value: Double) -> String {
        switch value {
        case 0.8...: return "High"
        case 0.5..<0.8: return "Moderate"
        default: return "Low"
        }
    }

    private func confidenceTone(_ value: Double) -> StatusPill.Tone {
        switch value {
        case 0.8...: return .success
        case 0.5..<0.8: return .active
        default: return .warning
        }
    }

    private var placeholder: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
            Image(systemName: "tray")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(IrshadTheme.Colors.tertiaryText)
                .accessibilityHidden(true)

            Text("No saved plan yet. Finish your journey to save one here.")
                .font(IrshadTheme.Typography.secondaryLabel)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .background(cardSurface)
        .accessibilityElement(children: .combine)
    }

    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
            .fill(IrshadTheme.Colors.surface)
            .overlay {
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                    .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
            }
    }
}
