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
    private let logger: @Sendable (AnalyticsEvent) -> Void

    init(logger: @escaping @Sendable (AnalyticsEvent) -> Void = AnalyticsService.defaultLogger(_:)) {
        self.logger = logger
    }

    func track(_ event: AnalyticsEvent) async {
        logger(event)
    }

    nonisolated private static func defaultLogger(_ event: AnalyticsEvent) {
        #if DEBUG
        let properties = event.properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.displayString)" }
            .joined(separator: ", ")

        if properties.isEmpty {
            print("[Analytics] \(event.name)")
        } else {
            print("[Analytics] \(event.name): \(properties)")
        }
        #else
        _ = event
        #endif
    }
}

struct NoopAnalyticsService: AnalyticsServiceProtocol {
    init() {}

    func track(_ event: AnalyticsEvent) async {}
}
