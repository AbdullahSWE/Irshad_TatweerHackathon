import Foundation

enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case ar
    case en
}

enum VoicePersona: String, Codable, CaseIterable, Sendable {
    case male
    case female
}

extension VoicePersona {
    func displayName(in language: AppLanguage) -> String {
        switch (self, language) {
        case (.male, .ar):
            return "أحمد"
        case (.female, .ar):
            return "زينب"
        case (.male, .en):
            return "Ahmad"
        case (.female, .en):
            return "Zainab"
        }
    }

    var assistantEmoji: String {
        switch self {
        case .male:
            return "🙋‍♂️"
        case .female:
            return "🙋‍♀️"
        }
    }
}
