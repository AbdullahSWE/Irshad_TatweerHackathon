# Prompt 02: Data Models

## Context

Create the Codable, Sendable, view-facing and service-facing data model layer for Irshad. The Swift app is a thin client: it renders backend-driven journey cards, stores local input/session state, orchestrates API calls, saves the final plan locally, and prepares share/copy payloads. Swift must not own legal, banking, fee, authority, phone, eligibility, or journey-decision rules.

This prompt creates models only. Do not create services, ViewModels, app entry code, SwiftUI views, reusable UI components, theme files, visual styling, animations, or gesture handlers.

## File Location

Create:

- `Irshad/Models/AppLanguage.swift`
- `Irshad/Models/JourneyPhase.swift`
- `Irshad/Models/JourneyStatus.swift`
- `Irshad/Models/FlexibleJSON.swift`
- `Irshad/Models/JourneySession.swift`
- `Irshad/Models/DynamicCard.swift`
- `Irshad/Models/CardAnswerDraft.swift`
- `Irshad/Models/ProgressModels.swift`
- `Irshad/Models/OutputModels.swift`
- `Irshad/Models/ProfileModels.swift`
- `Irshad/Models/TrustModels.swift`
- `Irshad/Models/VoiceModels.swift`
- `Irshad/Models/SharingModels.swift`
- `Irshad/Models/ErrorModels.swift`
- `Irshad/Utilities/JSONValue+Display.swift`

## Dependencies

- Imports: `Foundation`
- Depends on: project scaffold and `AppConfig`
- Later consumers: API DTOs, services, `JourneyViewModel`, and UX/UI views

## Requirements

- Use `struct` and `enum` by default.
- Conform API and persistence models to `Codable`.
- Conform models to `Equatable` where useful and `Sendable` where safe.
- Decode flexible backend JSON without throwing away the whole response when one dynamic value is unknown.
- Preserve unknown backend metadata only as flexible JSON for display/action forwarding. Do not interpret unknown metadata as legal or banking rules.
- Decode both `currentStage` and `currentPhase` in session responses. Prefer `currentStage` for backend compatibility and map either value into the visible phase model.
- Decode dynamic card options from either string arrays or object arrays.
- Decode unknown card types to a safe unsupported state.
- Keep numeric card answers as strings until the backend receives them.

## Interface

### App Language

`Irshad/Models/AppLanguage.swift`

```swift
enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case ar
    case en
}

enum VoicePersona: String, Codable, CaseIterable, Sendable {
    case male
    case female
}
```

### Journey Phase And Status

`Irshad/Models/JourneyPhase.swift`

```swift
enum JourneyPhase: String, Codable, CaseIterable, Sendable {
    case goal
    case business
    case founder
    case details
    case budget
    case documents
    case analysis
    case license
    case banking
    case verify
    case nextSteps
    case plan
    case unknown

    static var visibleOrder: [JourneyPhase] { get }
    init(backendValue: String?)
}
```

`Irshad/Models/JourneyStatus.swift`

```swift
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
```

### Flexible JSON

`Irshad/Models/FlexibleJSON.swift`

```swift
enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null
}
```

`Irshad/Utilities/JSONValue+Display.swift`

```swift
extension JSONValue {
    var displayString: String { get }
    var stringValue: String? { get }
}
```

### Trust Models

`Irshad/Models/TrustModels.swift`

```swift
enum TrustStatus: String, Codable, CaseIterable, Sendable {
    case verified
    case estimated
    case unverified
    case missing
    case unknown
    case guidanceOnly = "guidance_only"
}

struct TrustFact: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    let status: TrustStatus
    let source: String?
}

struct TrustFactBundle: Codable, Equatable, Sendable {
    var verified: [TrustFact]
    var estimated: [TrustFact]
    var unverified: [TrustFact]
    var missing: [TrustFact]
    var unknown: [TrustFact]
}
```

### Journey Session

`Irshad/Models/JourneySession.swift`

```swift
struct JourneySession: Identifiable, Codable, Equatable, Sendable {
    var id: String { sessionId }
    let sessionId: String
    var goalText: String
    var currentStage: String?
    var currentPhase: JourneyPhase
    var filledSlots: [String: JSONValue]
    var history: [JourneyHistoryItem]
}

struct JourneyHistoryItem: Identifiable, Codable, Equatable, Sendable {
    var id: String { cardId }
    let cardId: String
    let question: String
    let answer: JSONValue
    let slot: String?
    let stage: String?
    let timestamp: Date
}
```

### Dynamic Cards

`Irshad/Models/DynamicCard.swift`

```swift
enum DynamicCardKind: Codable, Equatable, Sendable {
    case question
    case confirmation
    case info
    case unsupported(String)
}

enum DynamicCardType: Codable, Equatable, Sendable {
    case singleSelect
    case multiSelect
    case text
    case number
    case toggle
    case checklist
    case info
    case summary
    case recommendation
    case roadmap
    case none
    case unsupported(String)
}

struct DynamicCard: Identifiable, Codable, Equatable, Sendable {
    var id: String { cardId }
    let cardId: String
    let kind: DynamicCardKind
    let type: DynamicCardType
    let title: String
    let subtitle: String?
    let options: [DynamicCardOption]
    let slot: String?
    let stage: String?
    let phase: JourneyPhase
    let metadata: [String: JSONValue]
}

struct DynamicCardOption: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String?
    let metadata: [String: JSONValue]
}
```

### Card Drafts

`Irshad/Models/CardAnswerDraft.swift`

```swift
struct CardAnswerDraft: Codable, Equatable, Sendable {
    var cardID: String?
    var value: CardAnswerValue
    var updatedAt: Date?

    static var empty: CardAnswerDraft { get }
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
```

### Progress Models

`Irshad/Models/ProgressModels.swift`

```swift
struct JourneyProgress: Codable, Equatable, Sendable {
    let filled: Int
    let required: Int
    let stagesDone: Int
    let stagesTotal: Int
}
```

### Output Models

`Irshad/Models/OutputModels.swift`

```swift
struct AnalysisSummary: Codable, Equatable, Sendable {
    let matchedActivities: [MatchedActivity]
    let estSetupCostRange: String?
    let candidateLicenses: [String]
    let confidence: Double?
    let unverified: [String]
    let metadata: [String: JSONValue]
}

struct MatchedActivity: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let metadata: [String: JSONValue]
}

enum VerificationStatus: Codable, Equatable, Sendable {
    case verified
    case notFound
    case unknown(String)
}

struct VerificationSummary: Codable, Equatable, Sendable {
    let status: VerificationStatus
    let info: String?
    let verifiedFacts: [String: JSONValue]
    let sources: [String]
    let authority: String?
    let phone: String?
    let contactURL: URL?
    let whatToConfirm: String?
    let message: String?
    let metadata: [String: JSONValue]
}

struct LicenseRecommendation: Codable, Equatable, Sendable {
    let best: LicenseOption?
    let alternatives: [LicenseOption]
    let metadata: [String: JSONValue]
}

struct LicenseOption: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let type: String
    let issuer: String?
    let pros: [String]
    let cons: [String]
    let timeline: String?
    let approvals: [String]
    let estCost: String?
    let costStatus: TrustStatus
    let source: String?
    let metadata: [String: JSONValue]
}

struct BankingRecommendations: Codable, Equatable, Sendable {
    let banks: [BankRecommendation]
    let metadata: [String: JSONValue]
}

struct BankRecommendation: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let minBalance: String?
    let requirements: [String]
    let docsNeeded: [String]
    let likelyToApprove: Bool?
    let source: String?
    let metadata: [String: JSONValue]
}

struct FinalPlan: Codable, Equatable, Sendable {
    let roadmap: [String]
    let totalEstCost: String?
    let totalTimeline: String?
    let nextAction: String?
    let confidence: Double?
    let unverified: [String]
    let metadata: [String: JSONValue]
}

enum NextStepStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case done
}

struct NextStepChecklistItem: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String?
    var status: NextStepStatus
    let actionMetadata: [String: JSONValue]
    var isDone: Bool
}
```

### Profile Models

`Irshad/Models/ProfileModels.swift`

```swift
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
```

### Voice Models

`Irshad/Models/VoiceModels.swift`

```swift
enum VoiceState: Codable, Equatable, Sendable {
    case idle
    case listening
    case processing
    case transcriptReady
    case failed(String)
}

enum TranscriptState: Codable, Equatable, Sendable {
    case empty
    case partial
    case final
    case editing
    case accepted
}

struct SpeechTranscriptEvent: Codable, Equatable, Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Double?
}

enum SpeechAuthorizationStatus: Codable, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}
```

### Sharing Models

`Irshad/Models/SharingModels.swift`

```swift
struct SharePayload: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let url: URL?
    let items: [String]
}

struct SavedPlanSummary: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let sessionId: String
    let savedAt: Date
    let plan: FinalPlan
    let session: JourneySession
    let checklist: [NextStepChecklistItem]
}
```

### Error Models

`Irshad/Models/ErrorModels.swift`

```swift
enum APIError: Error, Equatable, Sendable {
    case invalidURL(String)
    case transport(String)
    case badStatus(Int, String?)
    case decoding(String)
    case timeout
    case cancelled
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
```

## Implementation Notes

- Implement custom `Codable` for `JSONValue`, `DynamicCardKind`, `DynamicCardType`, `DynamicCardOption`, `JourneySession`, `VerificationStatus`, and any model that needs aliases.
- `DynamicCardOption` string decoding rule: a raw string option becomes `id` from a normalized label, `label` as the raw string, `value` as the raw string, and empty metadata.
- `JourneyPhase.visibleOrder` is exactly: goal, business, founder, details, budget, documents, analysis, license, banking, verify, nextSteps, plan.
- `JourneyPhase` display order does not control network orchestration. The ViewModel later owns the API order.
- Do not fabricate default phone numbers, fees, license names, bank names, authorities, approvals, or timelines.

## Acceptance Criteria

- [ ] Every file listed in the file location section exists.
- [ ] All API-facing and persistence-facing models compile as `Codable`.
- [ ] `JSONValue` decodes strings, numbers, booleans, objects, arrays, and null.
- [ ] `JourneySession` decodes both `currentStage` and `currentPhase` without dropping filled slots.
- [ ] Dynamic card options decode from both string arrays and object arrays.
- [ ] Unknown card kind/type values decode to unsupported cases instead of throwing.
- [ ] `TrustStatus.guidanceOnly` encodes and decodes as `guidance_only`.
- [ ] Numeric answer drafts are stored as strings.
- [ ] No services, ViewModels, app entry files, SwiftUI views, UI components, theme files, styling, animations, or gestures are added by this prompt.
