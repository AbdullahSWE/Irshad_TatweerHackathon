import SwiftUI

struct UnsupportedCardView: View {
    let card: DynamicCard?
    var viewModel: JourneyViewModel

    var body: some View {
        DynamicCardSurface(card: fallbackCard) {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                Text(explanation)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    Button {
                        viewModel.retryCurrentStep()
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(DynamicCardPrimaryButtonStyle())

                    Button {
                        viewModel.copyText(fallbackText)
                    } label: {
                        Label("Copy text", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }
            }
        }
    }

    private var fallbackCard: DynamicCard {
        card ?? DynamicCard(
            cardId: "unsupported-card",
            kind: .info,
            type: .unsupported("unknown"),
            title: "This card is not supported yet",
            subtitle: nil,
            options: [],
            slot: nil,
            stage: nil,
            phase: .unknown,
            metadata: [:]
        )
    }

    private var explanation: String {
        card?.metadata.string(for: ["explanation", "message", "fallback"]) ?? "Irshad received a card type this app version cannot render. Your session is still available."
    }

    private var fallbackText: String {
        [card?.displayTitle, card?.displaySubtitle, card?.bodyText]
            .compactMap { $0 }
            .joined(separator: "\n")
    }
}
