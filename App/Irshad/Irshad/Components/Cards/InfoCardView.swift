import SwiftUI

struct InfoCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    var body: some View {
        DynamicCardSurface(card: card) {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                if let bodyText = card.bodyText {
                    Text(bodyText)
                        .font(IrshadTheme.Typography.primaryBody)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                MetadataItemList(items: card.metadata.displayItems(for: ["items", "facts", "details"]))

                OutputCardActions(card: card, viewModel: viewModel)
            }
        }
    }
}

struct OutputCardActions: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    var body: some View {
        if !actions.isEmpty || card.requiresAction {
            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(actions) { action in
                    Button {
                        perform(action)
                    } label: {
                        Label(action.title, systemImage: action.systemImage ?? "arrow.right.circle.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }

                if card.requiresAction {
                    Button(card.confirmLabel) {
                        viewModel.submitCardAnswer(card.cardId)
                    }
                    .buttonStyle(DynamicCardPrimaryButtonStyle())
                    .disabled(viewModel.isBackendBusy)
                }
            }
        }
    }

    private var actions: [MetadataDisplayItem] {
        card.metadata.displayItems(for: ["actions", "action_items", "actionItems"])
    }

    private func perform(_ action: MetadataDisplayItem) {
        let title = action.title.lowercased()
        let payload = action.value ?? action.subtitle ?? card.bodyText ?? card.displayTitle

        if title.contains("copy") {
            viewModel.copyText(payload)
            return
        }

        if title.contains("open"), let urlString = action.value, let url = URL(string: urlString) {
            viewModel.openURL(url)
            return
        }

        viewModel.submitCardAnswer(card.cardId)
    }
}

struct MetadataItemList: View {
    let items: [MetadataDisplayItem]

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                        Image(systemName: item.systemImage ?? "checkmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tint(for: item.status))
                            .frame(width: 22, height: 22)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(IrshadTheme.Typography.secondaryLabel)
                                .foregroundStyle(IrshadTheme.Colors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            if let subtitle = item.subtitle {
                                Text(subtitle)
                                    .font(IrshadTheme.Typography.statusMicrocopy)
                                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let value = item.value {
                            Text(value)
                                .font(IrshadTheme.Typography.statusMicrocopy)
                                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .padding(IrshadTheme.Layout.spacingStandard)
                    .background(
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                            .fill(IrshadTheme.Colors.surfaceElevated)
                    )
                }
            }
        }
    }

    private func tint(for status: String?) -> Color {
        switch status?.lowercased() {
        case "verified", "complete", "completed", "success":
            return IrshadTheme.Colors.success
        case "warning", "pending", "unverified":
            return IrshadTheme.Colors.warning
        case "missing", "error":
            return .red
        default:
            return IrshadTheme.Colors.primaryAccent
        }
    }
}
