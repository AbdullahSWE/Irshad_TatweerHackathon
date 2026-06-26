# Dev Specification: Irshad Rural Business Agent

## Source Contract

This development specification translates `files/PRD.md`, `files/UX-spec.md`, `files/build-order/ux-ui.md`, and `files/API-endpoints.md` into the non-UI Swift/iOS implementation contract.

`files/API-endpoints.md` is the compatibility source of truth when the source documents disagree. The iOS app is a thin SwiftUI client for a Next.js backend. Swift owns voice/text input, local session presentation state, API orchestration, local saved-plan persistence, and sharing. Swift must not own business rules, license logic, bank suitability, authority requirements, fee values, phone numbers, or journey-stage decisions.

Required backend base URL:

```swift
enum AppConfig {
    static let baseURL = URL(string: "http://localhost:3001/")!
}
```

Allowed backend routes:

| Operation | Method | Path |
|-----------|--------|------|
| Start journey | POST | `/api/journey/start` |
| Continue adaptive loop | POST | `/api/journey/next` |
| Analyze business profile | POST | `/api/analyze` |
| Verify live facts | POST | `/api/verify` |
| Recommend license | POST | `/api/license` |
| Recommend banking | POST | `/api/banking` |
| Generate final plan | POST | `/api/plan/final` |

Canonical network order:

```text
start -> next* -> analyze -> verify -> license -> banking -> plan
```

The UI can still show the 12 visible phases from the PRD/UX specs: `goal`, `business`, `founder`, `details`, `budget`, `documents`, `analysis`, `license`, `banking`, `verify`, `nextSteps`, `plan`. For API compatibility, `verify` is called before `license`; the visible phase model maps backend output into the UI without changing the network order. `nextSteps` is local checklist/final-plan presentation state, not a backend route.

---

## Pass 1: Data Model

**Core Entities:**

| Entity | Properties | Persistence | Source |
|--------|------------|-------------|--------|
| `JourneySession` | `sessionId`, `goalText`, `currentStage`, `currentPhase`, `filledSlots`, `history` | Memory during active journey; saved only inside final/saved plan payload if needed | Backend plus local answer updates |
| `JourneyHistoryItem` | `cardId`, `question`, `answer`, optional `slot`, optional `stage`, timestamp | Memory; included in session sent to backend | Local user answers and backend card metadata |
| `DynamicCard` | `cardId`, `kind`, `type`, `title`, `subtitle`, `options`, `slot`, `stage`, `phase`, metadata | Memory | Backend |
| `DynamicCardOption` | stable local `id`, `label`, optional backend `value`, optional metadata | Memory | Backend card options |
| `JourneyProgress` | `filled`, `required`, `stagesDone`, `stagesTotal` | Memory | Backend |
| `AnalysisSummary` | matched activities, setup cost range, candidate licenses, confidence, unverified items | Memory; saved in final plan | `/api/analyze` |
| `VerificationSummary` | status, info, verified facts, sources, authority, phone, contact URL, what to confirm, message | Memory; saved in final plan | `/api/verify` |
| `LicenseRecommendation` | best option, alternatives, cost status, issuer, approvals, source | Memory; saved in final plan | `/api/license` |
| `BankingRecommendations` | banks, minimum balance, requirements, docs needed, likely approval flag, source | Memory; saved in final plan | `/api/banking` |
| `FinalPlan` | roadmap, total estimated cost, total timeline, next action, confidence, unverified items | Local JSON for saved plan; share payload | `/api/plan/final` |
| `ProfileSection` / `ProfileField` | display-ready section title, field label, value, trust status, correction id | Derived memory | `JourneySession.filledSlots` and backend outputs |
| `NextStepChecklistItem` | id, title, detail, status, action metadata, local completion flag | Local memory; saved with plan | Derived from final plan/backend action fields |
| `SharePayload` | title, body, optional URL/items | Memory during share sheet | Local formatting from final plan |

**Relationships:**

- `JourneySession` has many `JourneyHistoryItem` records.
- `DynamicCard` may have many `DynamicCardOption` records.
- `JourneyViewModel` owns one active `JourneySession` and the current/previous `DynamicCard` values.
- `AnalysisSummary`, `VerificationSummary`, `LicenseRecommendation`, `BankingRecommendations`, and `FinalPlan` belong to one `sessionId`.
- `SavedPlanSummary` is derived from the latest `FinalPlan` plus enough session/profile context to reopen the final roadmap.

**Data Flow Direction:**

```text
Voice/Text/Card input
  -> JourneyViewModel draft state
  -> JourneySession.history + filledSlots update
  -> JourneyAPIService
  -> Backend response DTO
  -> View-facing models
  -> SwiftUI views
```

Output-stage flow:

```text
gate_open
  -> /api/analyze
  -> /api/verify
  -> /api/license
  -> /api/banking
  -> /api/plan/final
  -> local saved plan + share payload
```

**Codable Requirements:**

- All API request/response DTOs must be `Codable`.
- `JourneySession.filledSlots` must decode flexible JSON values, not only strings, because examples include strings, numbers, arrays, booleans, nulls, and backend-specific objects.
- `JourneySession` must accept both `currentStage` and `currentPhase` response keys. `currentStage` is preferred for `API-endpoints.md`; `currentPhase` is retained for PRD compatibility.
- `DynamicCard.type` must decode known card types and map unknown values to `.unsupported(rawValue:)` or an equivalent safe fallback without throwing the whole response away.
- `DynamicCard.options` must decode both string arrays and object arrays. String options become `DynamicCardOption(id: normalizedLabel, label: rawString, value: rawString)`.
- Output models must preserve unrecognized backend fields in `metadata` or flexible JSON only when needed for display/action forwarding; Swift must not interpret unknown legal/banking facts as business rules.

Required flexible JSON model:

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

Required trust statuses:

```swift
enum TrustStatus: String, Codable, CaseIterable, Sendable {
    case verified
    case estimated
    case unverified
    case missing
    case unknown
    case guidanceOnly = "guidance_only"
}
```

---

## Pass 2: State Ownership

**State Map:**

| State | Owner | Scope | Triggers Update When |
|-------|-------|-------|----------------------|
| `sessionId` | `JourneyViewModel` | Journey/session | New journey starts or saved plan opens |
| `journeyStatus` | `JourneyViewModel` | App screen | Start, collect, process, gate-open, output, complete, partial, failed |
| `currentPhase` | `JourneyViewModel` | App screen | Backend `currentStage/currentPhase`, output orchestration, local next-step mapping |
| `phases` | `JourneyViewModel` | App screen | Static 12-phase list initialized once |
| `completedPhases` | `JourneyViewModel` | App screen | Progress response or successful endpoint completion |
| `progress` | `JourneyViewModel` | App screen | Backend progress response or derived output-stage progress |
| `activeSession` | `JourneyViewModel` | Journey/session | Start response, answer submission, correction submission |
| `currentCard` | `JourneyViewModel` | Journey/screen | Start/next response returns a card |
| `renderableCards` | `JourneyViewModel` | Journey/screen | Current card/result cards are appended or replaced |
| `cardAnswerDraft` | `JourneyViewModel` | Screen/card | User selects, toggles, types, or edits a card answer |
| `voiceState` | `SpeechRecognitionService` source, mirrored by `JourneyViewModel` | Screen | Recording, transcription, permission, failure |
| `transcriptState`, `liveTranscript`, `editableTranscript`, `transcriptConfidence` | `JourneyViewModel` | Screen/input | Speech service emits partial/final transcription or user edits |
| `textFallbackValue` | `JourneyViewModel` | Screen/input | User types or clears text fallback |
| `analysisSummary` | `JourneyViewModel` | Results | `/api/analyze` succeeds |
| `verificationSummary` | `JourneyViewModel` | Results | `/api/verify` succeeds or returns `not_found` |
| `licenseRecommendation` | `JourneyViewModel` | Results | `/api/license` succeeds |
| `bankingRecommendations` | `JourneyViewModel` | Results | `/api/banking` succeeds |
| `finalPlan` | `JourneyViewModel` | Results/saved plan | `/api/plan/final` succeeds or saved plan opens |
| `nextStepChecklist` | `JourneyViewModel` | Results/local | Final plan arrives or user marks a local item done |
| `savedPlanSummary` | `LocalPlanStore`, mirrored by `JourneyViewModel` | App/local | Final plan saved or opened |
| `toast`, `banner`, `recoverableError`, `unsupportedCard` | `JourneyViewModel` | App/screen | Recoverable operation, malformed card, backend/speech/share failure |

**Observable Objects:**

| Object | Owned State | Observers |
|--------|-------------|-----------|
| `JourneyViewModel` (`@MainActor @Observable`) | All view-facing state listed in the UX/UI build order | `JourneyView`, card views, result views, saved plan views |
| `SpeechRecognitionService` | Internal audio engine, speech task, permission status | `JourneyViewModel` only |
| `SpeechSynthesisService` | Internal synthesizer status | `JourneyViewModel` only |
| `LocalPlanStore` | Persisted final plan JSON | `JourneyViewModel` only |
| `ShareService` | Share payload preparation and UIKit handoff state | `JourneyViewModel` only |

**Observable Properties:**

Use Swift Observation (`@Observable`) rather than Combine. The `JourneyViewModel` is `@MainActor`; properties read directly by SwiftUI are observable by default. Mark service dependencies, tasks, decoders, and encoders as `@ObservationIgnored`.

Required observable reads from the UX/UI build order:

- Journey identity/status: `appTitle`, `currentLanguage`, `layoutDirection`, `sessionId`, `journeyStatus`, `currentPhase`, `phases`, `completedPhases`, `progress`, `isBackendBusy`, `lastUpdatedAt`.
- Prompt/response: `currentPrompt`, `framingMessage`, `currentAssistantMessage`, `currentCard`, `cardAnswerDraft`, `cardValidationMessage`.
- Voice/text input: `voiceState`, `transcriptState`, `liveTranscript`, `editableTranscript`, `transcriptConfidence`, `textFallbackValue`, `canSubmitCurrentInput`, `inputErrorMessage`.
- Dynamic cards/profile: `renderableCards`, `profileSections`, `missingFields`, `unknownFields`, `correctionTarget`.
- Outputs: `analysisSummary`, `licenseRecommendation`, `bankingRecommendations`, `verificationSummary`, `nextStepChecklist`, `finalPlan`, `savedPlanSummary`.
- Trust/feedback: `confidence`, `verifiedFacts`, `estimatedFacts`, `unverifiedFacts`, `guidanceDisclaimer`, `toast`, `banner`, `recoverableError`, `unsupportedCard`.
- Presentation: `isTextEntryExpanded`, `isProfileExpanded`, `expandedRecommendationIDs`, `showSavedPlan`, `showShareSheet`, `sharePayload`, `copiedItemID`, `reduceMotionPreferred`.

**Derived/Computed State:**

- `canSubmitCurrentInput`: true when editable transcript or text fallback has non-whitespace content and no blocking request is in flight.
- `layoutDirection`: `.rightToLeft` when `currentLanguage == .ar`, otherwise `.leftToRight`.
- `profileSections`: derived from `activeSession.filledSlots`, missing/unknown fields, trust status arrays, and backend output summaries.
- `missingFields`: derived from profile fields marked `.missing`.
- `unknownFields`: derived from profile fields marked `.unknown`.
- `confidence`: latest available confidence in priority order: final plan, analysis, license/verification metadata.
- `verifiedFacts`, `estimatedFacts`, `unverifiedFacts`: aggregated from verification, license, banking, analysis, and final plan responses without inventing facts.
- `currentPrompt`: current card title or backend assistant/framing message fallback.

**Concurrency Rules:**

- All ViewModel mutations occur on the main actor.
- API calls run through an async service and return DTOs to the main actor.
- Only one backend operation may be active at a time for the active journey. Store the active `Task<Void, Never>?` as `@ObservationIgnored`.
- `cancelCurrentOperation()` cancels the active task and preserves current session/card/output state.
- Retry uses the last recorded `PendingOperation` value and must not clear previous answers or outputs before a successful response arrives.

---

## Pass 3: Service Layer

**Services Required:**

| Service | Responsibility | Dependencies | Failable |
|---------|----------------|--------------|----------|
| `JourneyAPIService` | POST to the seven backend endpoints, decode flexible responses, normalize paths | Foundation `URLSession`, `JSONEncoder`, `JSONDecoder`, `AppConfig.baseURL` | Yes |
| `SpeechRecognitionService` | Request speech permission, capture Arabic/English speech, emit partial/final transcript | `Speech`, `AVFoundation` | Yes |
| `SpeechSynthesisService` | Optional spoken Arabic/English assistant response | `AVFoundation.AVSpeechSynthesizer` | Yes, non-blocking |
| `LocalPlanStore` | Save/load/delete latest final plan locally as JSON | Foundation file APIs or `UserDefaults` for small MVP payload | Yes |
| `ShareService` | Build and present/carry share payload for final plan text/PDF-ready content | UIKit share sheet bridge, Foundation | Yes |
| `AnalyticsService` | Optional lightweight event recording hook | Local logging or no-op implementation | No for UI flow |

**Key Operations:**

| Operation | Input | Output | Side Effects |
|-----------|-------|--------|--------------|
| `startJourney` | `StartJourneyRequest` | `StartJourneyResponse` | Creates/updates backend session |
| `nextJourneyStep` | `NextJourneyRequest` | `NextJourneyResponse` | Advances backend journey or opens gate |
| `analyze` | `AnalyzeRequest` | `AnalyzeResponse` | Generates analysis output |
| `verify` | `VerifyRequest` | `VerifyResponse` | Confirms or marks live facts unconfirmed |
| `license` | `SessionOnlyRequest` | `LicenseResponse` | Generates license recommendation using verified facts server-side |
| `banking` | `SessionOnlyRequest` | `BankingResponse` | Generates banking recommendations |
| `finalPlan` | `SessionOnlyRequest` | `FinalPlanResponse` | Generates final roadmap |
| `beginListening` | language | transcript async stream or delegate callbacks | Starts audio session/speech task |
| `stopListening` | none | final transcript if available | Stops audio capture |
| `saveFinalPlan` | final plan/saved summary | `SavedPlanSummary` | Writes local JSON |
| `makeSharePayload` | final plan, trust facts | `SharePayload` | Formats user-safe share text |

**Exact Service Signatures:**

```swift
protocol JourneyAPIServiceProtocol: Sendable {
    func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse
    func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse
    func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse
    func verify(_ request: VerifyRequest) async throws -> VerifyResponse
    func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse
    func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse
    func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse
}

protocol SpeechRecognitionServiceProtocol: AnyObject {
    func requestAuthorization() async -> SpeechAuthorizationStatus
    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error>
    func stopListening() async
    func cancelListening() async
}

protocol SpeechSynthesisServiceProtocol: AnyObject {
    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async
    func stopSpeaking() async
}

protocol LocalPlanStoreProtocol: Sendable {
    func loadSavedPlan() async throws -> SavedPlanSummary?
    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary
    func deleteSavedPlan() async throws
}

protocol ShareServiceProtocol: Sendable {
    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload
    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String
}

protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent) async
}
```

**Endpoint Request Contracts:**

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

**Path Joining Requirement:**

`JourneyAPIService` must join endpoint paths safely with `http://localhost:3001/` whether callers provide `api/analyze` or `/api/analyze`. Do not use naive string concatenation. Normalize by trimming leading slashes from paths before resolving against `baseURL`.

```swift
func url(for path: String) throws -> URL {
    let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard let url = URL(string: normalized, relativeTo: AppConfig.baseURL)?.absoluteURL else {
        throw APIError.invalidURL(path)
    }
    return url
}
```

**iOS Framework Dependencies:**

- `Foundation`: URLSession, Codable, dates, UUID, file persistence.
- `Observation`: `@Observable` ViewModel.
- `SwiftUI`: app entry and environment contracts only; view code belongs to UX/UI pipeline.
- `Speech`: speech recognition permissions and transcription.
- `AVFoundation`: audio session, recording support, optional text-to-speech.
- `UIKit`: share sheet, open URLs, tel links from backend-provided phone values.

**Error Types:**

| Error | Cause | Recovery |
|-------|-------|----------|
| `APIError.invalidURL` | Endpoint path cannot resolve against base URL | Developer fix; show generic retry only if surfaced |
| `APIError.transport` | Network/DNS/server unavailable | Preserve state, show retry |
| `APIError.badStatus` | Non-2xx response | Preserve state, show retry with backend message if safe |
| `APIError.decoding` | Malformed response | Preserve state, show unsupported/retry state |
| `APIError.timeout` | Backend exceeds timeout | Preserve state, show retry |
| `SpeechError.permissionDenied` | User denies speech recognition or mic | Keep text fallback active |
| `SpeechError.recognitionFailed` | Speech task fails or low confidence | Allow retry/edit/type |
| `PlanStoreError.writeFailed` | Local persistence fails | Keep final plan visible; show save warning |
| `ShareError.unavailable` | No final plan/share payload | Disable or show fallback copy error |

---

## Pass 4: ViewModel Architecture

**ViewModels:**

| Screen | ViewModel | Owned State | Actions |
|--------|-----------|-------------|---------|
| Welcome / Journey / Results / Saved Plan | `JourneyViewModel` | All journey, input, card, output, feedback, presentation, and saved-plan state | All methods listed in the UX/UI build-order contract |

Use one ViewModel for MVP because the backend session is the single source of truth and the UX/UI build order expects one injected observable object. Avoid child ViewModels until the feature surface grows enough to justify splitting.

**ViewModel Interfaces:**

| ViewModel | Observable Properties | Public Methods |
|-----------|-----------------------|----------------|
| `JourneyViewModel` | `appTitle`, `currentLanguage`, `layoutDirection`, `sessionId`, `journeyStatus`, `currentPhase`, `phases`, `completedPhases`, `progress`, `isBackendBusy`, `lastUpdatedAt`, prompt/card/input/output/trust/presentation state | Journey lifecycle, speech/transcript, card actions, correction/profile, output actions, final plan/sharing, feedback dismissal |

Required declaration:

```swift
@MainActor
@Observable
final class JourneyViewModel {
    @ObservationIgnored private let apiService: JourneyAPIServiceProtocol
    @ObservationIgnored private let speechRecognitionService: SpeechRecognitionServiceProtocol
    @ObservationIgnored private let speechSynthesisService: SpeechSynthesisServiceProtocol
    @ObservationIgnored private let localPlanStore: LocalPlanStoreProtocol
    @ObservationIgnored private let shareService: ShareServiceProtocol
    @ObservationIgnored private let analyticsService: AnalyticsServiceProtocol
    @ObservationIgnored private var activeTask: Task<Void, Never>?
    @ObservationIgnored private var pendingOperation: PendingOperation?
}
```

**Required ViewModel Reads:**

```swift
let appTitle: String
var currentLanguage: AppLanguage
var layoutDirection: LayoutDirection
var sessionId: String
var journeyStatus: JourneyStatus
var currentPhase: JourneyPhase
var phases: [JourneyPhase]
var completedPhases: Set<JourneyPhase>
var progress: JourneyProgress?
var isBackendBusy: Bool
var lastUpdatedAt: Date?

var currentPrompt: String?
var framingMessage: String?
var currentAssistantMessage: String?
var currentCard: DynamicCard?
var cardAnswerDraft: CardAnswerDraft
var cardValidationMessage: String?

var voiceState: VoiceState
var transcriptState: TranscriptState
var liveTranscript: String
var editableTranscript: String
var transcriptConfidence: Double?
var textFallbackValue: String
var canSubmitCurrentInput: Bool
var inputErrorMessage: String?

var renderableCards: [DynamicCard]
var profileSections: [ProfileSection]
var missingFields: [ProfileField]
var unknownFields: [ProfileField]
var correctionTarget: CorrectionTarget?

var analysisSummary: AnalysisSummary?
var licenseRecommendation: LicenseRecommendation?
var bankingRecommendations: BankingRecommendations?
var verificationSummary: VerificationSummary?
var nextStepChecklist: [NextStepChecklistItem]
var finalPlan: FinalPlan?
var savedPlanSummary: SavedPlanSummary?

var confidence: Double?
var verifiedFacts: [TrustFact]
var estimatedFacts: [TrustFact]
var unverifiedFacts: [TrustFact]
var guidanceDisclaimer: String
var toast: ToastState?
var banner: BannerState?
var recoverableError: RecoverableError?
var unsupportedCard: DynamicCard?

var isTextEntryExpanded: Bool
var isProfileExpanded: Bool
var expandedRecommendationIDs: Set<String>
var showSavedPlan: Bool
var showShareSheet: Bool
var sharePayload: SharePayload?
var copiedItemID: String?
var reduceMotionPreferred: Bool
```

**Required Public Methods:**

```swift
func startJourneyWithVoice()
func startJourneyWithText(_ text: String)
func submitCurrentAnswer()
func submitCardAnswer(_ cardID: String)
func retryCurrentStep()
func cancelCurrentOperation()

func beginListening()
func stopListening()
func retryListening()
func acceptTranscript()
func updateTranscript(_ value: String)
func updateTextFallback(_ value: String)

func selectSingleOption(cardID: String, optionID: String)
func toggleMultiOption(cardID: String, optionID: String)
func updateCardText(cardID: String, value: String)
func updateCardNumber(cardID: String, value: String)
func setToggleAnswer(cardID: String, value: Bool)
func toggleChecklistItem(cardID: String, itemID: String)
func expandCard(_ cardID: String)
func collapseCard(_ cardID: String)

func beginCorrection(fieldID: String)
func submitCorrection(_ value: String)
func cancelCorrection()

func expandRecommendation(_ id: String)
func savePreferredBank(_ id: String)
func openURL(_ url: URL)
func callPhoneNumber(_ phoneNumber: String)
func copyText(_ text: String)
func markNextStepDone(_ id: String)

func openSavedPlan()
func shareFinalPlan()
func copyFinalPlanSummary()
func continueWithAssistant()
func dismissToast()
func dismissBanner()
```

**Endpoint Orchestration:**

- `startJourneyWithText(_:)` creates a UUID session if needed, sends `StartJourneyRequest(sessionId, goalText, language)`, stores response session/card/framing, sets `currentPhase` to backend stage mapped into visible phase, and enters `.collecting`.
- `startJourneyWithVoice()` begins listening. After transcript acceptance, it delegates to `startJourneyWithText(editableTranscript)`.
- `submitCurrentAnswer()` sends either text/transcript as the answer for the active card or starts the journey if no active session exists.
- `submitCardAnswer(_:)` validates the draft, appends a local `JourneyHistoryItem`, updates local filled slot only as display/session echo, then calls `/api/journey/next` with the full `JourneySession`.
- If `/api/journey/next` returns `collecting`, update card/progress/stage and continue.
- If `/api/journey/next` returns `gate_open`, set `journeyStatus = .gateOpen`, then run output stages in this exact order: analyze, verify, license, banking, final plan.
- `verifyTarget` is derived from `analysisSummary.candidateLicenses.first` plus the critical facts phrase, e.g. `"<candidate> fee + requirements 2026"`. If no candidate exists, use a conservative backend-facing target such as `"best candidate license fee + requirements 2026"` and let the backend decide.
- `/api/license` must be called only after `/api/verify` returns, even when verification returns `not_found`.
- `/api/banking` must be called after license.
- `/api/plan/final` must be called after banking. If banking is temporarily skipped by product decision later, that must be documented in `API-endpoints.md` before changing the client flow.

**Data Bindings:**

| ViewModel | Provides to View | Receives from View |
|-----------|------------------|--------------------|
| `JourneyViewModel` | phase/progress, card models, drafts, profile, trust facts, output summaries, errors, share payload | voice/text starts, transcript edits, card answers, correction values, retry/cancel, expand/collapse, copy/share/open/call actions |

**Environment Dependencies:**

- Root app creates or injects one `JourneyViewModel` at the screen boundary using `@State`.
- SwiftUI views should receive the same ViewModel instance through initializer injection or environment as selected by the UI build order.
- No dependency injection framework is used. Provide a simple initializer with default concrete services for app runtime and protocol-based test doubles for tests.

---

## Pass 5: Navigation Architecture

**Navigation Model:**

- Primary pattern: single-root SwiftUI journey shell for MVP.
- State management: `JourneyStatus` and `JourneyPhase` drive visible screen content; backend stage state drives phase changes.
- Saved plan can be a sheet or navigation destination from the root shell, controlled by `showSavedPlan`.
- Share is presented by `showShareSheet` and `sharePayload`.

**Route Definitions:**

| Route / Presentation | Trigger | Data Required | Destination ViewModel |
|----------------------|---------|---------------|-----------------------|
| Welcome state | App launch with no active session/final plan | None | `JourneyViewModel` |
| Journey collecting state | Successful start or next card | `JourneySession`, optional `DynamicCard` | `JourneyViewModel` |
| Output state | `gate_open` or output endpoint in progress | `sessionId`, active session | `JourneyViewModel` |
| Saved plan | `openSavedPlan()` or app launch with saved plan | `SavedPlanSummary` / `FinalPlan` | `JourneyViewModel` |
| Share sheet | `shareFinalPlan()` | `SharePayload` | `JourneyViewModel` |
| External URL | `openURL(_:)` | Backend-provided URL only | System |
| Phone link | `callPhoneNumber(_:)` | Backend-provided phone only | System |

**Navigation State:**

| State | Scope | Persists Across |
|-------|-------|-----------------|
| `journeyStatus` | Root screen | In-memory session; restored only from saved plan as final view |
| `currentPhase` | Root screen | Current active session |
| `completedPhases` | Root screen | Current active session and saved final plan summary |
| `showSavedPlan` | Presentation | Until dismissed |
| `showShareSheet` | Presentation | Until share dismissed |

**Visible Phase Mapping:**

| Backend stage/output | Visible phase |
|----------------------|---------------|
| start/framing | `goal` |
| `business` | `business` |
| `founder` | `founder` |
| `details` | `details` |
| `budget` | `budget` |
| `documents` | `documents` |
| `/api/analyze` | `analysis` |
| `/api/verify` | `verify` |
| `/api/license` | `license` |
| `/api/banking` | `banking` |
| local checklist derived from final plan | `nextSteps` |
| `/api/plan/final` | `plan` |

Even though the compact 12-phase UI lists `license`, `banking`, and `verify`, the network sequence remains API-compatible: `analysis -> verify -> license -> banking -> plan`. Completion markers can mark `verify` before `license` internally; the UI can visually preserve the 12 labels without creating extra routes.

**Modal/Sheet Presentations:**

| Presentation | Trigger | Binding Type | Dismiss Condition |
|--------------|---------|--------------|-------------------|
| Saved plan | `openSavedPlan()` | `showSavedPlan: Bool` | User dismisses or returns to journey |
| Share sheet | `shareFinalPlan()` | `showShareSheet: Bool`, `sharePayload` | System share completes/cancels |
| Toast/banner | Recoverable operation result | optional state object | Timeout or explicit dismissal |

**Deep Link Handling:**

- No custom app deep links for MVP.
- `openURL(_:)` only opens backend-provided official URLs or locally generated safe URLs.
- `callPhoneNumber(_:)` builds a `tel:` URL only from backend-provided phone values. Never fabricate phone numbers and never show simulated call progress.

---

## Pass 6: Error Boundaries

**User-Facing Errors:**

| Error | Display | Recovery Action |
|-------|---------|-----------------|
| Backend unreachable | Inline/banner: "I could not reach the server. Please try again." | Retry current operation |
| Backend timeout | Same current content with retry | Retry; do not clear answers |
| Decode failure for whole response | Recoverable error plus retry | Retry current endpoint |
| Unsupported card type | Unsupported card fallback using card title if available | Retry or answer by text if possible |
| Malformed optional card data | Render available required content; hide broken optional fields | Continue or retry if required content missing |
| Speech permission denied | Permission fallback; text input remains active | Type answer or open settings |
| Speech recognition failed | "I could not hear clearly..." style error | Retry voice, edit transcript, or type |
| Low confidence transcript | Partial transcript state | Edit, retry, or submit |
| Verification not found | Verification card with authority/contact question from backend | Continue to license with unverified label |
| Share unavailable | Final plan stays visible; copy fallback if possible | Retry share or copy summary |
| Local save failed | Non-blocking warning | Retry save; keep final plan visible |

**Loading States:**

| Operation | Duration | UI During |
|-----------|----------|-----------|
| App prepare/saved plan load | Short | Preparing state, no blank screen |
| Speech authorization/listening | Immediate to ongoing | Voice state updates and transcript area |
| `/api/journey/start` | Backend latency | Preserve entered goal; show backend busy after 500ms |
| `/api/journey/next` | Backend latency | Preserve current card/session; show busy/progress after 500ms |
| Output chain | Potentially longer | Show current output phase, keep completed outputs visible |
| Share payload | Short | Disable duplicate share, preserve final plan |

**Permission Requirements:**

| Permission | When Requested | If Denied |
|------------|----------------|-----------|
| Speech recognition | First voice start or explicit voice permission setup | Use text fallback |
| Microphone | First listening attempt | Use text fallback |
| Network | Implicit backend calls | Show retry; preserve state |

**Edge Cases Handled:**

| Case | Detection | Handling |
|------|-----------|----------|
| Backend returns `status: "ready"` instead of `gate_open` | Decode status alias | Treat as gate open only if no card and progress indicates complete; otherwise show recoverable backend-state error |
| Response has `currentPhase` but no `currentStage` | Decode alias | Map `currentPhase` to visible/backend phase |
| Response has unknown stage/phase | Unknown enum fallback | Keep current phase and show backend-provided card if renderable |
| Card options are strings | Decoder branch | Convert to `DynamicCardOption` |
| Card options are objects | Decoder branch | Preserve id/label/value metadata |
| `filledSlots` values are not strings | `JSONValue` | Decode safely and display user-safe strings |
| Verification lacks phone | Optional phone/contact URL | Show only fields backend provided |
| Final plan missing optional banking | Optional model fields | Show partial labels; preserve unverified/guidance status |
| User retries after partial output success | `pendingOperation` | Retry failed endpoint only; keep prior outputs visible |
| User cancels in-flight request | task cancellation | Stop busy state; preserve session/card |

**Offline Behavior:**

- Existing saved final plan can be opened offline if it was saved locally.
- Active journey, analysis, verification, license, banking, and final plan generation require the backend.
- Speech-to-text may work depending on Apple service availability; text fallback remains available.
- Offline errors must not delete active session state.

---

## Implementation Specification

### Project Structure

```text
Irshad/
├── App/
│   ├── IrshadApp.swift
│   ├── AppConfig.swift
│   └── AppEnvironment.swift
├── Models/
│   ├── AppLanguage.swift
│   ├── JourneyPhase.swift
│   ├── JourneyStatus.swift
│   ├── JourneySession.swift
│   ├── DynamicCard.swift
│   ├── CardAnswerDraft.swift
│   ├── FlexibleJSON.swift
│   ├── ProgressModels.swift
│   ├── OutputModels.swift
│   ├── ProfileModels.swift
│   ├── TrustModels.swift
│   ├── VoiceModels.swift
│   ├── SharingModels.swift
│   └── ErrorModels.swift
├── Services/
│   ├── JourneyAPIService.swift
│   ├── APIRequests.swift
│   ├── APIResponses.swift
│   ├── SpeechRecognitionService.swift
│   ├── SpeechSynthesisService.swift
│   ├── LocalPlanStore.swift
│   ├── ShareService.swift
│   └── AnalyticsService.swift
├── ViewModels/
│   └── JourneyViewModel.swift
├── Navigation/
│   └── JourneyRouter.swift
├── Utilities/
│   ├── URL+EndpointJoining.swift
│   ├── JSONValue+Display.swift
│   ├── ClipboardClient.swift
│   └── DateFormatting.swift
├── Theme/          # Created/populated by UX/UI build order
├── Views/          # Created/populated by UX/UI build order
└── Components/     # Created/populated by UX/UI build order
```

`Theme/`, `Views/`, and `Components/` must exist for the UX/UI pipeline but are not populated by this dev spec.

### File Specifications

#### `AppConfig.swift`

**Purpose:** Centralize backend configuration.

**Contains:**
- `AppConfig`: no-instance namespace with `baseURL`.

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- `baseURL` must be exactly `http://localhost:3001/`.
- Do not add environment switching unless later requested.

#### `AppEnvironment.swift`

**Purpose:** Build runtime services and inject them into `JourneyViewModel`.

**Contains:**
- `AppEnvironment`: service factory for app runtime.

**Dependencies:**
- Foundation, Speech, AVFoundation, UIKit services where needed.

**Key Implementation Notes:**
- Use protocol-typed dependencies for testability.
- No DI framework.

#### `AppLanguage.swift`

**Purpose:** Represent app/backend language values.

**Contains:**
- `AppLanguage`: `ar`, `en`.
- Optional `VoicePersona`: `male`, `female` for local voice selection only.

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- Start requests send only `language` unless backend docs add persona.

#### `JourneyPhase.swift`

**Purpose:** Provide visible 12-phase UI model and backend-stage mapping.

**Contains:**
- `JourneyPhase`: `goal`, `business`, `founder`, `details`, `budget`, `documents`, `analysis`, `license`, `banking`, `verify`, `nextSteps`, `plan`, `unknown`.
- mapping from backend `currentStage/currentPhase` strings.

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- Do not use phase order to decide backend journey logic.

#### `JourneyStatus.swift`

**Purpose:** Track high-level journey screen state.

**Contains:**
- `JourneyStatus`: `empty`, `preparing`, `collecting`, `processing`, `gateOpen`, `showingResults`, `complete`, `partial`, `failed`.

**Dependencies:**
- Foundation.

#### `JourneySession.swift`

**Purpose:** Model the backend session as the single source of truth.

**Contains:**
- `JourneySession`
- `JourneyHistoryItem`

**Dependencies:**
- Foundation, `JSONValue`, `JourneyPhase`.

**Key Implementation Notes:**
- Decode both `currentStage` and `currentPhase`.
- Encode the current canonical field expected by backend while preserving known aliases if required by tests.
- `filledSlots` type is `[String: JSONValue]`.

#### `DynamicCard.swift`

**Purpose:** Decode and represent backend-driven cards.

**Contains:**
- `DynamicCard`
- `DynamicCardKind`
- `DynamicCardType`
- `DynamicCardOption`

**Dependencies:**
- Foundation, `JSONValue`, `JourneyPhase`, `TrustStatus`.

**Key Implementation Notes:**
- Unknown types decode to unsupported.
- `options` decodes from strings or objects.
- No business-specific card rules.

#### `CardAnswerDraft.swift`

**Purpose:** Store local in-progress answers before backend submission.

**Contains:**
- `CardAnswerDraft`
- `CardAnswerValue`

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- Supports single select, multi select, text, number string, toggle, and checklist selections.
- Numeric drafts remain strings until backend receives the answer to avoid locale parsing mistakes.

#### `FlexibleJSON.swift`

**Purpose:** Provide a safe Codable representation for variable backend values.

**Contains:**
- `JSONValue`
- display helpers in an extension or companion file.

**Dependencies:**
- Foundation.

#### `ProgressModels.swift`

**Purpose:** Model progress returned by collection endpoints and derived output progress.

**Contains:**
- `JourneyProgress`

**Dependencies:**
- Foundation.

#### `OutputModels.swift`

**Purpose:** Model analyze, verify, license, banking, and final plan response content.

**Contains:**
- `AnalysisSummary`
- `MatchedActivity`
- `VerificationSummary`
- `VerifiedFacts`
- `LicenseRecommendation`
- `LicenseOption`
- `BankingRecommendations`
- `BankRecommendation`
- `FinalPlan`
- `NextStepChecklistItem`

**Dependencies:**
- Foundation, `TrustStatus`, `JSONValue`.

**Key Implementation Notes:**
- Optional fields stay optional; missing facts must become missing/unknown/unverified display state, not invented values.

#### `ProfileModels.swift`

**Purpose:** Provide view-facing profile sections from session slots.

**Contains:**
- `ProfileSection`
- `ProfileField`
- `CorrectionTarget`

**Dependencies:**
- Foundation, `TrustStatus`.

#### `TrustModels.swift`

**Purpose:** Model trust labels and fact bundles used across result cards and sharing.

**Contains:**
- `TrustStatus`
- `TrustFact`
- `TrustFactBundle`

**Dependencies:**
- Foundation.

#### `VoiceModels.swift`

**Purpose:** Model speech and transcript state.

**Contains:**
- `VoiceState`
- `TranscriptState`
- `SpeechTranscriptEvent`
- `SpeechAuthorizationStatus`
- `VoicePersona`

**Dependencies:**
- Foundation.

#### `SharingModels.swift`

**Purpose:** Model share/copy payloads.

**Contains:**
- `SharePayload`
- `SavedPlanSummary`

**Dependencies:**
- Foundation.

#### `ErrorModels.swift`

**Purpose:** Model user-safe recoverable errors.

**Contains:**
- `APIError`
- `SpeechError`
- `PlanStoreError`
- `ShareError`
- `RecoverableError`
- `ToastState`
- `BannerState`

**Dependencies:**
- Foundation.

#### `JourneyAPIService.swift`

**Purpose:** Execute backend POST requests and decode responses.

**Contains:**
- `JourneyAPIServiceProtocol`
- `JourneyAPIService`
- shared generic `post` helper.

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- Uses `AppConfig.baseURL`.
- Normalizes endpoint paths.
- Sets `Content-Type: application/json`.
- Applies reasonable timeout through `URLRequest.timeoutInterval`.
- Does not retry automatically; ViewModel owns user-visible retry.

#### `APIRequests.swift`

**Purpose:** Define request DTOs for all allowed endpoints.

**Contains:**
- `StartJourneyRequest`
- `NextJourneyRequest`
- `AnalyzeRequest`
- `VerifyRequest`
- `SessionOnlyRequest`

**Dependencies:**
- Foundation, session models.

#### `APIResponses.swift`

**Purpose:** Define response DTOs for all allowed endpoints.

**Contains:**
- `StartJourneyResponse`
- `NextJourneyResponse`
- `AnalyzeResponse`
- `VerifyResponse`
- `LicenseResponse`
- `BankingResponse`
- `FinalPlanResponse`

**Dependencies:**
- Foundation, dynamic card/output/session models.

**Key Implementation Notes:**
- `NextJourneyResponse.status` supports `collecting`, `gate_open`, `ready`, and unknown fallback.
- `VerifyResponse.status` supports `verified`, `not_found`, and unknown fallback.

#### `SpeechRecognitionService.swift`

**Purpose:** Wrap Apple Speech and microphone capture.

**Contains:**
- `SpeechRecognitionServiceProtocol`
- `SpeechRecognitionService`

**Dependencies:**
- Speech, AVFoundation.

**Key Implementation Notes:**
- Supports Arabic by default and English fallback.
- Emits partial and final transcript events.
- Permission denial must not block text input.

#### `SpeechSynthesisService.swift`

**Purpose:** Optional assistant speech playback.

**Contains:**
- `SpeechSynthesisServiceProtocol`
- `SpeechSynthesisService`

**Dependencies:**
- AVFoundation.

**Key Implementation Notes:**
- Non-blocking. Failure should not fail the journey.

#### `LocalPlanStore.swift`

**Purpose:** Persist the latest final plan locally.

**Contains:**
- `LocalPlanStoreProtocol`
- `LocalPlanStore`

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- MVP can store one saved plan JSON.
- Use app support directory or `UserDefaults` only if payload stays small.

#### `ShareService.swift`

**Purpose:** Prepare final plan share/copy content.

**Contains:**
- `ShareServiceProtocol`
- `ShareService`

**Dependencies:**
- Foundation; UIKit presentation bridge is handled by UX/UI layer or a small adapter.

**Key Implementation Notes:**
- Shared/copy text must preserve verified, estimated, unverified, missing, unknown, and guidance-only labels.

#### `AnalyticsService.swift`

**Purpose:** Optional no-op-friendly analytics hook.

**Contains:**
- `AnalyticsServiceProtocol`
- `AnalyticsService`
- `NoopAnalyticsService`
- `AnalyticsEvent`

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- Analytics must never be user-facing.
- No external analytics package for MVP.

#### `JourneyViewModel.swift`

**Purpose:** Own all view-facing app state and orchestrate services.

**Contains:**
- `JourneyViewModel`
- `PendingOperation`

**Dependencies:**
- Observation, SwiftUI for `LayoutDirection`, Foundation, service protocols, models.

**Key Implementation Notes:**
- `@MainActor @Observable`.
- Matches the UX/UI build-order interface exactly.
- Does not contain licensing/banking/authority business logic.

#### `JourneyRouter.swift`

**Purpose:** Isolate simple presentation decisions for saved plan/share/external actions.

**Contains:**
- `JourneyRouter` or lightweight route enum if useful.

**Dependencies:**
- Foundation.

**Key Implementation Notes:**
- Keep routing simple; no tab shell for MVP.

### Dependencies

**Swift Package Manager:**

| Package | Version | Purpose |
|---------|---------|---------|
| None | N/A | MVP uses native Apple frameworks only |

**System Frameworks:**

| Framework | APIs Used |
|-----------|-----------|
| SwiftUI | App entry, root state injection, view-facing types |
| Observation | `@Observable`, `@ObservationIgnored` |
| Foundation | URLSession, Codable, Date, UUID, file persistence |
| Speech | Speech recognition authorization and transcription |
| AVFoundation | Audio session, recording support, text-to-speech |
| UIKit | Share sheet bridge, clipboard/open URL/tel handoff where required |

### Contract Registry

**Endpoint constants:**

```swift
enum JourneyEndpoint: String, CaseIterable {
    case start = "/api/journey/start"
    case next = "/api/journey/next"
    case analyze = "/api/analyze"
    case verify = "/api/verify"
    case license = "/api/license"
    case banking = "/api/banking"
    case finalPlan = "/api/plan/final"
}
```

**Threading Policy:**

| Type/File | Policy |
|-----------|--------|
| `JourneyViewModel` | `@MainActor @Observable` |
| `JourneyAPIService` | `final`, async methods, no main-actor isolation |
| `SpeechRecognitionService` | class wrapping Apple delegates; callback/event delivery normalized before ViewModel mutation |
| `SpeechSynthesisService` | class; main actor only if AVSpeechSynthesizer delegate handling requires it |
| `LocalPlanStore` | async methods; can use actor if file writes become concurrent |
| Models | `Codable`, `Equatable` where useful, `Sendable` where safe |

**State Management Gates:**

- ViewModels must explicitly mark service dependencies, tasks, encoders, and decoders as `@ObservationIgnored`.
- All properties listed in the UX/UI build-order "ViewModel Reads" must exist before UI prompts are implemented.
- Any new endpoint or route must be added to `API-endpoints.md` before Swift introduces it.

### Integration Points With UI

**JourneyViewModel:**

Observable properties (views read these):

- `appTitle: String` - fixed app title, `Irshad`.
- `currentLanguage: AppLanguage` - defaults to `.ar`.
- `layoutDirection: LayoutDirection` - derived from language.
- `sessionId: String` - active UUID string.
- `journeyStatus: JourneyStatus` - root state.
- `currentPhase: JourneyPhase` - visible phase.
- `phases: [JourneyPhase]` - 12 visible phases.
- `completedPhases: Set<JourneyPhase>` - completed phase markers.
- `progress: JourneyProgress?` - fine-grained and stage progress.
- `isBackendBusy: Bool` - true during backend operation.
- `lastUpdatedAt: Date?` - last successful state update.
- `currentPrompt: String?` - current question/prompt.
- `framingMessage: String?` - start response framing.
- `currentAssistantMessage: String?` - current backend assistant text if provided.
- `currentCard: DynamicCard?` - active backend card.
- `cardAnswerDraft: CardAnswerDraft` - in-progress card answer.
- `cardValidationMessage: String?` - validation text for current draft.
- `voiceState: VoiceState` - voice lifecycle.
- `transcriptState: TranscriptState` - transcript lifecycle.
- `liveTranscript: String` - partial speech result.
- `editableTranscript: String` - user-editable final transcript.
- `transcriptConfidence: Double?` - speech confidence if available.
- `textFallbackValue: String` - typed fallback.
- `canSubmitCurrentInput: Bool` - submit enablement.
- `inputErrorMessage: String?` - user-safe input error.
- `renderableCards: [DynamicCard]` - current/history/output cards for UI rendering.
- `profileSections: [ProfileSection]` - display-ready profile fields.
- `missingFields: [ProfileField]` - missing profile fields.
- `unknownFields: [ProfileField]` - unknown profile fields.
- `correctionTarget: CorrectionTarget?` - active correction context.
- `analysisSummary: AnalysisSummary?` - analysis card data.
- `licenseRecommendation: LicenseRecommendation?` - license card data.
- `bankingRecommendations: BankingRecommendations?` - bank card data.
- `verificationSummary: VerificationSummary?` - verification card data.
- `nextStepChecklist: [NextStepChecklistItem]` - local next-step checklist.
- `finalPlan: FinalPlan?` - final roadmap data.
- `savedPlanSummary: SavedPlanSummary?` - saved plan entry data.
- `confidence: Double?` - latest confidence.
- `verifiedFacts: [TrustFact]` - verified facts.
- `estimatedFacts: [TrustFact]` - estimated facts.
- `unverifiedFacts: [TrustFact]` - unverified facts.
- `guidanceDisclaimer: String` - reusable guidance disclaimer.
- `toast: ToastState?` - transient feedback.
- `banner: BannerState?` - persistent feedback.
- `recoverableError: RecoverableError?` - retryable error.
- `unsupportedCard: DynamicCard?` - unsupported/malformed card context.
- `isTextEntryExpanded: Bool` - presentation.
- `isProfileExpanded: Bool` - presentation.
- `expandedRecommendationIDs: Set<String>` - expanded output rows/cards.
- `showSavedPlan: Bool` - saved plan presentation.
- `showShareSheet: Bool` - share presentation.
- `sharePayload: SharePayload?` - share data.
- `copiedItemID: String?` - copy feedback target.
- `reduceMotionPreferred: Bool` - presentation input from environment/UI.

Public methods (views call these):

- `startJourneyWithVoice()` - start voice-first journey.
- `startJourneyWithText(_:)` - start journey from typed text.
- `submitCurrentAnswer()` - submit transcript/text answer for current context.
- `submitCardAnswer(_:)` - submit current card draft.
- `retryCurrentStep()` - retry last failed operation.
- `cancelCurrentOperation()` - cancel in-flight task.
- `beginListening()`, `stopListening()`, `retryListening()` - speech controls.
- `acceptTranscript()`, `updateTranscript(_:)`, `updateTextFallback(_:)` - transcript/text controls.
- Card answer methods exactly as listed in Pass 4.
- Correction/profile methods exactly as listed in Pass 4.
- Output/share methods exactly as listed in Pass 4.

Binding requirements:

- `@Bindable` is needed where SwiftUI edits `editableTranscript`, `textFallbackValue`, card text/number drafts, expanded presentation flags, or correction values directly.
- Selection/toggle/checklist cards should call ViewModel methods instead of binding directly into backend models.

Environment/injection:

- Root app creates `@State private var viewModel = JourneyViewModel(environment: .live)` or equivalent.
- UX/UI views receive the same ViewModel instance.
- Services are injected through initializer defaults; tests inject mock services.

---

## Test Cases And Scenarios

### URL And Endpoint Tests

- Given `AppConfig.baseURL = http://localhost:3001/`, `JourneyAPIService.url(for: "/api/analyze")` returns `http://localhost:3001/api/analyze`.
- Same test for `api/analyze` with no leading slash.
- Verify all seven `JourneyEndpoint` cases resolve correctly.
- Verify no route outside the seven allowed paths is referenced by `JourneyAPIService`.

### Decoding Tests

- Decode `/api/journey/start` sample with `framing`, `activity`, and `card`.
- Decode `/api/journey/next` `collecting` response with `currentStage`, `progress`, and card.
- Decode stage-advanced response with `stageJustCompleted`.
- Decode `gate_open` response.
- Decode `ready` alias as compatible gate-open behavior only in the response adapter.
- Decode card options as `[String]`.
- Decode card options as object array with `id`, `label`, `value`.
- Decode unknown card type as unsupported without throwing.
- Decode `filledSlots` containing strings, numbers, booleans, arrays, objects, and null.
- Decode `/api/verify` `verified` response.
- Decode `/api/verify` `not_found` response with authority/phone/message.
- Decode license, banking, and final plan samples with optional fields missing.

### ViewModel State Tests

- Start from text creates session, posts language `.ar`, stores first card, enters `.collecting`.
- Speech permission denied keeps text fallback active and does not mark journey failed.
- Submit card answer appends history, sends full session to `/api/journey/next`, and preserves current card until response succeeds.
- `collecting` next response updates card, phase, progress, and profile.
- `gate_open` triggers output chain in exact order: analyze, verify, license, banking, final plan.
- Verification `not_found` still proceeds to license and marks unverified facts.
- API failure during banking preserves analysis, verification, and license outputs and allows retrying banking.
- Final plan success creates checklist, saves local plan, and marks journey complete.
- Cancel operation stops busy state without clearing session.
- Retry current step repeats only the failed pending operation.

### Trust And Safety Tests

- Final share/copy payload includes unverified and guidance labels.
- `callPhoneNumber(_:)` rejects empty/local fabricated values and only acts on backend-provided phone strings.
- UI-facing profile/output derivation does not create license, bank, fee, authority, or phone values not present in backend/session data.
- Unknown/missing facts display as `.unknown`, `.missing`, or `.unverified`, never as `.verified`.

### Persistence And Sharing Tests

- Save/load/delete latest final plan.
- Saved plan opens final roadmap without requiring backend.
- Save failure leaves final plan visible and shows recoverable warning.
- Share unavailable leaves final plan visible and allows copy fallback if payload exists.

### Accessibility/Localization-Adjacent Dev Tests

- `currentLanguage` defaults to `.ar`.
- `layoutDirection` is `.rightToLeft` for `.ar` and `.leftToRight` for `.en`.
- Text fallback path works without voice services.
- Large/RTL visual behavior belongs to UX/UI tests, but ViewModel must expose the required language/direction state.

---

## Assumptions And Defaults

- `files/dev-spec.md` is the generated dev-spec artifact; `files/build-order/dev.md` remains a later build-order output.
- `API-endpoints.md` overrides older PRD/UX ordering conflicts, especially verify-before-license.
- Backend accepts `language: "ar"` or `language: "en"` on `/api/journey/start`.
- Voice persona is local only unless the backend later documents a request field.
- MVP persists one local saved plan as JSON. No accounts, cloud sync, migrations, document upload, OCR, appointment booking, or real AI calling.
- Banking remains in the output chain because `API-endpoints.md` includes `/api/banking`; if time pressure later requires skipping it, update the API spec before changing Swift.
- No third-party SPM packages are used for MVP.
