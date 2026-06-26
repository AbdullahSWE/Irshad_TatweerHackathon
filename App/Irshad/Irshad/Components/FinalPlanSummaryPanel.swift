import SwiftUI

/// Grouped read-only summary of a finished plan. Leads with the single immediate
/// next action to create momentum, then lays out the supporting detail groups:
/// business summary, recommended licence, estimated cost, timeline, documents,
/// approvals, banks, confidence, unverified items, and the guidance disclaimer.
///
/// Displays only what it is given — nothing is invented and uncertainty labels
/// (Estimated / Unverified / Guidance only) always stay visible. The same panel
/// backs both the live final plan and a reopened saved plan, so it takes an
/// explicit `FinalPlan` plus optional fallbacks rather than reading a ViewModel.
struct FinalPlanSummaryPanel: View {
    let plan: FinalPlan
    var licenseFallback: String?
    var licenseIssuerFallback: String?
    var approvalsFallback: [String]
    var banksFallback: [String]
    var confidenceFallback: Double?
    var unverifiedFacts: [TrustFact]
    var guidanceDisclaimer: String

    init(
        plan: FinalPlan,
        licenseFallback: String? = nil,
        licenseIssuerFallback: String? = nil,
        approvalsFallback: [String] = [],
        banksFallback: [String] = [],
        confidenceFallback: Double? = nil,
        unverifiedFacts: [TrustFact] = [],
        guidanceDisclaimer: String = ""
    ) {
        self.plan = plan
        self.licenseFallback = licenseFallback
        self.licenseIssuerFallback = licenseIssuerFallback
        self.approvalsFallback = approvalsFallback
        self.banksFallback = banksFallback
        self.confidenceFallback = confidenceFallback
        self.unverifiedFacts = unverifiedFacts
        self.guidanceDisclaimer = guidanceDisclaimer
    }

    // MARK: Derived groups (only shown when present)

    private var businessSummary: String? {
        plan.metadata.string(for: ["business_summary", "businessSummary", "summary", "business"])
    }

    private var recommendedLicense: String? {
        plan.metadata.string(for: ["recommended_license", "recommendedLicense", "license", "licence"])
            ?? licenseFallback
    }

    private var licenseIssuer: String? {
        plan.metadata.string(for: ["license_issuer", "licenseIssuer", "issuer"])
            ?? licenseIssuerFallback
    }

    private var documents: [String] {
        plan.metadata.stringArray(for: ["documents", "docs", "docs_needed", "docsNeeded"])
    }

    private var approvals: [String] {
        let fromPlan = plan.metadata.stringArray(for: ["approvals", "required_approvals", "requiredApprovals"])
        return fromPlan.isEmpty ? approvalsFallback : fromPlan
    }

    private var banks: [String] {
        let fromPlan = plan.metadata.stringArray(for: ["banks", "recommended_banks", "recommendedBanks"])
        return fromPlan.isEmpty ? banksFallback : fromPlan
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            if let nextAction = plan.nextAction, !nextAction.isEmpty {
                immediateNextAction(nextAction)
            }

            if let businessSummary, !businessSummary.isEmpty {
                Text(businessSummary)
                    .font(IrshadTheme.Typography.primaryBody)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            keyFacts

            if !documents.isEmpty {
                TextListSection(title: "Documents", icon: "doc.text.fill", tint: IrshadTheme.Colors.primaryAccent, items: documents)
            }

            if !approvals.isEmpty {
                TextListSection(title: "Approvals", icon: "checkmark.shield.fill", tint: IrshadTheme.Colors.primaryAccent, items: approvals)
            }

            if !banks.isEmpty {
                TextListSection(title: "Banks", icon: "building.columns", tint: IrshadTheme.Colors.primaryAccent, items: banks)
            }

            OutputConfidenceView(confidence: plan.confidence ?? confidenceFallback)

            if !plan.unverified.isEmpty {
                TextListSection(
                    title: "Unverified items",
                    icon: "exclamationmark.triangle.fill",
                    tint: IrshadTheme.Colors.warning,
                    items: plan.unverified
                )
            }

            OutputFactList(title: "Still to confirm", facts: unverifiedFacts)

            if !guidanceDisclaimer.isEmpty {
                guidanceNote
            }
        }
    }

    private func immediateNextAction(_ action: String) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            Label("Do this first", systemImage: "flag.checkered")
                .font(IrshadTheme.Typography.statusMicrocopy)
                .foregroundStyle(IrshadTheme.Colors.primaryAccent)

            InfoBannerView(message: action, systemImage: "arrow.forward.circle.fill", tone: .info)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Immediate next action"))
        .accessibilityValue(Text(action))
    }

    @ViewBuilder
    private var keyFacts: some View {
        let hasFacts = (recommendedLicense?.isEmpty == false)
            || (plan.totalEstCost?.isEmpty == false)
            || (plan.totalTimeline?.isEmpty == false)

        if hasFacts {
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
        }
    }

    private var guidanceNote: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingTight) {
            TrustBadge(status: .guidanceOnly)

            Text(guidanceDisclaimer)
                .font(IrshadTheme.Typography.statusMicrocopy)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(IrshadTheme.Layout.spacingStandard)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Guidance only"))
        .accessibilityValue(Text(guidanceDisclaimer))
    }
}
