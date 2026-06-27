import Foundation

enum APIError: Error, Equatable, Sendable {
    case invalidURL(String)
    case transport(String)
    case badStatus(Int, String?)
    case decoding(String)
    case timeout
    case cancelled
}

struct DebuggableAPIError: Error, Sendable {
    let underlying: APIError
    let debugTrace: String
}

enum SpeechError: Error, Equatable, Sendable {
    case permissionDenied
    case microphoneUnavailable
    case recognitionFailed(String)
}

enum PlanStoreError: Error, Equatable, Sendable {
    case readFailed(String)
    case writeFailed(String)
    case deleteFailed(String)
}

enum ShareError: Error, Equatable, Sendable {
    case unavailable
    case formattingFailed(String)
}

struct RecoverableError: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let retryKey: String?
}

struct ToastState: Identifiable, Equatable, Sendable {
    let id: String
    let message: String
}

struct BannerState: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
}
