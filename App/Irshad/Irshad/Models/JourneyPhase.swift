import Foundation

enum JourneyPhase: String, Codable, CaseIterable, Sendable {
    case goal
    case business
    case founder
    case details
    case budget
    case documents
    case analysis
    case license
    case banking
    case verify
    case nextSteps
    case plan
    case unknown

    static var visibleOrder: [JourneyPhase] {
        [
            .goal,
            .business,
            .founder,
            .details,
            .budget,
            .documents,
            .analysis,
            .license,
            .banking,
            .verify,
            .nextSteps,
            .plan
        ]
    }

    init(serviceValue: String?) {
        guard let serviceValue else {
            self = .unknown
            return
        }

        switch serviceValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "goal":
            self = .goal
        case "business":
            self = .business
        case "founder":
            self = .founder
        case "details":
            self = .details
        case "budget":
            self = .budget
        case "documents":
            self = .documents
        case "analysis", "analyze":
            self = .analysis
        case "license":
            self = .license
        case "banking":
            self = .banking
        case "verify", "verification":
            self = .verify
        case "nextsteps", "next_steps", "next-steps", "next steps":
            self = .nextSteps
        case "plan", "final":
            self = .plan
        default:
            self = .unknown
        }
    }
}
