import SwiftUI

/// License recommendation card: best license first, then alternatives. Shows
/// issuer, rationale, cost with trust status, timeline, approvals, pros/cons,
/// and the supplied verification status. License logic only — no verification
/// orchestration is performed here.
struct LicenseRecommendationCardView: View {
    var viewModel: JourneyViewModel

    private var recommendation: LicenseRecommendation? {
        viewModel.licenseRecommendation
    }

    private var hasContent: Bool {
        recommendation?.best != nil || !(recommendation?.alternatives.isEmpty ?? true)
    }

    private var state: OutputStageState {
        if viewModel.recoverableError != nil && !hasContent {
            return .error
        }
        guard hasContent else {
            return viewModel.isBackendBusy ? .loading : .empty
        }
        return recommendation?.best == nil ? .partial : .success
    }

    var body: some View {
        OutputStageContainerView(
            title: "License recommendation",
            subtitle: "The licence path that best fits your activity",
            systemImage: "doc.badge.gearshape",
            state: state,
            hasContent: hasContent,
            loadingLabel: "Matching licences…",
            emptyLabel: "License options appear after the activity analysis is ready.",
            partialNote: "No single best licence yet — review the options below.",
            recoverableError: viewModel.recoverableError,
            onRetry: { viewModel.retryCurrentStep() }
        ) {
            if let recommendation {
                VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
                    if let best = recommendation.best {
                        LicenseOptionView(option: best, isBest: true, viewModel: viewModel)
                    }

                    if !recommendation.alternatives.isEmpty {
                        Text("Alternatives")
                            .font(IrshadTheme.Typography.statusMicrocopy)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)

                        ForEach(recommendation.alternatives) { option in
                            LicenseOptionView(option: option, isBest: false, viewModel: viewModel)
                        }
                    }
                }
            }
        }
    }
}

private struct LicenseOptionView: View {
    let option: LicenseOption
    let isBest: Bool
    var viewModel: JourneyViewModel

    private var isExpanded: Bool {
        viewModel.expandedRecommendationIDs.contains(option.id)
    }

    private var whyRecommended: String? {
        option.metadata.string(for: ["why", "reason", "rationale", "why_recommended", "whyRecommended"])
    }

    private var verificationStatusLabel: String? {
        option.metadata.string(for: ["verification_status", "verificationStatus", "status_label", "statusLabel"])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                VStack(alignment: .leading, spacing: 4) {
                    if isBest {
                        StatusPill("Best fit", systemImage: "star.fill", tone: .success)
                    }

                    Text(option.type)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if let issuer = option.issuer, !issuer.isEmpty {
                        Text("Issued by \(issuer)")
                            .font(IrshadTheme.Typography.secondaryLabel)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let verificationStatusLabel {
                    StatusPill(verificationStatusLabel, systemImage: "shield.lefthalf.filled", tone: .secondary)
                }
            }

            if let whyRecommended {
                Text(whyRecommended)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let cost = option.estCost, !cost.isEmpty {
                OutputDetailRow(
                    label: "Estimated cost",
                    value: cost,
                    systemImage: "banknote",
                    accessory: AnyView(TrustBadge(status: option.costStatus))
                )
            }

            if let timeline = option.timeline, !timeline.isEmpty {
                OutputDetailRow(label: "Timeline", value: timeline, systemImage: "clock")
            }

            Button {
                if isExpanded {
                    viewModel.expandedRecommendationIDs.remove(option.id)
                } else {
                    viewModel.expandRecommendation(option.id)
                }
            } label: {
                Label(isExpanded ? "Hide details" : "Why this & trade-offs", systemImage: isExpanded ? "chevron.up" : "chevron.down")
            }
            .buttonStyle(DynamicCardSecondaryButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                    if !option.approvals.isEmpty {
                        TextListSection(title: "Approvals", icon: "checkmark.shield.fill", tint: IrshadTheme.Colors.primaryAccent, items: option.approvals)
                    }
                    if !option.pros.isEmpty {
                        TextListSection(title: "Pros", icon: "plus.circle.fill", tint: IrshadTheme.Colors.success, items: option.pros)
                    }
                    if !option.cons.isEmpty {
                        TextListSection(title: "Cons", icon: "minus.circle.fill", tint: IrshadTheme.Colors.warning, items: option.cons)
                    }
                    if let source = option.source, !source.isEmpty {
                        OutputDetailRow(label: "Source", value: source, systemImage: "link")
                    }
                }
                .padding(IrshadTheme.Layout.spacingStandard)
                .background(
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(IrshadTheme.Colors.surfaceTint)
                )
            }
        }
        .padding(IrshadTheme.Layout.spacingComfortable)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(isBest ? IrshadTheme.Colors.surfaceTint : IrshadTheme.Colors.surfaceElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(isBest ? IrshadTheme.Colors.primaryAccent.opacity(0.3) : IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
    }
}
