import SwiftUI

struct PhaseStepperView: View {
    let currentPhase: JourneyPhase
    let phases: [JourneyPhase]
    let completedPhases: Set<JourneyPhase>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleSteps: [JourneyFlowStep] {
        JourneyFlowStep.allCases
    }

    private var currentStep: JourneyFlowStep {
        JourneyFlowStep(phase: currentPhase)
    }

    private var completedSteps: Set<JourneyFlowStep> {
        var steps = Set(completedPhases.map(JourneyFlowStep.init(phase:)))

        if let currentIndex = visibleSteps.firstIndex(of: currentStep) {
            steps.formUnion(visibleSteps.prefix(currentIndex))
        }

        if currentPhase == .plan {
            steps.insert(.actionPlan)
        }

        return steps
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(visibleSteps.enumerated()), id: \.element) { index, step in
                    PhaseStepItem(
                        accessibilityTitle: step.accessibleDisplayName,
                        state: state(for: step),
                        title: title(for: step),
                        showsConnector: index < visibleSteps.count - 1
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

    private func state(for step: JourneyFlowStep) -> PhaseStepState {
        if step == currentStep {
            return .current
        }

        if completedSteps.contains(step) {
            return .completed
        }

        return .pending
    }

    private func title(for step: JourneyFlowStep) -> String {
        dynamicTypeSize.isAccessibilitySize ? step.accessibleDisplayName : step.compactDisplayName
    }
}

private struct PhaseStepItem: View {
    let accessibilityTitle: String
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
            .accessibilityLabel(Text(accessibilityTitle))
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

private enum JourneyFlowStep: Int, CaseIterable {
    case idea
    case clarify
    case license
    case bank
    case actionPlan

    init(phase: JourneyPhase) {
        switch phase {
        case .goal, .unknown:
            self = .idea
        case .business, .founder, .details, .budget, .documents:
            self = .clarify
        case .analysis, .license:
            self = .license
        case .banking:
            self = .bank
        case .verify, .nextSteps, .plan:
            self = .actionPlan
        }
    }

    var compactDisplayName: String {
        switch self {
        case .idea:
            "Idea"
        case .clarify:
            "Clarify"
        case .license:
            "License"
        case .bank:
            "Bank"
        case .actionPlan:
            "Action Plan"
        }
    }

    var accessibleDisplayName: String {
        switch self {
        case .idea:
            "Idea"
        case .clarify:
            "Clarify"
        case .license:
            "License"
        case .bank:
            "Bank"
        case .actionPlan:
            "Action Plan"
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
