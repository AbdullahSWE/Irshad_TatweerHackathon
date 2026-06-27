import SwiftUI

struct JourneyHeaderView: View {
    var viewModel: JourneyViewModel
    var onRetry: (() -> Void)?
    var onCancel: (() -> Void)?

    private var shouldShowPhaseDetails: Bool {
        viewModel.journeyStatus != .empty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            HStack(alignment: .firstTextBaseline, spacing: IrshadTheme.Layout.spacingTight) {
                Text(businessText)
                    .font(IrshadTheme.Typography.secondaryLabelDynamic.weight(.semibold))
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isServiceBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(IrshadTheme.Colors.primaryAccent)
                        .accessibilityHidden(true)
                }
            }

            if shouldShowPhaseDetails {
                VStack(spacing: IrshadTheme.Layout.spacingTight) {
                    PhaseProgressBar(progress: viewModel.progress, isServiceBusy: viewModel.isServiceBusy)

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
        .animation(IrshadTheme.Animations.progressTransition, value: viewModel.isServiceBusy)
    }

    private var businessText: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "المشروع: \(viewModel.compactBusinessLabel)"
        case .en:
            return "Business: \(viewModel.compactBusinessLabel)"
        }
    }

    private var statusTitle: String {
        if viewModel.isServiceBusy {
            switch viewModel.currentLanguage {
            case .ar:
                return "جار التحديث"
            case .en:
                return "Updating"
            }
        }

        switch (viewModel.journeyStatus, viewModel.currentLanguage) {
        case (.empty, .ar), (.gateOpen, .ar):
            return "جاهز"
        case (.empty, .en), (.gateOpen, .en):
            return "Ready"
        case (.preparing, .ar):
            return "نجهز"
        case (.preparing, .en):
            return "Preparing"
        case (.collecting, .ar):
            return "نجمع التفاصيل"
        case (.collecting, .en):
            return "Collecting details"
        case (.processing, .ar):
            return "نعالج"
        case (.processing, .en):
            return "Processing"
        case (.showingResults, .ar):
            return "النتائج"
        case (.showingResults, .en):
            return "Results"
        case (.complete, .ar):
            return "مكتمل"
        case (.complete, .en):
            return "Complete"
        case (.partial, .ar):
            return "جزئي"
        case (.partial, .en):
            return "Partial"
        case (.failed, .ar):
            return "يحتاج إعادة"
        case (.failed, .en):
            return "Retry needed"
        }
    }

    private var retryButtonTitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "أعد المحاولة"
        case .en:
            return "Retry"
        }
    }

    private var cancelButtonTitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "إلغاء"
        case .en:
            return "Cancel"
        }
    }

    private var statusIcon: String? {
        if viewModel.isServiceBusy {
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
        if viewModel.isServiceBusy {
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
            return viewModel.recoverableError == nil ? .error : .warning
        }
    }

    private var shouldShowRecoveryActions: Bool {
        false
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
