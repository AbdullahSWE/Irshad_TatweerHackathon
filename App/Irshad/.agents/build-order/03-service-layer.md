# Prompt 03: Service Layer Stubs

## Context

Create the service protocols, DTOs, endpoint registry, and concrete service stubs for Irshad. These stubs define the contract consumed by `JourneyViewModel` before implementation details are filled in. The app talks only to seven backend POST endpoints and uses Apple/native services for speech, audio playback, local persistence, sharing payload preparation, and lightweight analytics.

This prompt creates service interfaces and stub implementations only. Use `fatalError("TODO")` or minimal no-op returns where noted. Do not implement networking, speech engine logic, persistence, sharing formatting, ViewModel behavior, SwiftUI views, reusable components, theme files, visual styling, animations, or gestures.

## File Location

Create:

- `Irshad/Services/JourneyAPIService.swift`
- `Irshad/Services/APIRequests.swift`
- `Irshad/Services/APIResponses.swift`
- `Irshad/Services/SpeechRecognitionService.swift`
- `Irshad/Services/SpeechSynthesisService.swift`
- `Irshad/Services/LocalPlanStore.swift`
- `Irshad/Services/ShareService.swift`
- `Irshad/Services/AnalyticsService.swift`

## Dependencies

- Imports: `Foundation`, `Speech`, `AVFoundation`
- Depends on: all models from `Irshad/Models/`, `AppConfig`
- Later consumers: `JourneyViewModel`, app environment, tests

## Requirements

- Define protocol-first services for testability.
- Use async service APIs.
- Keep concrete methods as stubs in this prompt.
- Use only the allowed backend endpoint paths.
- Do not automatically retry in `JourneyAPIService`; retry is ViewModel-owned.
- Do not add business logic for license, banking, authority, fee, phone, or journey-stage decisions.

## Interface

### API Requests

`Irshad/Services/APIRequests.swift`

```swift
struct StartJourneyRequest: Encodable, Sendable {
    let sessionId: String
    let goalText: String
    let language: AppLanguage
}

struct NextJourneyRequest: Encodable, Sendable {
    let sessionId: String
    let session: JourneySession
}

struct AnalyzeRequest: Encodable, Sendable {
    let sessionId: String
    let session: JourneySession
}

struct VerifyRequest: Encodable, Sendable {
    let sessionId: String
    let verifyTarget: String
}

struct SessionOnlyRequest: Encodable, Sendable {
    let sessionId: String
}
```

### API Responses

`Irshad/Services/APIResponses.swift`

```swift
enum JourneyResponseStatus: Codable, Equatable, Sendable {
    case collecting
    case gateOpen
    case ready
    case unknown(String)
}

struct StartJourneyResponse: Decodable, Sendable {
    let session: JourneySession?
    let framing: String?
    let activity: String?
    let card: DynamicCard?
    let progress: JourneyProgress?
    let currentStage: String?
    let currentPhase: JourneyPhase?
}

struct NextJourneyResponse: Decodable, Sendable {
    let status: JourneyResponseStatus
    let session: JourneySession?
    let currentStage: String?
    let currentPhase: JourneyPhase?
    let stageJustCompleted: String?
    let progress: JourneyProgress?
    let card: DynamicCard?
}

struct AnalyzeResponse: Decodable, Sendable {
    let analysis: AnalysisSummary
    let nextStage: String?
}

struct VerifyResponse: Decodable, Sendable {
    let verification: VerificationSummary
    let nextStage: String?
}

struct LicenseResponse: Decodable, Sendable {
    let license: LicenseRecommendation
    let nextStage: String?
}

struct BankingResponse: Decodable, Sendable {
    let banking: BankingRecommendations
    let nextStage: String?
}

struct FinalPlanResponse: Decodable, Sendable {
    let plan: FinalPlan
}
```

### Journey API

`Irshad/Services/JourneyAPIService.swift`

```swift
enum JourneyEndpoint: String, CaseIterable, Sendable {
    case start = "/api/journey/start"
    case next = "/api/journey/next"
    case analyze = "/api/analyze"
    case verify = "/api/verify"
    case license = "/api/license"
    case banking = "/api/banking"
    case finalPlan = "/api/plan/final"
}

protocol JourneyAPIServiceProtocol: Sendable {
    func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse
    func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse
    func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse
    func verify(_ request: VerifyRequest) async throws -> VerifyResponse
    func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse
    func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse
    func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse
}

final class JourneyAPIService: JourneyAPIServiceProtocol {
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder(), encoder: JSONEncoder = JSONEncoder())
    func url(for path: String) throws -> URL
    func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse
    func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse
    func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse
    func verify(_ request: VerifyRequest) async throws -> VerifyResponse
    func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse
    func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse
    func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse
}
```

### Speech Recognition

`Irshad/Services/SpeechRecognitionService.swift`

```swift
protocol SpeechRecognitionServiceProtocol: AnyObject {
    func requestAuthorization() async -> SpeechAuthorizationStatus
    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error>
    func stopListening() async
    func cancelListening() async
}

final class SpeechRecognitionService: NSObject, SpeechRecognitionServiceProtocol {
    override init()
    func requestAuthorization() async -> SpeechAuthorizationStatus
    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error>
    func stopListening() async
    func cancelListening() async
}
```

### Speech Synthesis

`Irshad/Services/SpeechSynthesisService.swift`

```swift
protocol SpeechSynthesisServiceProtocol: AnyObject {
    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async
    func stopSpeaking() async
}

final class SpeechSynthesisService: NSObject, SpeechSynthesisServiceProtocol {
    override init()
    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async
    func stopSpeaking() async
}
```

### Local Plan Store

`Irshad/Services/LocalPlanStore.swift`

```swift
protocol LocalPlanStoreProtocol: Sendable {
    func loadSavedPlan() async throws -> SavedPlanSummary?
    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary
    func deleteSavedPlan() async throws
}

actor LocalPlanStore: LocalPlanStoreProtocol {
    init(fileManager: FileManager = .default, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder())
    func loadSavedPlan() async throws -> SavedPlanSummary?
    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary
    func deleteSavedPlan() async throws
}
```

### Share Service

`Irshad/Services/ShareService.swift`

```swift
protocol ShareServiceProtocol: Sendable {
    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload
    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String
}

struct ShareService: ShareServiceProtocol {
    init()
    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload
    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String
}
```

### Analytics Service

`Irshad/Services/AnalyticsService.swift`

```swift
struct AnalyticsEvent: Codable, Equatable, Sendable {
    let name: String
    let properties: [String: JSONValue]
    let timestamp: Date
}

protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent) async
}

struct AnalyticsService: AnalyticsServiceProtocol {
    init()
    func track(_ event: AnalyticsEvent) async
}

struct NoopAnalyticsService: AnalyticsServiceProtocol {
    init()
    func track(_ event: AnalyticsEvent) async
}
```

## Implementation Notes

- Concrete method bodies should be stubs only in this prompt.
- `JourneyEndpoint` must contain only the seven allowed routes.
- `JourneyAPIService.url(for:)` can be declared here and implemented later.
- `ShareService` prepares data only; system share sheet presentation belongs to the UX/UI layer or a small adapter called by UI.
- Speech permission denial is not a journey failure. The ViewModel later keeps text fallback active.

## Acceptance Criteria

- [ ] All service files listed above exist.
- [ ] Every service protocol signature exactly matches this prompt.
- [ ] Concrete services compile as stubs or intentional TODO implementations.
- [ ] API request DTOs encode the documented request shapes.
- [ ] API response DTOs decode the documented response shapes and status aliases.
- [ ] `JourneyEndpoint.allCases` contains exactly seven cases.
- [ ] No service references any route outside the seven allowed paths.
- [ ] No network, speech, persistence, sharing formatting, ViewModel behavior, SwiftUI view, component, theme, styling, animation, or gesture implementation is added by this prompt.
