import Foundation

struct AnalyticsEvent: Codable, Equatable, Sendable {
    let name: String
    let properties: [String: JSONValue]
    let timestamp: Date
}

protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent) async
}

struct AnalyticsService: AnalyticsServiceProtocol {
    init() {}

    func track(_ event: AnalyticsEvent) async {}
}

struct NoopAnalyticsService: AnalyticsServiceProtocol {
    init() {}

    func track(_ event: AnalyticsEvent) async {}
}
