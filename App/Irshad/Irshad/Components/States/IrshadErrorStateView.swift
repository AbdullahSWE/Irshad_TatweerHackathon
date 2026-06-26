import SwiftUI

/// Server / step failure state. Names the failed point plainly, keeps the
/// retry path obvious, and optionally keeps a text fallback so the user is
/// never stranded. Never clears the session — prior answers stay visible
/// in the surrounding view.
struct IrshadErrorStateView: View {
    var viewModel: JourneyViewModel

    /// When true, a typed-answer fallback is offered alongside retry.
    var offersTextFallback: Bool = false

    private var error: RecoverableError? { viewModel.recoverableError }

    private var title: String {
        error?.title ?? "Something went wrong"
    }

    private var message: String {
        error?.message ?? "Irshad could not finish that step. Your previous answers are safe — you can try again."
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
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.warning)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
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
                    Label("Try again", systemImage: "arrow.clockwise")
                        .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(DynamicCardPrimaryButtonStyle())
                .disabled(viewModel.isBackendBusy)

                if let safeCopy = error?.message {
                    Button {
                        viewModel.copyText(safeCopy)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
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
                        .stroke(IrshadTheme.Colors.warning.opacity(0.22), lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }
}
