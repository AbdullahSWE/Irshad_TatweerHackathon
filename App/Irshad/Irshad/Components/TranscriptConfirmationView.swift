import SwiftUI

struct TranscriptConfirmationView: View {
    var transcript: Binding<String>
    var confidence: Double?
    var isProcessing: Bool
    var errorMessage: String?
    var language: AppLanguage = .en
    var confirmTitle: String
    var retryListening: () -> Void
    var confirm: () -> Void

    private var hasText: Bool {
        !transcript.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var confidenceText: String? {
        guard let confidence else {
            return nil
        }

        if confidence < 0.62 {
            switch language {
            case .ar:
                return "الثقة منخفضة. عدل النص أو أعد التسجيل"
            case .en:
                return "Low confidence. Edit the text or record again"
            }
        }

        switch language {
        case .ar:
            return "الثقة \(Int((confidence * 100).rounded()))%"
        case .en:
            return "\(Int((confidence * 100).rounded()))% confidence"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .center) {
                Text(reviewTitle)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)

                Spacer()

                if let confidenceText {
                    Label(confidenceText, systemImage: isLowConfidence ? "exclamationmark.circle" : "checkmark.circle")
                        .font(IrshadTheme.Typography.statusMicrocopy)
                        .foregroundStyle(isLowConfidence ? IrshadTheme.Colors.warning : IrshadTheme.Colors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(IrshadTheme.Colors.surfaceTint)
                    .overlay {
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                            .stroke(IrshadTheme.Colors.primaryAccent.opacity(0.16), lineWidth: 1)
                    }

                if transcript.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .padding(IrshadTheme.Layout.spacingComfortable)
                }

                TextEditor(text: transcript)
                    .font(IrshadTheme.Typography.primaryBody)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(IrshadTheme.Layout.spacingTight)
                    .frame(minHeight: 112, maxHeight: 168)
                    .disabled(isProcessing)
            }
            .frame(minHeight: 124)

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: IrshadTheme.Layout.spacingStandard) {
                Button(action: retryListening) {
                    Label(retryTitle, systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryInputButtonStyle())
                .disabled(isProcessing)

                Button(action: confirm) {
                    Label(confirmTitle, systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryInputButtonStyle())
                .disabled(!hasText || isProcessing)
            }
        }
        .padding(IrshadTheme.Layout.spacingComfortable)
        .background {
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
                .irshadShadow(IrshadTheme.Shadows.cardShadow)
        }
        .transition(IrshadTheme.Animations.cardRevealTransition)
        .animation(IrshadTheme.Animations.cardReveal, value: hasText)
    }

    private var isLowConfidence: Bool {
        (confidence ?? 1) < 0.62
    }

    private var reviewTitle: String {
        switch language {
        case .ar:
            return "راجع ما سمعناه"
        case .en:
            return "Review what we heard"
        }
    }

    private var placeholder: String {
        switch language {
        case .ar:
            return "سيظهر النص هنا ويمكنك تعديله"
        case .en:
            return "The transcript appears here and you can edit it"
        }
    }

    private var retryTitle: String {
        switch language {
        case .ar:
            return "أعد"
        case .en:
            return "Retry"
        }
    }
}

struct PrimaryInputButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(IrshadTheme.Typography.secondaryLabel.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
            .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
            .background {
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(IrshadTheme.Colors.primaryAccent.opacity(configuration.isPressed ? 0.82 : 1))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(IrshadTheme.Animations.buttonFeedback, value: configuration.isPressed)
    }
}

struct SecondaryInputButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(IrshadTheme.Typography.secondaryLabel.weight(.semibold))
            .foregroundStyle(IrshadTheme.Colors.primaryAccent)
            .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
            .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
            .background {
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(IrshadTheme.Colors.surfaceTint.opacity(configuration.isPressed ? 0.72 : 1))
                    .overlay {
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                            .stroke(IrshadTheme.Colors.primaryAccent.opacity(0.18), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(IrshadTheme.Animations.buttonFeedback, value: configuration.isPressed)
    }
}
