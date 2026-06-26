import Foundation

enum JourneyStatus: String, Codable, CaseIterable, Sendable {
    case empty
    case preparing
    case collecting
    case processing
    case gateOpen
    case showingResults
    case complete
    case partial
    case failed
}
