import SwiftUI

/// Final roadmap: the complete plan grouped into business summary, recommended
/// licence, estimated cost, documents, approvals, banks, timeline, immediate
/// next action, unverified items, and confidence. Displays only what the
/// ViewModel supplies — nothing is invented.
struct FinalRoadmapView: View {
    var viewModel: JourneyViewModel

    private var plan: FinalPlan? {
        viewModel.finalPlan
    }

    private var hasContent: Bool {
        plan != nil
    }

    private var state: OutputStageState {
        if viewModel.recoverableError != nil && plan == nil {
            return .error
        }
        guard let plan else {
            return viewModel.isServiceBusy ? .loading : .empty
        }
        return plan.unverified.isEmpty ? .success : .partial
    }

    // MARK: Derived groups (only shown when present)

    private var businessSummary: String? {
        plan?.metadata.string(for: ["business_summary", "businessSummary", "summary", "business"])
    }

    private var recommendedLicense: String? {
        plan?.metadata.string(for: ["recommended_license", "recommendedLicense", "license", "licence"])
            ?? viewModel.licenseRecommendation?.best?.type
    }

    private var licenseIssuer: String? {
        plan?.metadata.string(for: ["license_issuer", "licenseIssuer", "issuer"])
            ?? viewModel.licenseRecommendation?.best?.issuer
    }

    private var documents: [String] {
        let fromPlan = plan?.metadata.stringArray(for: ["documents", "docs", "docs_needed", "docsNeeded"]) ?? []
        return fromPlan
    }

    private var approvals: [String] {
        let fromPlan = plan?.metadata.stringArray(for: ["approvals", "required_approvals", "requiredApprovals"]) ?? []
        if !fromPlan.isEmpty {
            return fromPlan
        }
        return viewModel.licenseRecommendation?.best?.approvals ?? []
    }

    private var banks: [String] {
        let fromPlan = plan?.metadata.stringArray(for: ["banks", "recommended_banks", "recommendedBanks"]) ?? []
        if !fromPlan.isEmpty {
            return fromPlan
        }
        return viewModel.bankingRecommendations?.banks.map(\.name) ?? []
    }

    var body: some View {
        OutputStageContainerView(
            title: "Your roadmap",
            subtitle: "Everything Irshad pulled together",
            systemImage: "map",
            state: state,
            hasContent: hasContent,
            loadingLabel: "Building roadmap…",
            emptyLabel: "Your roadmap appears once the earlier stages are complete.",
            partialNote: "This plan includes items that are still unverified.",
            recoverableError: viewModel.recoverableError,
            onRetry: { viewModel.retryCurrentStep() }
        ) {
            if let plan {
                content(for: plan)
            }
        }
    }

    @ViewBuilder
    private func content(for plan: FinalPlan) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            if let businessSummary, !businessSummary.isEmpty {
                Text(businessSummary)
                    .font(IrshadTheme.Typography.primaryBodyDynamic)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let nextAction = plan.nextAction, !nextAction.isEmpty {
                InfoBannerView(message: nextAction, systemImage: "arrow.forward.circle.fill", tone: .info)
            }

            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                if let recommendedLicense, !recommendedLicense.isEmpty {
                    OutputDetailRow(
                        label: licenseIssuer.map { "Recommended licence · \($0)" } ?? "Recommended licence",
                        value: recommendedLicense,
                        systemImage: "doc.badge.gearshape"
                    )
                }

                if let cost = plan.totalEstCost, !cost.isEmpty {
                    OutputDetailRow(
                        label: "Estimated cost",
                        value: cost,
                        systemImage: "banknote",
                        accessory: AnyView(TrustBadge(status: .estimated))
                    )
                }

                if let timeline = plan.totalTimeline, !timeline.isEmpty {
                    OutputDetailRow(label: "Timeline", value: timeline, systemImage: "clock")
                }
            }
            .padding(IrshadTheme.Layout.spacingComfortable)
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(IrshadTheme.Colors.surfaceTint)
            )

            if !plan.roadmap.isEmpty {
                roadmapSteps(plan.roadmap)
            }

            if !documents.isEmpty {
                TextListSection(title: "Documents", icon: "doc.text.fill", tint: IrshadTheme.Colors.primaryAccent, items: documents)
            }

            if !approvals.isEmpty {
                TextListSection(title: "Approvals", icon: "checkmark.shield.fill", tint: IrshadTheme.Colors.primaryAccent, items: approvals)
            }

            if !banks.isEmpty {
                TextListSection(title: "Banks", icon: "building.columns", tint: IrshadTheme.Colors.primaryAccent, items: banks)
            }

            OutputConfidenceView(confidence: plan.confidence ?? viewModel.confidence)

            if !plan.unverified.isEmpty {
                TextListSection(title: "Unverified items", icon: "exclamationmark.triangle.fill", tint: IrshadTheme.Colors.warning, items: plan.unverified)
            }

            actions
        }
    }

    private func roadmapSteps(_ steps: [String]) -> some View {
        VStack(spacing: IrshadTheme.Layout.spacingTight) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                    Text("\(index + 1)")
                        .font(IrshadTheme.Typography.statusMicrocopyDynamic)
                        .foregroundStyle(.white)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(Circle().fill(IrshadTheme.Colors.primaryAccent))
                        .accessibilityHidden(true)

                    Text(step)
                        .font(IrshadTheme.Typography.primaryBodyDynamic)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(IrshadTheme.Layout.spacingStandard)
                .background(
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(IrshadTheme.Colors.surfaceElevated)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Step \(index + 1): \(step)"))
            }
        }
    }

    private var actions: some View {
        VStack(spacing: IrshadTheme.Layout.spacingTight) {
            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                Button {
                    viewModel.shareFinalPlan()
                } label: {
                    Label("Share plan", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(DynamicCardPrimaryButtonStyle())
                .accessibilityHint(Text(IrshadTheme.Accessibility.Hint.sharePlan))
                .help(IrshadTheme.Accessibility.Label.sharePlan)

                Button {
                    viewModel.copyFinalPlanSummary()
                } label: {
                    Label(isSummaryCopied ? "Copied" : "Copy summary", systemImage: "doc.on.doc")
                        .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(DynamicCardSecondaryButtonStyle())
                .accessibilityHint(Text(IrshadTheme.Accessibility.Hint.copySummary))
                .help(IrshadTheme.Accessibility.Label.copySummary)
            }

            Button {
                viewModel.continueWithAssistant()
            } label: {
                Label("Continue with assistant", systemImage: "bubble.left.and.text.bubble.right")
                    .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget)
            }
            .buttonStyle(DynamicCardSecondaryButtonStyle())
        }
    }

    private var isSummaryCopied: Bool {
        guard let action = plan?.nextAction else { return false }
        return viewModel.copiedItemID == action
    }
}
