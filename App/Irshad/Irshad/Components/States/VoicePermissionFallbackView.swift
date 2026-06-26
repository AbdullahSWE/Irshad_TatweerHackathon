import SwiftUI

/// Shown when voice is denied/unavailable or listening failed. Keeps the
/// journey fully usable through typing and offers a single retry for voice.
struct VoicePermissionFallbackView: View {
    var viewModel: JourneyViewModel

    var title: String = "Voice isn't available"
    var message: String = "Microphone access is off or speech didn't work. You can keep going by typing — nothing is lost."

    private var failureReason: String? {
        if case .failed(let reason) = viewModel.voiceState {
            let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
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
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.warning)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(failureReason ?? message)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                viewModel.retryListening()
            } label: {
                Label("Try voice again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(DynamicCardSecondaryButtonStyle())

            TextFallbackInputView(
                text: textBinding,
                isExpanded: false,
                isProcessing: viewModel.isBackendBusy,
                submitTitle: "Send answer"
            ) {
                viewModel.submitCurrentAnswer()
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
