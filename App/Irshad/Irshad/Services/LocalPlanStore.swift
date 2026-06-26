import Foundation

protocol LocalPlanStoreProtocol: Sendable {
    func loadSavedPlan() async throws -> SavedPlanSummary?
    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary
    func deleteSavedPlan() async throws
}

actor LocalPlanStore: LocalPlanStoreProtocol {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadSavedPlan() async throws -> SavedPlanSummary? {
        nil
    }

    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary {
        fatalError("TODO")
    }

    func deleteSavedPlan() async throws {}
}
