# Prompt 04: ViewModel Skeleton

## Context

Create the `JourneyViewModel` skeleton that defines the public contract consumed by the UX/UI build order. This ViewModel owns all view-facing journey, input, card, output, feedback, presentation, and saved-plan state. It orchestrates services later, but this prompt only creates the observable interface and empty action methods.

This prompt must not implement backend calls, speech handling, persistence, sharing behavior, UI views, UI components, theme files, visual styling, animations, or gesture code.

## File Location

Create:

- `Irshad/ViewModels/JourneyViewModel.swift`

## Dependencies

- Imports: `Foundation`, `Observation`, `SwiftUI`
- Depends on: all models, all service protocols
- Later consumers: UX/UI views, app entry, ViewModel implementation prompt, tests

## Requirements

- Define exactly one ViewModel for MVP: `JourneyViewModel`.
- Mark the class `@MainActor` and `@Observable`.
- Use `@ObservationIgnored` for services, tasks, encoders, decoders, and pending operation internals.
- Provide all observable properties required by the UX/UI build order.
- Provide all public methods required by the UX/UI build order.
- Method bodies may be empty or contain TODO placeholders in this prompt.
- Use protocol-typed dependencies and initializer injection.
- Do not split into child ViewModels.

## Interface

`Irshad/ViewModels/JourneyViewModel.swift`

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

    let appTitle: String
    var currentLanguage: AppLanguage
    var layoutDirection: LayoutDirection { get }
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
    var canSubmitCurrentInput: Bool { get }
    var inputErrorMessage: String?

    var activeSession: JourneySession?
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

    var confidence: Double? { get }
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

    init(
        apiService: JourneyAPIServiceProtocol,
        speechRecognitionService: SpeechRecognitionServiceProtocol,
        speechSynthesisService: SpeechSynthesisServiceProtocol,
        localPlanStore: LocalPlanStoreProtocol,
        shareService: ShareServiceProtocol,
        analyticsService: AnalyticsServiceProtocol
    )
}
```

Create the internal pending operation model in the same file:

```swift
enum PendingOperation: Equatable, Sendable {
    case startText(String)
    case nextCard(cardID: String)
    case analyze
    case verify
    case license
    case banking
    case finalPlan
    case loadSavedPlan
    case saveFinalPlan
    case shareFinalPlan
}
```

Public methods:

```swift
extension JourneyViewModel {
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
}
```

## Implementation Notes

- Default property values should represent a clean launch state: Arabic language, right-to-left layout, empty journey, no active session, no card, no outputs, no busy state.
- `layoutDirection` returns `.rightToLeft` when `currentLanguage == .ar`; otherwise `.leftToRight`.
- `phases` is initialized to `JourneyPhase.visibleOrder`.
- `canSubmitCurrentInput` is true when either `editableTranscript` or `textFallbackValue` contains non-whitespace text and no backend operation is active.
- `confidence` returns the latest available confidence in this priority order: final plan, analysis, license or verification metadata if exposed later.
- Selection/toggle/checklist card methods update local draft state only in this skeleton.
- `openURL(_:)` and `callPhoneNumber(_:)` may be left as TODOs here; behavior is implemented later.
- Do not create any SwiftUI `View` types in this prompt.

## ViewModel-To-View Contract

Views read the observable properties listed in this prompt directly from one shared `JourneyViewModel` instance. Views call only the public methods listed in this prompt. Views should not call services directly, construct backend requests directly, infer legal or banking rules, fabricate phone numbers, or choose backend routes.

Use `@Bindable` in views where the UX/UI build order edits these ViewModel-owned values directly:

- `editableTranscript`
- `textFallbackValue`
- text or number card draft values
- presentation flags such as `isTextEntryExpanded` and `isProfileExpanded`
- correction values if exposed by the UX/UI layer

## Acceptance Criteria

- [ ] `JourneyViewModel` is `@MainActor @Observable`.
- [ ] Service dependencies, task state, and pending operation state are marked `@ObservationIgnored`.
- [ ] Every observable property listed in this prompt exists.
- [ ] Every public method listed in this prompt exists.
- [ ] The initializer accepts protocol-typed services.
- [ ] Default state represents an empty Arabic-first app launch.
- [ ] No backend orchestration, speech engine implementation, persistence, sharing behavior, SwiftUI view, component, theme, styling, animation, or gesture logic is implemented by this prompt.
