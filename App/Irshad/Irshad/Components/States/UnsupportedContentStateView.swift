import SwiftUI

/// Catch-all for unknown card types or malformed optional payloads. Renders a
/// plain fallback instead of crashing, and keeps retry + typed-answer paths so
/// the journey continues. Reads `unsupportedCard` from the ViewModel.
struct UnsupportedContentStateView: View {
    var viewModel: JourneyViewModel

    /// When true, a typed-answer fallback is offered so the user can respond
    /// even though the card itself can't be rendered.
    var offersTextFallback: Bool = false

    private var card: DynamicCard? { viewModel.unsupportedCard }

    private var heading: String {
        card?.displayTitle ?? "This step can't be shown"
    }

    private var explanation: String {
        card?.metadata.string(for: ["explanation", "message", "fallback"])
            ?? "Irshad received content this app version can't display yet. Your session is still active — you can retry or answer below."
    }

    private var fallbackText: String? {
        let text = [card?.displayTitle, card?.displaySubtitle, card?.bodyText]
            .compactMap { $0 }
            .joined(separator: "\n")
        return text.isEmpty ? nil : text
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.textFallbackValue },
            set: { viewModel.updateTextFallback($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(heading)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(explanation)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                Button {
                    viewModel.retryCurrentStep()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(DynamicCardPrimaryButtonStyle())
                .disabled(viewModel.isBackendBusy)

                if let fallbackText {
                    Button {
                        viewModel.copyText(fallbackText)
                    } label: {
                        Label("Copy text", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }
            }

            if offersTextFallback {
                TextFallbackInputView(
                    text: textBinding,
                    isExpanded: false,
                    isProcessing: viewModel.isBackendBusy,
                    submitTitle: "Send answer"
                ) {
                    viewModel.submitCurrentAnswer()
                }
            }
        }
        .padding(IrshadTheme.Layout.outerMarginCompact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }
}
