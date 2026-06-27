import SwiftUI

struct PhaseStepperView: View {
    let currentPhase: JourneyPhase
    let phases: [JourneyPhase]
    let completedPhases: Set<JourneyPhase>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visiblePhases: [JourneyPhase] {
        let servicePhases = phases.filter { $0 != .unknown }
        let source = servicePhases.isEmpty ? JourneyPhase.visibleOrder : servicePhases
        let compactOrder: [JourneyPhase] = [.business, .founder, .details, .budget, .documents]
        let compact = compactOrder.filter { source.contains($0) }
        return compact.isEmpty ? compactOrder : compact
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(visiblePhases.enumerated()), id: \.element) { index, phase in
                    PhaseStepItem(
                        phase: phase,
                        state: state(for: phase),
                        title: title(for: phase),
                        showsConnector: index < visiblePhases.count - 1
                    )
                }
            }
            .padding(.horizontal, IrshadTheme.Layout.spacingTight)
            .padding(.vertical, IrshadTheme.Layout.spacingTight)
        }
        .scrollIndicators(.hidden)
        .frame(minHeight: stepperHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Journey phases"))
        .animation(IrshadTheme.Animations.progressTransition, value: currentPhase)
        .animation(IrshadTheme.Animations.progressTransition, value: completedPhases)
    }

    private var stepperHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? IrshadTheme.Layout.phaseStepperHeight + 34 : IrshadTheme.Layout.phaseStepperHeight
    }

    private func state(for phase: JourneyPhase) -> PhaseStepState {
        if completedPhases.contains(phase) {
            return .completed
        }

        if phase == currentPhase {
            return .current
        }

        return .pending
    }

    private func title(for phase: JourneyPhase) -> String {
        dynamicTypeSize.isAccessibilitySize ? phase.accessibleDisplayName : phase.compactDisplayName
    }
}

private struct PhaseStepItem: View {
    let phase: JourneyPhase
    let state: PhaseStepState
    let title: String
    let showsConnector: Bool

    var body: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingTight) {
            VStack(spacing: 6) {
                Circle()
                    .fill(dotFill)
                    .frame(width: dotSize, height: dotSize)
                    .overlay {
                        Circle()
                            .stroke(dotStroke, lineWidth: state == .pending ? 1 : 0)
                    }
                .frame(width: IrshadTheme.Layout.minimumTapTarget, height: 22)

                Text(title)
                    .font(labelFont)
                    .foregroundStyle(labelColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)
                    .frame(width: 62, alignment: .top)
                    .frame(minHeight: 30, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(phase.accessibleDisplayName))
            .accessibilityValue(Text(state.accessibilityValue))

            if showsConnector {
                Capsule(style: .continuous)
                    .fill(connectorFill)
                    .frame(width: 18, height: 2)
                    .padding(.top, 10)
                    .accessibilityHidden(true)
            }
        }
    }

    private var dotSize: CGFloat {
        switch state {
        case .completed:
            IrshadTheme.Layout.phaseDotSize
        case .current:
            IrshadTheme.Layout.phaseDotSize + 6
        case .pending:
            IrshadTheme.Layout.phaseDotSize
        }
    }

    private var dotFill: Color {
        switch state {
        case .completed:
            IrshadTheme.Colors.primaryAccent.opacity(0.58)
        case .current:
            IrshadTheme.Colors.primaryAccent
        case .pending:
            IrshadTheme.Colors.surface
        }
    }

    private var dotStroke: Color {
        switch state {
        case .completed:
            IrshadTheme.Colors.success.opacity(0.35)
        case .current:
            IrshadTheme.Colors.primaryAccent
        case .pending:
            IrshadTheme.Colors.separator
        }
    }

    private var connectorFill: Color {
        state == .completed ? IrshadTheme.Colors.primaryAccent.opacity(0.42) : IrshadTheme.Colors.progressTrack
    }

    private var labelFont: Font {
        state == .current ? IrshadTheme.Typography.statusMicrocopy.weight(.semibold) : IrshadTheme.Typography.statusMicrocopy
    }

    private var labelColor: Color {
        switch state {
        case .completed:
            IrshadTheme.Colors.secondaryText
        case .current:
            IrshadTheme.Colors.primaryAccent
        case .pending:
            IrshadTheme.Colors.tertiaryText
        }
    }
}

private enum PhaseStepState {
    case completed
    case current
    case pending

    var accessibilityValue: String {
        switch self {
        case .completed:
            "Done"
        case .current:
            "Current"
        case .pending:
            "Pending"
        }
    }
}

private extension JourneyPhase {
    var compactDisplayName: String {
        switch self {
        case .goal:
            "Start"
        case .business:
            "Business"
        case .founder:
            "Founder"
        case .details:
            "Details"
        case .budget:
            "Budget"
        case .documents:
            "Docs"
        case .analysis:
            "Analysis"
        case .license:
            "License"
        case .banking:
            "Bank"
        case .verify:
            "Verify"
        case .nextSteps:
            "Next"
        case .plan:
            "Plan"
        case .unknown:
            "Phase"
        }
    }

    var accessibleDisplayName: String {
        switch self {
        case .goal:
            "Goal"
        case .business:
            "Business"
        case .founder:
            "Founder"
        case .details:
            "Details"
        case .budget:
            "Budget"
        case .documents:
            "Documents"
        case .analysis:
            "Analysis"
        case .license:
            "License"
        case .banking:
            "Banking"
        case .verify:
            "Verify"
        case .nextSteps:
            "Next Steps"
        case .plan:
            "Plan"
        case .unknown:
            "Current Phase"
        }
    }
}

#Preview {
    PhaseStepperView(
        currentPhase: .budget,
        phases: JourneyPhase.visibleOrder,
        completedPhases: [.goal, .business, .founder, .details]
    )
    .padding()
}
