import SwiftUI

/// Full saved-plan presentation. Opens into the finished roadmap and keeps the
/// grouped plan sections readable: an immediate next action and summary panel up
/// top, the ordered roadmap, the next-step checklist, and the share toolbar.
///
/// All content comes from the ViewModel's saved plan (falling back to the live
/// final plan). Nothing is generated here, and uncertainty labels are always
/// carried through `FinalPlanSummaryPanel`. Presented as the saved-plan sheet.
struct SavedPlanView: View {
    var viewModel: JourneyViewModel

    private var summary: SavedPlanSummary? {
        viewModel.savedPlanSummary
    }

    private var plan: FinalPlan? {
        summary?.plan ?? viewModel.finalPlan
    }

    private var checklist: [NextStepChecklistItem] {
        summary?.checklist ?? viewModel.nextStepChecklist
    }

    private var navigationTitle: String {
        summary?.title ?? "Saved plan"
    }

    private var isPreparing: Bool {
        viewModel.isBackendBusy && plan == nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let plan {
                        readablePlan(plan)
                    } else if isPreparing {
                        loadingState
                    } else if let error = viewModel.recoverableError {
                        errorState(error)
                    } else {
                        emptyState
                    }
                }
                .padding(IrshadTheme.Layout.outerMarginCompact)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea())
            .environment(\.layoutDirection, viewModel.layoutDirection)
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        viewModel.continueWithAssistant()
                    }
                }
            }
        }
    }

    // MARK: Success / partial

    private func readablePlan(_ plan: FinalPlan) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingSection) {
            FinalPlanSummaryPanel(
                plan: plan,
                licenseFallback: viewModel.licenseRecommendation?.best?.type,
                licenseIssuerFallback: viewModel.licenseRecommendation?.best?.issuer,
                approvalsFallback: viewModel.licenseRecommendation?.best?.approvals ?? [],
                banksFallback: viewModel.bankingRecommendations?.banks.map(\.name) ?? [],
                confidenceFallback: viewModel.confidence,
                unverifiedFacts: viewModel.unverifiedFacts,
                guidanceDisclaimer: viewModel.guidanceDisclaimer
            )

            if !plan.roadmap.isEmpty {
                roadmapSection(plan.roadmap)
            }

            if !checklist.isEmpty {
                checklistSection
            }

            if let error = viewModel.recoverableError {
                InfoBannerView(
                    message: error.message,
                    systemImage: "exclamationmark.triangle.fill",
                    tone: .error,
                    actionTitle: "Retry",
                    onAction: { viewModel.retryCurrentStep() }
                )
                .accessibilityLabel(Text(error.title))
            }

            PlanShareToolbar(viewModel: viewModel)
        }
    }

    private func roadmapSection(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            sectionHeader("Your roadmap", systemImage: "map")

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
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            sectionHeader("Next steps", systemImage: "checklist")

            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(Array(checklist.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(item.isDone ? IrshadTheme.Colors.success : IrshadTheme.Colors.tertiaryText)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(index + 1). \(item.title)")
                                .font(IrshadTheme.Typography.secondaryLabelDynamic)
                                .foregroundStyle(IrshadTheme.Colors.primaryText)
                                .strikethrough(item.isDone, color: IrshadTheme.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            if let detail = item.detail, !detail.isEmpty {
                                Text(detail)
                                    .font(IrshadTheme.Typography.statusMicrocopyDynamic)
                                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(IrshadTheme.Layout.spacingStandard)
                    .background(
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                            .fill(item.isDone ? IrshadTheme.Colors.verifiedTint : IrshadTheme.Colors.surfaceElevated)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(Text(item.isDone ? "Done" : "Not done"))
                }
            }
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(IrshadTheme.Typography.sectionTitleDynamic)
            .foregroundStyle(IrshadTheme.Colors.primaryText)
    }

    // MARK: Empty / loading / error

    private var emptyState: some View {
        statusCard(
            systemImage: "tray",
            title: "No saved plan yet",
            message: "Your plan appears here once the journey is complete and saved."
        )
    }

    private var loadingState: some View {
        statusCard(
            systemImage: "hourglass",
            title: "Preparing your plan",
            message: "Hold on while Irshad finishes putting the roadmap together.",
            showsSpinner: true
        )
    }

    private func errorState(_ error: RecoverableError) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            statusCard(systemImage: "exclamationmark.triangle.fill", title: error.title, message: error.message)

            InfoBannerView(
                message: "Your earlier answers are safe.",
                systemImage: "checkmark.shield.fill",
                tone: .neutral,
                actionTitle: "Retry",
                onAction: { viewModel.retryCurrentStep() }
            )
        }
    }

    private func statusCard(
        systemImage: String,
        title: String,
        message: String,
        showsSpinner: Bool = false
    ) -> some View {
        VStack(spacing: IrshadTheme.Layout.spacingStandard) {
            if showsSpinner {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(IrshadTheme.Typography.cardTitleDynamic)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .multilineTextAlignment(.center)

            Text(message)
                .font(IrshadTheme.Typography.secondaryLabelDynamic)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(IrshadTheme.Layout.spacingSection)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .combine)
    }
}
