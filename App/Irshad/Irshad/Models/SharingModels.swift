import Foundation

struct SharePayload: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let url: URL?
    let items: [String]
}

struct SavedPlanSummary: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let sessionId: String
    let savedAt: Date
    let plan: FinalPlan
    let session: JourneySession
    let checklist: [NextStepChecklistItem]
}
