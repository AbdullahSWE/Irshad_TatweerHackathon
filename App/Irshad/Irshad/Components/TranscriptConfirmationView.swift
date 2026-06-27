import SwiftUI

struct TranscriptConfirmationView: View {
    var transcript: Binding<String>
    var isProcessing: Bool
    var errorMessage: String?
    var language: AppLanguage = .en
    var retryListening: () -> Void

    @FocusState private var isTranscriptFocused: Bool

    private var hasText: Bool {
        !transcript.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .center) {
                Text(reviewTitle)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)

                Spacer()
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
                    .frame(minHeight: 48, maxHeight: 68)
                    .disabled(isProcessing)
                    .focused($isTranscriptFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()

                            Button(doneTitle) {
                                isTranscriptFocused = false
                            }
                        }
                    }
            }
            .frame(minHeight: 58)

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: retryListeningAndDismissKeyboard) {
                Label(retryTitle, systemImage: "arrow.counterclockwise")
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryInputButtonStyle())
            .disabled(isProcessing)
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

    private var reviewTitle: String {
        switch language {
        case .ar:
            return "راجع ما سمعناه"
        case .en:
            return "Review what we heard"
        }
    }

    private func retryListeningAndDismissKeyboard() {
        isTranscriptFocused = false
        retryListening()
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

    private var doneTitle: String {
        switch language {
        case .ar:
            return "تم"
        case .en:
            return "Done"
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
