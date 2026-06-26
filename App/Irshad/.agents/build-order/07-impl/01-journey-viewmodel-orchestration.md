# Prompt 07.01: Journey ViewModel Orchestration Implementation

## Context

Implement `JourneyViewModel` behavior for Irshad. The ViewModel is the single app-facing coordinator: it manages voice/text input state, card drafts, session history, backend orchestration, output stages, retry/cancel behavior, saved plan state, share/copy payloads, trust facts, and user-safe feedback. Swift remains a thin client and must not own legal, banking, authority, fee, phone, or journey-stage business rules.

This prompt implements ViewModel logic only. Do not create SwiftUI views, reusable UI components, theme files, visual styling, animations, gesture handlers, or new backend routes.

## File Location

Update:

- `Irshad/ViewModels/JourneyViewModel.swift`
- `Irshad/Navigation/JourneyRouter.swift`
- `Irshad/Utilities/ClipboardClient.swift`
- model/service helpers only when needed to support the ViewModel contract

## Dependencies

- Imports: `Foundation`, `Observation`, `SwiftUI`, `UIKit` only for system handoff helpers if required
- Depends on: implemented services, all models, `PendingOperation`, `JourneyRouter`, `ClipboardClient`
- Later consumers: UX/UI build order and integration tests

## Requirements

- Keep `JourneyViewModel` `@MainActor @Observable`.
- Mutate observable state only on the main actor.
- Allow only one active backend operation at a time.
- Preserve current session/card/output state when requests fail, timeout, or are cancelled.
- Implement retry through `pendingOperation`.
- Implement cancel by cancelling `activeTask` and clearing busy state without deleting current data.
- Keep the network order exactly:

```text
start -> next* -> analyze -> verify -> license -> banking -> plan
```

- Do not call `/api/license` before `/api/verify`, even if verification returns `not_found`.
- Do not skip `/api/banking` unless the API contract is changed elsewhere.
- Do not introduce any route beyond the seven allowed endpoints.

## Behavior

### Start Journey

`startJourneyWithText(_:)`:

- Trims whitespace and validates non-empty input.
- Creates a UUID session id when needed.
- Sets busy state and records `pendingOperation = .startText(text)`.
- Sends `StartJourneyRequest(sessionId:goalText:language:)`.
- Stores returned session if provided; otherwise creates/updates a local `JourneySession` echo from the response.
- Stores `framingMessage`, `currentCard`, `progress`, `currentPhase`, and `renderableCards`.
- Sets `journeyStatus = .collecting`.
- Clears input errors on success.

`startJourneyWithVoice()`:

- Delegates to `beginListening()`.
- When transcript is accepted through `acceptTranscript()`, calls `startJourneyWithText(editableTranscript)`.

### Speech And Text

- `beginListening()` requests authorization, starts speech recognition, updates `voiceState`, `transcriptState`, `liveTranscript`, `editableTranscript`, and `transcriptConfidence`.
- Permission denied sets a user-safe input error and keeps text fallback active.
- `stopListening()` stops the service and preserves the best transcript.
- `retryListening()` clears speech error state and begins listening again.
- `updateTranscript(_:)` and `updateTextFallback(_:)` update local editable text.
- `submitCurrentAnswer()` starts a new journey if no active session exists; otherwise submits the active card answer.

### Card Drafts

- Selection/toggle/text/number/checklist methods update `cardAnswerDraft`.
- `submitCardAnswer(_:)` validates the draft for the requested card id.
- On valid submit, append a local `JourneyHistoryItem` to the active session.
- Update `filledSlots` only as a local display/session echo for the slot sent back to the backend.
- Send `NextJourneyRequest(sessionId:session:)`.
- Preserve the current card until a successful response arrives.
- If response status is `collecting`, update card/progress/stage/phase and continue.
- If response status is `gate_open`, set `journeyStatus = .gateOpen` and run output orchestration.
- Treat `ready` as gate-open only when no card is present and progress indicates collection is complete; otherwise surface a recoverable backend-state error.

### Output Chain

When the gate opens, run:

```text
/api/analyze
/api/verify
/api/license
/api/banking
/api/plan/final
```

Implementation details:

- Set `currentPhase = .analysis` before analyze.
- Store `analysisSummary` after analyze succeeds.
- Build `verifyTarget` from `analysisSummary.candidateLicenses.first` plus `" fee + requirements 2026"`.
- If no candidate exists, use `"best candidate license fee + requirements 2026"`.
- Set `currentPhase = .verify` before verify.
- Store `verificationSummary` whether status is verified or not found.
- Set `currentPhase = .license` before license.
- Store `licenseRecommendation`.
- Set `currentPhase = .banking` before banking.
- Store `bankingRecommendations`.
- Set `currentPhase = .plan` before final plan.
- Store `finalPlan`, derive `nextStepChecklist`, save the plan locally, update `savedPlanSummary`, and set `journeyStatus = .complete`.
- Mark completed phases as each endpoint succeeds.
- If one output endpoint fails, keep all prior outputs visible and set retry to the failed endpoint only.

### Profile, Trust, And Safety

- Derive `profileSections` from `activeSession.filledSlots` and known trust status arrays.
- Derive `missingFields` and `unknownFields` from fields marked `.missing` and `.unknown`.
- Aggregate `verifiedFacts`, `estimatedFacts`, and `unverifiedFacts` from backend output summaries without inventing facts.
- `guidanceDisclaimer` must make clear that output is guidance and unverified items need confirmation.
- `callPhoneNumber(_:)` only acts on backend-provided phone strings through `JourneyRouter`.
- `openURL(_:)` only opens backend-provided or locally generated safe URLs.
- `copyText(_:)` uses `ClipboardClient` and sets `copiedItemID` or toast feedback.

### Saved Plan And Sharing

- `openSavedPlan()` loads saved plan through `LocalPlanStore`, updates `savedPlanSummary`, `finalPlan`, `activeSession`, checklist, and `showSavedPlan`.
- `shareFinalPlan()` uses `ShareService` to create `sharePayload`, then sets `showShareSheet = true`.
- `copyFinalPlanSummary()` uses `ShareService.makeCopySummary`, copies it, and preserves trust labels.
- Share unavailable keeps the final plan visible and surfaces a recoverable error or toast.

## Public Methods

Keep this full public method surface and implement each method:

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

## Implementation Notes

- Prefer small private helper methods for operation wrapping, error mapping, phase mapping, checklist derivation, trust aggregation, and profile derivation.
- Use `Task {}` only from main-actor methods and store it in `activeTask`.
- Do not clear existing successful outputs when a later output endpoint fails.
- Do not make the UI wait for speech synthesis.
- Use `AnalyticsServiceProtocol.track(_:)` as best effort only.
- Keep all user-facing errors generic and safe; do not expose raw backend bodies unless already user-safe.

## Acceptance Criteria

- [ ] Start from text creates a session id, posts Arabic or English language, stores first card, and enters `.collecting`.
- [ ] Speech permission denied keeps text fallback active and does not mark the journey failed.
- [ ] Submitting a card appends history, sends the full session to `/api/journey/next`, and preserves the current card until success.
- [ ] Collecting responses update card, phase, progress, and profile state.
- [ ] Gate-open runs output calls in exact order: analyze, verify, license, banking, final plan.
- [ ] Verification `not_found` still proceeds to license and marks facts unverified where appropriate.
- [ ] Banking failure preserves analysis, verification, and license outputs and allows retrying banking only.
- [ ] Final plan success derives checklist, saves locally, and marks the journey complete.
- [ ] Cancel stops busy state without clearing session/card/output data.
- [ ] Retry repeats only the last failed pending operation.
- [ ] Share/copy payloads preserve trust labels.
- [ ] Phone calls and URLs are based only on backend-provided values.
- [ ] No new backend route, SwiftUI view, UI component, theme, visual style, animation, gesture, legal rule, banking rule, authority value, fee value, or fabricated phone number is added.
