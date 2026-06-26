import SwiftUI

struct InputDockView: View {
    var viewModel: JourneyViewModel
    var isWelcome: Bool

    private var isProcessing: Bool {
        viewModel.journeyStatus == .processing || viewModel.voiceState == .processing || viewModel.isBackendBusy
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

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.textFallbackValue },
            set: { viewModel.updateTextFallback($0) }
        )
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
            if shouldShowTranscript {
                TranscriptConfirmationView(
                    transcript: transcriptBinding,
                    confidence: viewModel.transcriptConfidence,
                    isProcessing: isProcessing,
                    errorMessage: viewModel.inputErrorMessage,
                    language: viewModel.currentLanguage,
                    confirmTitle: confirmTitle,
                    retryListening: viewModel.retryListening,
                    confirm: confirmTranscript
                )
            }

            VoiceControlHub(
                voiceState: viewModel.voiceState,
                transcriptState: viewModel.transcriptState,
                language: viewModel.currentLanguage,
                reduceMotion: viewModel.reduceMotionPreferred,
                beginListening: viewModel.beginListening,
                stopListening: viewModel.stopListening,
                retryListening: viewModel.retryListening
            )

            if viewModel.voiceState == .listening {
                VoiceWaveformView(isActive: true)
                    .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
                    .transition(.opacity)
            }

            TextFallbackInputView(
                text: textBinding,
                isExpanded: viewModel.isTextEntryExpanded || viewModel.voiceState.isFailed,
                isProcessing: isProcessing,
                language: viewModel.currentLanguage,
                submitTitle: submitTitle,
                submit: submitTypedInput
            )
        }
        .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
        .padding(.top, IrshadTheme.Layout.spacingComfortable)
        .padding(.bottom, IrshadTheme.Layout.spacingComfortable)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(IrshadTheme.Colors.separator)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(
            IrshadTheme.Animations.resolved(IrshadTheme.Animations.cardReveal, reduceMotion: viewModel.reduceMotionPreferred),
            value: shouldShowTranscript
        )
        .animation(
            IrshadTheme.Animations.resolved(IrshadTheme.Animations.buttonFeedback, reduceMotion: viewModel.reduceMotionPreferred),
            value: viewModel.voiceState
        )
    }

    private func confirmTranscript() {
        if isWelcome {
            viewModel.acceptTranscript()
        } else {
            viewModel.submitCurrentAnswer()
        }
    }

    private func submitTypedInput() {
        let value = viewModel.textFallbackValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return
        }

        if isWelcome {
            viewModel.startJourneyWithText(value)
        } else {
            viewModel.submitCurrentAnswer()
        }
    }

    private var confirmTitle: String {
        switch (isWelcome, viewModel.currentLanguage) {
        case (true, .ar):
            return "اعتمد"
        case (true, .en):
            return "Use transcript"
        case (false, .ar):
            return "أرسل"
        case (false, .en):
            return "Send"
        }
    }

    private var submitTitle: String {
        switch (isWelcome, viewModel.currentLanguage) {
        case (true, .ar):
            return "ابدأ بالنص"
        case (true, .en):
            return "Start with text"
        case (false, .ar):
            return "أرسل الإجابة"
        case (false, .en):
            return "Send answer"
        }
    }
}

private extension VoiceState {
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}
