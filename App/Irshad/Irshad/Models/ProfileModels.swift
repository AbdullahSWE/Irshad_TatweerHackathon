import Foundation

struct ProfileSection: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let fields: [ProfileField]
}

struct ProfileField: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    let trustStatus: TrustStatus
    let correctionID: String?
}

struct CorrectionTarget: Identifiable, Codable, Equatable, Sendable {
    var id: String { fieldID }
    let fieldID: String
    let label: String
    let currentValue: String?
}
