import Foundation

enum AppConfig {
    static let openRouterAPIKey = Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String ?? ""
    static let openRouterModel = {
        let configured = Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_MODEL") as? String
        let trimmed = configured?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "google/gemini-2.5-flash-lite" : trimmed
    }()
}
