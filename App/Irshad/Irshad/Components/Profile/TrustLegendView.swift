import SwiftUI

struct TrustLegendView: View {
    var verifiedFacts: [TrustFact] = []
    var estimatedFacts: [TrustFact] = []
    var unverifiedFacts: [TrustFact] = []
    var guidanceDisclaimer: String

    private let items: [LegendItem] = [
        LegendItem(status: .verified, text: "Confirmed from available evidence."),
        LegendItem(status: .estimated, text: "Calculated or inferred by the service."),
        LegendItem(status: .unverified, text: "Captured but not confirmed yet."),
        LegendItem(status: .missing, text: "Needed later, not provided yet."),
        LegendItem(status: .unknown, text: "Not enough information to know."),
        LegendItem(status: .guidanceOnly, text: "Advice, not a verified fact.")
    ]

    private var normalizedDisclaimer: String? {
        let trimmed = guidanceDisclaimer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            Text("Trust labels")
                .font(IrshadTheme.Typography.cardTitle)
                .foregroundStyle(IrshadTheme.Colors.primaryText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: IrshadTheme.Layout.spacingTight)], alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        TrustBadge(status: item.status)

                        Text(item.text)
                            .font(IrshadTheme.Typography.statusMicrocopy)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if hasTrustFacts {
                VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                    Text("Evidence captured")
                        .font(IrshadTheme.Typography.statusMicrocopy)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)

                    HStack(spacing: IrshadTheme.Layout.spacingTight) {
                        StatusPill("\(verifiedFacts.count) verified", systemImage: "checkmark.seal.fill", tone: .success)
                        StatusPill("\(estimatedFacts.count) estimated", systemImage: "chart.line.uptrend.xyaxis", tone: .active)
                        StatusPill("\(unverifiedFacts.count) unverified", systemImage: "exclamationmark.triangle.fill", tone: .warning)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    ForEach(sampleFacts) { fact in
                        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingTight) {
                            TrustBadge(status: fact.status)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(fact.label)
                                    .font(IrshadTheme.Typography.secondaryLabel)
                                    .foregroundStyle(IrshadTheme.Colors.primaryText)

                                Text(fact.value)
                                    .font(IrshadTheme.Typography.statusMicrocopy)
                                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(IrshadTheme.Layout.spacingTight)
                        .background(
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .fill(IrshadTheme.Colors.surfaceTint)
                        )
                    }
                }
            }

            if let normalizedDisclaimer {
                InfoBannerView(
                    message: normalizedDisclaimer,
                    systemImage: "lightbulb.fill",
                    tone: .info
                )
            }
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
    }

    private var hasTrustFacts: Bool {
        !verifiedFacts.isEmpty || !estimatedFacts.isEmpty || !unverifiedFacts.isEmpty
    }

    private var sampleFacts: [TrustFact] {
        Array((verifiedFacts + estimatedFacts + unverifiedFacts).prefix(3))
    }
}

private struct LegendItem: Identifiable {
    let status: TrustStatus
    let text: String

    var id: String {
        status.rawValue
    }
}
