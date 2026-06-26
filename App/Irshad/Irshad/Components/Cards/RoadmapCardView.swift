import SwiftUI

struct RoadmapCardView: View {
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

                if let nextAction = nextAction {
                    InfoBannerView(
                        message: nextAction,
                        systemImage: "arrow.forward.circle.fill",
                        tone: .info
                    )
                }

                VStack(spacing: IrshadTheme.Layout.spacingTight) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                            Text("\(index + 1)")
                                .font(IrshadTheme.Typography.statusMicrocopy)
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(IrshadTheme.Colors.primaryAccent))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(IrshadTheme.Typography.primaryBody)
                                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let subtitle = step.subtitle {
                                    Text(subtitle)
                                        .font(IrshadTheme.Typography.secondaryLabel)
                                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if let status = step.status {
                                StatusPill(status, tone: .neutral)
                            }
                        }
                        .padding(IrshadTheme.Layout.spacingStandard)
                        .background(
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .fill(IrshadTheme.Colors.surfaceElevated)
                        )
                    }
                }

                if let confidence {
                    StatusPill(confidence, systemImage: "gauge.with.dots.needle.67percent", tone: .active)
                }

                if !unverifiedItems.isEmpty {
                    TextListSection(
                        title: "Unverified",
                        icon: "exclamationmark.triangle.fill",
                        tint: IrshadTheme.Colors.warning,
                        items: unverifiedItems
                    )
                }

                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    if card.showsCopyControl || card.metadata.bool(for: ["copyable", "can_copy", "canCopy"]) == true {
                        Button {
                            viewModel.copyText(copyText)
                        } label: {
                            Label(viewModel.copiedItemID == copyText ? "Copied" : "Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }

                    OutputCardActions(card: card, viewModel: viewModel)
                }
            }
        }
    }

    private var steps: [MetadataDisplayItem] {
        let metadataSteps = card.metadata.displayItems(for: ["steps", "roadmap", "items"])
        if !metadataSteps.isEmpty {
            return metadataSteps
        }

        return card.options.map {
            MetadataDisplayItem(id: $0.id, title: $0.label, subtitle: $0.displaySubtitle, value: $0.trailingLabel, status: $0.status, systemImage: $0.systemImage)
        }
    }

    private var nextAction: String? {
        card.metadata.string(for: ["next_action", "nextAction", "immediate_next_action", "immediateNextAction"])
    }

    private var confidence: String? {
        if let label = card.metadata.string(for: ["confidence_label", "confidenceLabel"]) {
            return label
        }

        if let number = card.metadata.number(for: ["confidence"]) {
            return "\(Int(number * 100))% confidence"
        }

        return nil
    }

    private var unverifiedItems: [String] {
        card.metadata.stringArray(for: ["unverified", "unverified_items", "unverifiedItems"])
    }

    private var copyText: String {
        ([card.displayTitle] + steps.map(\.title)).joined(separator: "\n")
    }
}
