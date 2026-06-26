import SwiftUI

struct JourneyHeaderView: View {
    var viewModel: JourneyViewModel
    var onRetry: (() -> Void)?
    var onCancel: (() -> Void)?

    private var shouldShowPhaseDetails: Bool {
        viewModel.journeyStatus != .empty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                    Text(viewModel.appTitle)
                        .font(IrshadTheme.Typography.stepIndicatorDynamic)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(framingText)
                        .font(IrshadTheme.Typography.statusMicrocopyDynamic)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                StatusPill(
                    statusTitle,
                    systemImage: statusIcon,
                    tone: statusTone,
                    showsSpinner: viewModel.isBackendBusy
                )
            }

            if shouldShowPhaseDetails {
                VStack(spacing: IrshadTheme.Layout.spacingStandard) {
                    PhaseProgressBar(progress: viewModel.progress, isBackendBusy: viewModel.isBackendBusy)

                    PhaseStepperView(
                        currentPhase: viewModel.currentPhase,
                        phases: viewModel.phases,
                        completedPhases: viewModel.completedPhases
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text(IrshadTheme.Accessibility.Label.phaseProgress))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if shouldShowRecoveryActions {
                HStack(spacing: IrshadTheme.Layout.spacingStandard) {
                    if let onRetry {
                        Button("أعد المحاولة", action: onRetry)
                            .buttonStyle(HeaderActionButtonStyle(tone: .primary))
                    }

                    if let onCancel {
                        Button("إلغاء", action: onCancel)
                            .buttonStyle(HeaderActionButtonStyle(tone: .secondary))
                    }
                }
                .transition(IrshadTheme.Animations.cardRevealTransition)
            }
        }
        .padding(IrshadTheme.Layout.outerMarginCompact)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
        .animation(IrshadTheme.Animations.progressTransition, value: viewModel.journeyStatus)
        .animation(IrshadTheme.Animations.progressTransition, value: viewModel.isBackendBusy)
    }

    private var framingText: String {
        if let message = normalized(viewModel.framingMessage) {
            return message
        }

        if let sessionLabel {
            return sessionLabel
        }

        return "ابدأ رحلة موجهة لتأسيس مشروعك."
    }

    private var sessionLabel: String? {
        let trimmed = viewModel.sessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return "Session \(trimmed)"
    }

    private var statusTitle: String {
        if viewModel.isBackendBusy {
            return "جار التحديث"
        }

        switch viewModel.journeyStatus {
        case .empty:
            return "جاهز"
        case .preparing:
            return "نجهز"
        case .collecting:
            return "نجمع التفاصيل"
        case .processing:
            return "نعالج"
        case .gateOpen:
            return "جاهز"
        case .showingResults:
            return "النتائج"
        case .complete:
            return "مكتمل"
        case .partial:
            return "جزئي"
        case .failed:
            return "يحتاج إعادة"
        }
    }

    private var statusIcon: String? {
        if viewModel.isBackendBusy {
            return nil
        }

        switch viewModel.journeyStatus {
        case .empty:
            return "sparkles"
        case .preparing, .collecting, .processing:
            return "arrow.triangle.2.circlepath"
        case .gateOpen, .showingResults:
            return "checkmark.seal"
        case .complete:
            return "checkmark.circle.fill"
        case .partial:
            return "exclamationmark.circle"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusTone: StatusPill.Tone {
        if viewModel.isBackendBusy {
            return .active
        }

        switch viewModel.journeyStatus {
        case .empty:
            return .neutral
        case .preparing, .collecting, .processing:
            return .active
        case .gateOpen, .showingResults:
            return .secondary
        case .complete:
            return .success
        case .partial:
            return .warning
        case .failed:
            return .error
        }
    }

    private var shouldShowRecoveryActions: Bool {
        (viewModel.journeyStatus == .failed || viewModel.isBackendBusy) && (onRetry != nil || onCancel != nil)
    }

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct HeaderActionButtonStyle: ButtonStyle {
    enum Tone {
        case primary
        case secondary
    }

    let tone: Tone

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(IrshadTheme.Typography.statusMicrocopyDynamic)
            .foregroundStyle(foreground)
            .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
            .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(background.opacity(configuration.isPressed ? 0.76 : 1))
                    .overlay {
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                            .stroke(stroke, lineWidth: 1)
                    }
            )
            .animation(IrshadTheme.Animations.buttonFeedback, value: configuration.isPressed)
    }

    private var foreground: Color {
        switch tone {
        case .primary:
            .white
        case .secondary:
            IrshadTheme.Colors.primaryAccent
        }
    }

    private var background: Color {
        switch tone {
        case .primary:
            IrshadTheme.Colors.primaryAccent
        case .secondary:
            IrshadTheme.Colors.surfaceTint
        }
    }

    private var stroke: Color {
        switch tone {
        case .primary:
            IrshadTheme.Colors.primaryAccent.opacity(0.18)
        case .secondary:
            IrshadTheme.Colors.primaryAccent.opacity(0.18)
        }
    }
}

#Preview {
    JourneyHeaderView(viewModel: AppEnvironment.live.makeJourneyViewModel())
        .padding()
}
