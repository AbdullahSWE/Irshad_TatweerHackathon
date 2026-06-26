import Foundation

protocol ShareServiceProtocol: Sendable {
    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload
    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String
}

struct ShareService: ShareServiceProtocol {
    init() {}

    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload {
        fatalError("TODO")
    }

    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String {
        ""
    }
}
