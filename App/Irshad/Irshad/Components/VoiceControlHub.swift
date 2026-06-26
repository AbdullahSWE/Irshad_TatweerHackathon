import SwiftUI

struct VoiceControlHub: View {
    var voiceState: VoiceState
    var transcriptState: TranscriptState
    var reduceMotion: Bool
    var beginListening: () -> Void
    var stopListening: () -> Void
    var retryListening: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var pulse = false

    private var isListening: Bool {
        voiceState == .listening
    }

    private var isProcessing: Bool {
        voiceState == .processing
    }

    private var isFailed: Bool {
        if case .failed = voiceState {
            return true
        }
        return false
    }

    private var size: CGFloat {
        isListening ? IrshadTheme.Layout.voiceButtonExpandedSize : IrshadTheme.Layout.voiceButtonSize
    }

    private var shouldReduceMotion: Bool {
        reduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
            Button(action: performPrimaryAction) {
                ZStack {
                    voiceHalo(scale: isListening && pulse ? 1.28 : 1.08, opacity: isListening ? 0.28 : 0.12)
                    voiceHalo(scale: isListening && pulse ? 1.58 : 1.24, opacity: isListening ? 0.18 : 0.08)

                    Circle()
                        .fill(IrshadTheme.Colors.activeVoiceRadialGradient)
                        .frame(width: size, height: size)
                        .overlay {
                            Circle()
                                .stroke(IrshadTheme.Colors.primaryAccent.opacity(isListening ? 0.36 : 0.18), lineWidth: 1)
                        }
                        .irshadShadow(IrshadTheme.Shadows.voiceHaloShadow)

                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.66, height: size * 0.66)
                        .overlay {
                            Image(systemName: iconName)
                                .font(.system(size: size * 0.27, weight: .semibold))
                                .foregroundStyle(iconColor)
                        }
                }
                .frame(width: IrshadTheme.Layout.voiceButtonExpandedSize * 1.55, height: IrshadTheme.Layout.voiceButtonExpandedSize * 1.55)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .accessibilityLabel(Text(accessibilityTitle))
            .accessibilityHint(Text(accessibilityHint))

            Text(statusText)
                .font(IrshadTheme.Typography.statusMicrocopy)
                .foregroundStyle(isFailed ? IrshadTheme.Colors.warning : IrshadTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 34)
        }
        .onAppear {
            pulse = isListening
        }
        .onChange(of: isListening) { _, newValue in
            pulse = newValue
        }
        .animation(shouldReduceMotion ? IrshadTheme.Animations.reducedMotion : IrshadTheme.Animations.listeningPulse, value: pulse)
        .animation(IrshadTheme.Animations.buttonFeedback, value: voiceState)
    }

    private func voiceHalo(scale: CGFloat, opacity: Double) -> some View {
        Circle()
            .stroke(IrshadTheme.Colors.primaryAccent.opacity(opacity), lineWidth: 1.5)
            .background {
                Circle()
                    .fill(IrshadTheme.Colors.softHighlight.opacity(opacity * 0.32))
            }
            .scaleEffect(scale)
            .frame(width: size, height: size)
    }

    private var iconName: String {
        switch voiceState {
        case .idle:
            return transcriptState == .accepted ? "checkmark" : "mic.fill"
        case .listening:
            return "stop.fill"
        case .processing:
            return "hourglass"
        case .transcriptReady:
            return "checkmark"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        isFailed ? IrshadTheme.Colors.warning : IrshadTheme.Colors.primaryAccent
    }

    private var statusText: String {
        switch voiceState {
        case .idle:
            return transcriptState == .accepted ? "تم حفظ الإجابة" : "اضغط وتحدث"
        case .listening:
            return "نستمع الآن"
        case .processing:
            return "جاري التحضير"
        case .transcriptReady:
            return "راجع النص ثم أرسله"
        case .failed(let message):
            return message.isEmpty ? "تعذر التسجيل. حاول مرة أخرى" : message
        }
    }

    private var accessibilityTitle: String {
        switch voiceState {
        case .listening:
            return "Stop listening"
        case .processing:
            return "Voice is processing"
        case .failed:
            return "Retry voice input"
        default:
            return "Start voice input"
        }
    }

    private var accessibilityHint: String {
        switch voiceState {
        case .listening:
            return "Stops recording and prepares transcript"
        case .failed:
            return "Starts listening again"
        default:
            return "Starts listening to your business answer"
        }
    }

    private func performPrimaryAction() {
        switch voiceState {
        case .idle:
            beginListening()
        case .listening:
            stopListening()
        case .processing:
            break
        case .transcriptReady, .failed:
            retryListening()
        }
    }
}

