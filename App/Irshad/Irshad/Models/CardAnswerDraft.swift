import Foundation

struct CardAnswerDraft: Codable, Equatable, Sendable {
    var cardID: String?
    var value: CardAnswerValue
    var updatedAt: Date?

    static var empty: CardAnswerDraft {
        CardAnswerDraft(cardID: nil, value: .empty, updatedAt: nil)
    }
}

enum CardAnswerValue: Codable, Equatable, Sendable {
    case empty
    case singleOption(String)
    case multiOptions(Set<String>)
    case text(String)
    case numberString(String)
    case toggle(Bool)
    case checklist(Set<String>)
}
