import SwiftUI

struct AdditionalContextView: View {
    var viewModel: JourneyViewModel

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var emojiIsVisible = false
    @State private var emojiIsWaving = false
    @State private var emojiIsPressed = false

    private var shouldReduceMotion: Bool {
        viewModel.reduceMotionPreferred || accessibilityReduceMotion
    }

    private var isProcessing: Bool {
        viewModel.journeyStatus == .processing || viewModel.voiceState == .processing || viewModel.isServiceBusy
    }

    private var shouldShowTranscript: Bool {
        if viewModel.voiceState == .transcriptReady {
            return true
        }

        if !viewModel.editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        switch viewModel.transcriptState {
        case .partial, .final, .editing:
            return true
        case .empty, .accepted:
            return false
        }
    }

    private var transcriptBinding: Binding<String> {
        Binding(
            get: { viewModel.editableTranscript },
            set: { viewModel.updateTranscript($0) }
        )
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
            DynamicCardSurface(card: displayCard) {
                VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
                    emojiButton

                    Text(viewModel.additionalContextMessage)
                        .font(IrshadTheme.Typography.primaryBodyDynamic)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    if shouldShowTranscript {
                        TranscriptConfirmationView(
                            transcript: transcriptBinding,
                            isProcessing: isProcessing,
                            errorMessage: viewModel.inputErrorMessage,
                            language: viewModel.currentLanguage,
                            retryListening: viewModel.retryListening
                        )
                    }

                    VoiceControlHub(
                        voiceState: viewModel.voiceState,
                        transcriptState: viewModel.transcriptState,
                        language: viewModel.currentLanguage,
                        reduceMotion: viewModel.reduceMotionPreferred,
                        beginListening: viewModel.beginListening,
                        stopListening: viewModel.stopListening,
                        submitTranscript: viewModel.submitRecognizedSpeech,
                        retryListening: viewModel.retryListening
                    )

                    if viewModel.voiceState == .listening {
                        VoiceWaveformView(isActive: true)
                            .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
                            .transition(.opacity)
                    }

                    Button(action: viewModel.skipAdditionalContext) {
                        Label(viewModel.additionalContextSkipTitle, systemImage: "forward.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                    .disabled(isProcessing)
                    .accessibilityHint(Text("Skips this optional note and prepares the plan."))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(
            IrshadTheme.Animations.resolved(IrshadTheme.Animations.cardReveal, reduceMotion: shouldReduceMotion),
            value: shouldShowTranscript
        )
        .animation(
            IrshadTheme.Animations.resolved(IrshadTheme.Animations.cardReveal, reduceMotion: shouldReduceMotion),
            value: viewModel.voiceState
        )
    }

    private var emojiButton: some View {
        Button {
            playEmojiInteraction()
        } label: {
            Text(viewModel.selectedVoicePersona.assistantEmoji)
                .font(.system(size: 72))
                .scaleEffect(emojiIsPressed ? 1.08 : 1)
                .rotationEffect(.degrees(shouldReduceMotion ? 0 : (emojiIsWaving ? 7 : -7)))
                .opacity(emojiIsVisible ? 1 : 0)
                .frame(width: 98, height: 98)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(viewModel.selectedVoicePersona.displayName(in: viewModel.currentLanguage)))
        .onAppear {
            withAnimation(.easeOut(duration: 0.32)) {
                emojiIsVisible = true
            }

            guard !shouldReduceMotion else {
                return
            }

            emojiIsWaving = true
        }
        .animation(
            IrshadTheme.Animations.resolved(
                Animation.easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                reduceMotion: shouldReduceMotion
            ),
            value: emojiIsWaving
        )
        .animation(IrshadTheme.Animations.buttonFeedback, value: emojiIsPressed)
    }

    private var displayCard: DynamicCard {
        DynamicCard(
            cardId: "additional-context",
            kind: .question,
            type: .text,
            title: viewModel.additionalContextTitle,
            subtitle: nil,
            options: [],
            slot: "additional_context",
            stage: "final_context",
            phase: viewModel.currentPhase,
            metadata: [
                "eyebrow": .string(optionalLabel)
            ]
        )
    }

    private var optionalLabel: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "اختياري"
        case .en:
            return "Optional"
        }
    }

    private func playEmojiInteraction() {
        guard !shouldReduceMotion else {
            return
        }

        emojiIsPressed = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            emojiIsPressed = false
        }
    }
}

#Preview {
    AdditionalContextView(viewModel: AppEnvironment.live.makeJourneyViewModel())
        .padding()
        .background(IrshadTheme.Colors.appBackgroundGradient)
}
