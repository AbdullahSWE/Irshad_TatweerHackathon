import SwiftUI

struct RecommendationCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    var body: some View {
        DynamicCardSurface(card: card) {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                if let summary = card.bodyText {
                    Text(summary)
                        .font(IrshadTheme.Typography.primaryBody)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TrustBadgeRow(labels: trustBadgeLabels)

                if !card.options.isEmpty {
                    VStack(spacing: IrshadTheme.Layout.spacingTight) {
                        ForEach(card.options) { option in
                            RecommendationOptionView(option: option, viewModel: viewModel)
                        }
                    }
                } else {
                    RecommendationDetailPanel(
                        id: card.cardId,
                        isExpanded: viewModel.expandedRecommendationIDs.contains(card.cardId),
                        pros: card.metadata.stringArray(for: ["pros"]),
                        cons: card.metadata.stringArray(for: ["cons"]),
                        requirements: card.metadata.stringArray(for: ["requirements", "required_items", "requiredItems"]),
                        details: card.metadata.displayItems(for: ["details", "facts"])
                    ) {
                        toggleExpansion(card.cardId)
                    }
                }

                OutputCardActions(card: card, viewModel: viewModel)
            }
        }
    }

    private var trustBadgeLabels: [String] {
        card.metadata.stringArray(for: ["trust_badges", "trustBadges", "badges"])
    }

    private func toggleExpansion(_ id: String) {
        if viewModel.expandedRecommendationIDs.contains(id) {
            viewModel.collapseCard(id)
        } else {
            viewModel.expandCard(id)
        }
    }
}

private struct RecommendationOptionView: View {
    let option: DynamicCardOption
    var viewModel: JourneyViewModel

    private var isExpanded: Bool {
        viewModel.expandedRecommendationIDs.contains(option.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            Button {
                if isExpanded {
                    viewModel.collapseCard(option.id)
                } else {
                    viewModel.expandCard(option.id)
                }
            } label: {
                DynamicCardOptionRow(
                    title: option.label,
                    subtitle: option.displaySubtitle,
                    leadingSystemImage: option.systemImage ?? "sparkles",
                    trailingText: isExpanded ? "Hide" : "Details",
                    isSelected: isExpanded
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                RecommendationDetailPanel(
                    id: option.id,
                    isExpanded: isExpanded,
                    pros: option.metadata.stringArray(for: ["pros"]),
                    cons: option.metadata.stringArray(for: ["cons"]),
                    requirements: option.metadata.stringArray(for: ["requirements", "required_items", "requiredItems"]),
                    details: option.metadata.displayItems(for: ["details", "facts"])
                ) {
                    viewModel.collapseCard(option.id)
                }

                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    if option.metadata.bool(for: ["copyable", "can_copy", "canCopy"]) == true {
                        Button {
                            viewModel.copyText(option.value ?? option.label)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }

                    if let urlString = option.metadata.string(for: ["url", "href", "open_url", "openURL"]),
                       let url = URL(string: urlString) {
                        Button {
                            viewModel.openURL(url)
                        } label: {
                            Label("Open", systemImage: "safari")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }
                }
            }
        }
    }
}

private struct RecommendationDetailPanel: View {
    let id: String
    let isExpanded: Bool
    let pros: [String]
    let cons: [String]
    let requirements: [String]
    let details: [MetadataDisplayItem]
    var onCollapse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            Button {
                onCollapse()
            } label: {
                Label("Collapse", systemImage: "chevron.up")
            }
            .buttonStyle(DynamicCardSecondaryButtonStyle())

            MetadataItemList(items: details)

            if !pros.isEmpty {
                TextListSection(title: "Pros", icon: "plus.circle.fill", tint: IrshadTheme.Colors.success, items: pros)
            }

            if !cons.isEmpty {
                TextListSection(title: "Cons", icon: "minus.circle.fill", tint: IrshadTheme.Colors.warning, items: cons)
            }

            if !requirements.isEmpty {
                TextListSection(title: "Requirements", icon: "doc.text.fill", tint: IrshadTheme.Colors.primaryAccent, items: requirements)
            }
        }
        .padding(IrshadTheme.Layout.spacingStandard)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceTint)
        )
    }
}

struct TextListSection: View {
    let title: String
    let icon: String
    let tint: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            Label(title, systemImage: icon)
                .font(IrshadTheme.Typography.statusMicrocopy)
                .foregroundStyle(tint)

            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct TrustBadgeRow: View {
    let labels: [String]

    var body: some View {
        if !labels.isEmpty {
            FlowLayout(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(labels, id: \.self) { label in
                    StatusPill(label, systemImage: "checkmark.seal.fill", tone: .secondary)
                }
            }
        }
    }
}
