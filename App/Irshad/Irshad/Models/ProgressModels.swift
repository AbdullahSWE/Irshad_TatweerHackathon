import Foundation

struct JourneyProgress: Codable, Equatable, Sendable {
    let filled: Int
    let required: Int
    let stagesDone: Int
    let stagesTotal: Int
}
