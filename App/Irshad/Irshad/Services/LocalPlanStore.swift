import Foundation

protocol LocalPlanStoreProtocol: Sendable {
    func loadSavedPlan() async throws -> SavedPlanSummary?
    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary
    func deleteSavedPlan() async throws
}

actor LocalPlanStore: LocalPlanStoreProtocol {
    private let storageDirectory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> String
    private let filename = "latest-plan.json"

    init(
        storageDirectory: URL? = nil,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        now: @escaping @Sendable () -> Date = Date.init,
        makeID: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.storageDirectory = storageDirectory ?? Self.defaultStorageDirectory(fileManager: fileManager)
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
        self.now = now
        self.makeID = makeID
    }

    func loadSavedPlan() async throws -> SavedPlanSummary? {
        let url = storageURL

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(SavedPlanSummary.self, from: data)
        } catch {
            throw PlanStoreError.readFailed(error.localizedDescription)
        }
    }

    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary {
        let savedAt = now()
        let summary = SavedPlanSummary(
            id: makeID(),
            title: title(for: plan, session: session),
            sessionId: session.sessionId,
            savedAt: savedAt,
            plan: plan,
            session: session,
            checklist: checklist
        )

        do {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
            let data = try encoder.encode(summary)
            try data.write(to: storageURL, options: [.atomic])
            return summary
        } catch {
            throw PlanStoreError.writeFailed(error.localizedDescription)
        }
    }

    func deleteSavedPlan() async throws {
        let url = storageURL

        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw PlanStoreError.deleteFailed(error.localizedDescription)
        }
    }

    private var storageURL: URL {
        storageDirectory.appendingPathComponent(filename, isDirectory: false)
    }

    private static func defaultStorageDirectory(fileManager: FileManager) -> URL {
        if let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return url.appendingPathComponent("Irshad", isDirectory: true)
        }

        return fileManager.temporaryDirectory.appendingPathComponent("Irshad", isDirectory: true)
    }

    private func title(for plan: FinalPlan, session: JourneySession) -> String {
        if let nextAction = plan.nextAction?.trimmedForStorageTitle, !nextAction.isEmpty {
            return nextAction
        }

        let goal = session.goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !goal.isEmpty {
            return goal
        }

        return "Saved Irshad Plan"
    }
}

private extension String {
    var trimmedForStorageTitle: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
