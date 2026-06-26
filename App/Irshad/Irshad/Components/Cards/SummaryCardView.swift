import SwiftUI

struct SummaryCardView: View {
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

                MetadataItemList(items: summaryItems)

                if card.showsCopyControl || card.metadata.bool(for: ["copy_summary", "copySummary"]) == true {
                    Button {
                        viewModel.copyText(card.bodyText ?? card.displayTitle)
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }

                OutputCardActions(card: card, viewModel: viewModel)
            }
        }
    }

    private var summaryItems: [MetadataDisplayItem] {
        card.metadata.displayItems(for: ["summary_items", "summaryItems", "items", "facts", "highlights"])
    }

    private var copied: Bool {
        viewModel.copiedItemID == (card.bodyText ?? card.displayTitle)
    }
}
