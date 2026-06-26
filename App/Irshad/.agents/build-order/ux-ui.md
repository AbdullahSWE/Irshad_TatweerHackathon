# UX/UI Build-Order Prompts: Irshad

## Overview

Irshad is an Arabic-first, voice-first iOS app that guides rural entrepreneurs through a backend-driven business launch journey. This UX/UI build order creates the SwiftUI visual layer: theme tokens, reusable components, voice input surfaces, dynamic backend card rendering, profile/recommendation/result cards, the main journey shell, saved plan presentation, resilient states, and final polish.

This build order covers Theme, Views, Components, interactions, visual states, overlays, accessibility presentation, Arabic right-to-left layout behavior, and responsive iPhone portrait layout. Models, Services, backend calls, speech recognition implementation, text-to-speech implementation, and ViewModel internals are handled by the later dev build order.

## Scope

This UX/UI build order is allowed to define the ViewModel surface it expects, because the dev build order comes later. It must not implement Models, Services, backend logic, endpoint orchestration, speech engine logic, persistence, or recommendation rules.

The UI must remain a thin renderer of backend state. It may call ViewModel methods, but it must not hardcode license, bank, authority, fee, eligibility, or phase-decision logic.

## Prerequisites From Dev Build Order

The dev build order is intentionally not required before generating this document. Before implementing these UI prompts in SwiftUI, the later dev build order should provide:

- Xcode project scaffold with `Irshad/Theme`, `Irshad/Components`, `Irshad/Views`, and feature subfolders.
- View-facing data types for journey phases, voice state, dynamic cards, profile sections, trust status, recommendations, verification, checklist items, and final plan content.
- One observable `JourneyViewModel` matching the expected interface below.
- Method signatures for speech, API, correction, share/copy, and saved-plan actions.

## Expected ViewModel Interface

The prompts below assume one observable view model named `JourneyViewModel`. The later dev build order should create matching view-facing state and method signatures.

### ViewModel Reads

- Journey identity and status: `appTitle`, `currentLanguage`, `layoutDirection`, `sessionId`, `journeyStatus`, `currentPhase`, `phases`, `completedPhases`, `progress`, `isBackendBusy`, `lastUpdatedAt`.
- Current prompt and response: `currentPrompt`, `framingMessage`, `currentAssistantMessage`, `currentCard`, `cardAnswerDraft`, `cardValidationMessage`.
- Voice and text input: `voiceState`, `transcriptState`, `liveTranscript`, `editableTranscript`, `transcriptConfidence`, `textFallbackValue`, `canSubmitCurrentInput`, `inputErrorMessage`.
- Dynamic cards and profile: `renderableCards`, `profileSections`, `missingFields`, `unknownFields`, `correctionTarget`.
- Output stages: `analysisSummary`, `licenseRecommendation`, `bankingRecommendations`, `verificationSummary`, `nextStepChecklist`, `finalPlan`, `savedPlanSummary`.
- Trust and feedback: `confidence`, `verifiedFacts`, `estimatedFacts`, `unverifiedFacts`, `guidanceDisclaimer`, `toast`, `banner`, `recoverableError`, `unsupportedCard`.
- Presentation: `isTextEntryExpanded`, `isProfileExpanded`, `expandedRecommendationIDs`, `showSavedPlan`, `showShareSheet`, `sharePayload`, `copiedItemID`, `reduceMotionPreferred`.

### ViewModel Calls

- Journey lifecycle: `startJourneyWithVoice()`, `startJourneyWithText(_:)`, `submitCurrentAnswer()`, `submitCardAnswer(_:)`, `retryCurrentStep()`, `cancelCurrentOperation()`.
- Voice and transcript: `beginListening()`, `stopListening()`, `retryListening()`, `acceptTranscript()`, `updateTranscript(_:)`, `updateTextFallback(_:)`.
- Card actions: `selectSingleOption(cardID:optionID:)`, `toggleMultiOption(cardID:optionID:)`, `updateCardText(cardID:value:)`, `updateCardNumber(cardID:value:)`, `setToggleAnswer(cardID:value:)`, `toggleChecklistItem(cardID:itemID:)`, `expandCard(_:)`, `collapseCard(_:)`.
- Correction and profile: `beginCorrection(fieldID:)`, `submitCorrection(_:)`, `cancelCorrection()`.
- Output actions: `expandRecommendation(_:)`, `savePreferredBank(_:)`, `openURL(_:)`, `callPhoneNumber(_:)`, `copyText(_:)`, `markNextStepDone(_:)`.
- Final plan and sharing: `openSavedPlan()`, `shareFinalPlan()`, `copyFinalPlanSummary()`, `continueWithAssistant()`, `dismissToast()`, `dismissBanner()`.

### Assumed View-Facing Types

The UI prompts can reference these names as view-facing contracts without implementing them:

- `JourneyPhase`: `goal`, `business`, `founder`, `details`, `budget`, `documents`, `analysis`, `license`, `banking`, `verify`, `nextSteps`, `plan`.
- `JourneyStatus`: `empty`, `preparing`, `collecting`, `processing`, `gateOpen`, `showingResults`, `complete`, `partial`, `failed`.
- `VoiceState`: `idle`, `listening`, `processing`, `transcriptReady`, `failed`.
- `TrustStatus`: `verified`, `estimated`, `unverified`, `missing`, `unknown`, `guidanceOnly`.
- `DynamicCardType`: `single_select`, `multi_select`, `text`, `number`, `toggle`, `checklist`, `info`, `summary`, `recommendation`, `roadmap`, `unsupported`.

## Route Boundaries

The UI may only surface journey actions through ViewModel calls that map to the existing PRD routes:

- `POST /api/journey/start`
- `POST /api/journey/next`
- `POST /api/analyze`
- `POST /api/verify`
- `POST /api/license`
- `POST /api/banking`
- `POST /api/plan/final`

Do not introduce or imply any other route. Do not show fake phone progress, fake authority calls, invented fees, invented phone numbers, or guaranteed approvals.

## Cross-Pipeline Sequence

1. UX/UI: Generate this build order and use it as the visual contract.
2. Dev: Create scaffold, view-facing models, services, `JourneyViewModel`, speech wrappers, and app entry point matching the expected interface.
3. UX/UI: Build `IrshadTheme` and reusable visual components.
4. UX/UI: Build welcome, journey shell, dynamic cards, profile, outputs, saved plan, and states.
5. Dev: Implement API, speech, persistence, share payload, and ViewModel behavior.
6. UX/UI + Dev: Wire interactions, run demo path, verify route boundaries, accessibility, RTL, Dynamic Type, dark mode, and reduced motion.

## Build Sequence

0. Theme System - design tokens from `files/styles.md`.
1. Shared Visual Components - ambient background, icon buttons, status pills, waveform, processing orb, toast, and banner primitives.
2. Welcome And Voice Input - start screen, microphone hub, transcript confirmation, and text fallback.
3. Phase Stepper And Journey Header - 12-phase progress and current journey framing.
4. Dynamic Card Renderer - backend-driven cards for question, info, recommendation, and roadmap content.
5. Profile And Trust Cards - auto-filled business profile, trust badges, confidence, missing, and unknown field states.
6. Result Cards - analysis, license, banking, verification, next-step checklist, and final roadmap modules.
7. Main Journey Shell - full-screen composition for current prompt, cards, profile, input dock, and output-stage content.
8. Saved Plan And Sharing - saved plan surface, final roadmap presentation, share, copy, and continue actions.
9. Resilient States - empty, loading, partial, error, retry, unsupported-card, and permission fallback states.
10. Polish And Accessibility - Arabic RTL, Dynamic Type, dark mode, reduced motion, accessibility labels, and iPhone portrait refinement.

---

## Prompt 0: Theme System

### Context

Create the shared SwiftUI design token system for Irshad. The app should feel calm, trustworthy, bright, Arabic-first, and voice-controlled. The visual direction is the modern blue voice-flow language from `files/styles.md`: luminous white surfaces, soft blue ambient light, a central microphone hub, quiet progress, structured cards, and no chat transcript layout.

### File Location

Create:

- `Irshad/Theme/IrshadTheme.swift`
- `Irshad/Theme/IrshadTheme+Colors.swift`
- `Irshad/Theme/IrshadTheme+Typography.swift`
- `Irshad/Theme/IrshadTheme+Layout.swift`
- `Irshad/Theme/IrshadTheme+Animation.swift`

### ViewModel Binding

None. This prompt defines static theme tokens only.

### Theme References

This prompt defines `IrshadTheme.*`. Later prompts must reference these tokens instead of repeating raw colors, spacing, corner radii, or animation values.

### Requirements

- Define `enum IrshadTheme` as a no-instance namespace.
- Use nested enums named `Colors`, `Typography`, `Layout`, `Shadows`, and `Animations`.
- Use SwiftUI-native types: `Color`, `Font`, `CGFloat`, `Animation`, `Gradient`, and shape styles where useful.
- Include light mode and dark mode compatible tokens using semantic colors where possible.
- Keep blue as the identity color, with indigo and cyan as supporting accents only.
- Include success/status accents as localized tokens for status cards, not as dominant brand colors.
- Keep all card radii at 24 pt and small controls at 16 pt unless a token clearly says otherwise.

### Token Requirements

- Colors:
  - `primaryAccent` -> `.blue`
  - `supportingAccent` -> `.indigo`
  - `softHighlight` -> `.cyan`
  - `success` -> `.green`
  - `warning` -> `.orange`
  - `secondaryStatus` -> `.purple`
  - `canvas` -> `Color(.systemBackground)`
  - `surface` -> `Color(.systemBackground)`
  - `surfaceElevated` -> `Color(.secondarySystemBackground)`
  - `surfaceTint` -> `.blue.opacity(0.06)`
  - `indigoTint` -> `.indigo.opacity(0.05)`
  - `primaryText` -> `.primary`
  - `secondaryText` -> `.secondary`
  - `tertiaryText` -> `.tertiary`
  - `separator` -> `Color(.separator).opacity(0.45)`
  - `progressTrack` -> `.tertiary.opacity(0.35)`
  - `verifiedTint`, `estimatedTint`, `unverifiedTint`, `missingTint`, and `unknownTint` for trust badges.
- Gradients and styles:
  - `appBackgroundGradient` matching white to faint blue to white.
  - `activeVoiceRadialGradient` matching white, blue opacity, and indigo opacity.
  - `analysisGlowGradient` from blue to indigo opacity.
  - Dark-mode alternatives that preserve blue highlights without washing out text.
- Typography:
  - `largeTitle` for 34-40 pt bold main task framing.
  - `sectionTitle` for 24-28 pt semibold analysis or stage headers.
  - `stepIndicator` for 18-22 pt semibold phase labels.
  - `primaryBody` for 17-19 pt regular prompt and guidance copy.
  - `cardTitle` for 17-20 pt semibold card headings.
  - `secondaryLabel` for 14-16 pt helper copy.
  - `statusMicrocopy` for 13-15 pt medium pills and live-state labels.
  - Use SF Pro through SwiftUI system fonts; do not load custom fonts.
- Layout:
  - `baseUnit` = 4
  - `spacingTight` = 8
  - `spacingStandard` = 12
  - `spacingComfortable` = 16
  - `spacingSection` = 24
  - `spacingMajor` = 32
  - `outerMarginCompact` = 20
  - `outerMarginRegular` = 24
  - `controlRadius` = 16
  - `cardRadius` = 24
  - `largeRadius` = 32
  - `minimumTapTarget` = 44
  - `voiceButtonSize` = 96
  - `voiceButtonExpandedSize` = 128
  - `bottomDockHeight` = 132
  - `phaseDotSize` = 10
  - `phaseStepperHeight` = 46
  - `statusPillHeight` = 30
  - `waveformHeight` = 52
  - `cardHorizontalPadding` = 16
  - `cardVerticalPadding` = 18
  - `bannerPadding` = 16
- Shadows:
  - `ambientBlueShadow`
  - `floatingControlShadow`
  - `cardShadow`
  - `voiceHaloShadow`
  - Define as reusable View extensions or values usable by components.
- Animations:
  - `listeningPulse` slow breathing scale and opacity.
  - `waveformResponse` continuous low-amplitude waveform movement.
  - `progressTransition` easeInOut around 0.25-0.35 seconds.
  - `orbMotion` subtle floating or rotating state.
  - `cardReveal` gentle opacity and position transition.
  - `buttonFeedback` soft spring with low bounce.
  - Provide reduced-motion alternatives or static names for callers.

### States

- Theme supports light mode as the primary visual direction.
- Theme supports dark mode with near-black/deep neutral surfaces and preserved blue highlights.
- Theme supports reduced motion by exposing non-pulsing animation fallbacks.

### Interactions

None. This prompt defines shared visual constants only.

### Constraints

- Do not implement app screens in this prompt.
- Do not use raw color values in later prompts if a token exists.
- Do not use chat-bubble styling tokens; the app is not a message thread.
- Do not hardcode Arabic or English strings in theme files.

---

## Prompt 1: Shared Visual Components

### Context

Build reusable visual primitives used across Irshad: the luminous background, floating icon controls, trust/status pills, live waveform, processing orb, toast, and informational banner. These components provide the visual language for listening, thinking, progressing, and showing trust without adding business logic.

### File Location

Create:

- `Irshad/Components/IrshadBackgroundView.swift`
- `Irshad/Components/FloatingIconButton.swift`
- `Irshad/Components/StatusPill.swift`
- `Irshad/Components/TrustBadge.swift`
- `Irshad/Components/VoiceWaveformView.swift`
- `Irshad/Components/ProcessingOrbView.swift`
- `Irshad/Components/IrshadToastView.swift`
- `Irshad/Components/InfoBannerView.swift`

### ViewModel Binding

- ViewModel: None directly.
- Reads: all state is passed through init parameters such as title, icon, status, isActive, waveformLevel, message, action label, and dismiss action.
- Calls: only closures passed into each component, such as `onTap`, `onDismiss`, `onCopy`, or `onRetry`.
- Bindings: none.

### Theme References

- Colors: `IrshadTheme.Colors.canvas`, `surface`, `surfaceElevated`, `surfaceTint`, `primaryAccent`, `supportingAccent`, `softHighlight`, `primaryText`, `secondaryText`, `tertiaryText`, `separator`, status tint tokens.
- Typography: `IrshadTheme.Typography.statusMicrocopy`, `secondaryLabel`, `cardTitle`.
- Layout: `IrshadTheme.Layout.minimumTapTarget`, `controlRadius`, `cardRadius`, `statusPillHeight`, `waveformHeight`, spacing tokens, outer margins.
- Animations: `IrshadTheme.Animations.listeningPulse`, `waveformResponse`, `orbMotion`, `buttonFeedback`, `cardReveal`.

### Requirements

- `IrshadBackgroundView` renders the bright full-screen gradient and subtle soft blue ambient layers using SwiftUI shapes/gradients, not image textures.
- `FloatingIconButton` is a 44 pt minimum icon button with a white/elevated surface, subtle blue edge, faint shadow, and visible disabled state.
- `StatusPill` shows compact status labels with optional icon and spinner slot; it must not rely on color alone.
- `TrustBadge` maps `TrustStatus` to icon, label, tint, and accessibility value for verified, estimated, unverified, missing, unknown, and guidance-only.
- `VoiceWaveformView` renders animated vertical bars or capsules with blue/cyan highlights; it accepts levels or produces visual placeholder motion when active.
- `ProcessingOrbView` renders a calm central orb with blue symbol, subtle orbit/anchor details, and reduced-motion fallback.
- `IrshadToastView` shows a short floating feedback message with optional action.
- `InfoBannerView` shows one leading icon, concise message, optional action, and optional dismiss control.

### States

- Default: visible, calm, and low-contrast enough to support the main task.
- Active/listening: blue/cyan motion and emphasis are visible.
- Processing: orb or spinner style communicates thinking without implying a call or official submission.
- Disabled: controls remain readable and have clear accessibility labels.
- Error/warning/success: status pills and banners pair icon plus label.
- Reduced motion: waveform/orb/pulse use static highlights or low-frequency fades.

### Interactions

- Icon buttons call injected actions only.
- Toast action calls injected closure and can be dismissed by injected dismiss closure.
- Banner action calls injected closure, such as retry, open, copy, or dismiss.
- No component starts a backend request or speech session by itself.

### Constraints

- Do not implement business-specific cards here.
- Do not include chat bubbles or conversation timeline styling.
- Do not add hardcoded legal, banking, authority, or route behavior.
- All user-facing icon-only controls must include accessibility labels and hints.

---

## Prompt 2: Welcome And Voice Input

### Context

Build the first-use and ongoing input surfaces for Irshad. The experience should make one primary action obvious: speak the business idea or answer. Text is always available as a fallback, but voice remains visually primary. Spoken input must become an editable transcript before submission.

### File Location

Create:

- `Irshad/Views/WelcomeView.swift`
- `Irshad/Components/VoiceControlHub.swift`
- `Irshad/Components/TranscriptConfirmationView.swift`
- `Irshad/Components/TextFallbackInputView.swift`
- `Irshad/Components/InputDockView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `appTitle`, `currentLanguage`, `journeyStatus`, `currentPrompt`, `voiceState`, `transcriptState`, `liveTranscript`, `editableTranscript`, `transcriptConfidence`, `textFallbackValue`, `canSubmitCurrentInput`, `inputErrorMessage`, `isTextEntryExpanded`.
- Calls: `beginListening()`, `stopListening()`, `retryListening()`, `acceptTranscript()`, `updateTranscript(_:)`, `updateTextFallback(_:)`, `startJourneyWithText(_:)`, `submitCurrentAnswer()`, `retryCurrentStep()`.
- Bindings: editable transcript text and text fallback value should be wired through ViewModel update calls or bindings exposed by the dev build order.

### Theme References

- Colors: `IrshadTheme.Colors.appBackgroundGradient`, `activeVoiceRadialGradient`, `primaryAccent`, `supportingAccent`, `softHighlight`, `surface`, `surfaceTint`, `primaryText`, `secondaryText`, `warning`.
- Typography: `largeTitle`, `primaryBody`, `secondaryLabel`, `statusMicrocopy`.
- Layout: `voiceButtonSize`, `voiceButtonExpandedSize`, `bottomDockHeight`, `outerMarginCompact`, `spacingStandard`, `spacingComfortable`, `spacingMajor`, `minimumTapTarget`, `controlRadius`, `cardRadius`.
- Animations: `listeningPulse`, `waveformResponse`, `buttonFeedback`, `cardReveal`.

### Requirements

- `WelcomeView` shows the Irshad identity, one short Arabic-first promise sourced from local UI copy or ViewModel, one large microphone control, text fallback, and 2-3 example business prompts if supplied by the ViewModel.
- `VoiceControlHub` shows a circular microphone button with white core, blue icon, soft rings, and clear states: idle, listening, processing, transcript ready, and failed.
- `TranscriptConfirmationView` shows editable transcript text, confidence or low-confidence cue if supplied, confirm/send, retry, and cancel/edit affordances.
- `TextFallbackInputView` is reachable from every question state and uses the same submit flow as confirmed transcript.
- `InputDockView` anchors voice and text controls near the bottom while preserving safe area and keyboard behavior.
- All input copy should be short, respectful, and Arabic-first where app strings are provided.

### States

- Empty: microphone idle, short current prompt or welcome promise, text fallback visible but secondary.
- Loading/preparing: voice/session capabilities are preparing with no blank screen.
- Listening: waveform visible, microphone hub active, stop/cancel available.
- Processing: transcript or backend submission is in progress, input is protected from accidental double submission.
- Transcript ready: editable transcript plus confirm/send action.
- Partial: low confidence transcript encourages edit, retry, or type.
- Error: voice failed or backend failed; preserve entered text/transcript and offer retry or text fallback.

### Interactions

- Tap microphone idle: call `beginListening()`.
- Tap stop while listening: call `stopListening()`.
- Tap retry transcript: call `retryListening()`.
- Edit transcript: call `updateTranscript(_:)`.
- Confirm transcript: call `acceptTranscript()` or `submitCurrentAnswer()` according to the ViewModel contract.
- Type fallback text: call `updateTextFallback(_:)`.
- Submit typed answer: call `startJourneyWithText(_:)` on welcome or `submitCurrentAnswer()` during the journey.

### Constraints

- Do not implement speech recognition, AVAudioSession, AVSpeechSynthesizer, or API calls.
- Do not clear current prompt or prior session context on voice errors.
- Do not make text fallback visually dominant over the microphone.
- Do not present spoken content as chat bubbles or a transcript timeline.

---

## Prompt 3: Phase Stepper And Journey Header

### Context

Build the compact progress system that makes the backend-driven journey feel structured. Irshad has 12 visible phases: Goal, Business, Founder, Details, Budget, Documents, Analysis, License, Banking, Verify, Next Steps, and Plan. The UI does not decide phases; it displays the phase state supplied by `JourneyViewModel`.

### File Location

Create:

- `Irshad/Components/JourneyHeaderView.swift`
- `Irshad/Components/PhaseStepperView.swift`
- `Irshad/Components/PhaseProgressBar.swift`
- `Irshad/Components/CurrentPromptView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `currentPhase`, `phases`, `completedPhases`, `progress`, `journeyStatus`, `currentPrompt`, `framingMessage`, `currentAssistantMessage`, `isBackendBusy`.
- Calls: none for normal display. Optional injected closures may support correction or retry if the ViewModel exposes them.
- Bindings: none.

### Theme References

- Colors: `IrshadTheme.Colors.primaryAccent`, `progressTrack`, `surface`, `surfaceTint`, `primaryText`, `secondaryText`, `tertiaryText`, `separator`, `verifiedTint`.
- Typography: `stepIndicator`, `primaryBody`, `secondaryLabel`, `statusMicrocopy`.
- Layout: `phaseStepperHeight`, `phaseDotSize`, `outerMarginCompact`, `spacingTight`, `spacingStandard`, `spacingSection`, `minimumTapTarget`.
- Animations: `progressTransition`, `cardReveal`, `buttonFeedback`.

### Requirements

- `JourneyHeaderView` contains the app/session framing, optional compact status pill, and phase progress.
- `PhaseStepperView` shows all 12 phases in compact form and adapts labels for small widths.
- Completed phases show a check or completed visual state.
- Current phase is emphasized with blue fill, larger dot, or active label treatment.
- Future phases are dimmed/pending/locked without looking like errors.
- `PhaseProgressBar` can display fine-grained backend progress when `progress.filled` and `progress.required` exist.
- `CurrentPromptView` shows the latest question or assistant framing as centered current-state messaging, not a chat message.

### States

- Empty: no session yet; show minimal welcome framing or hide phase details if ViewModel marks journey empty.
- Collecting: current collection phase active with completed prior phases.
- Backend busy: keep current phase and prompt visible while showing subtle progress.
- Gate open/output stage: transition from collection to analysis/verification/license/banking/plan phases.
- Complete: plan phase completed and share/copy actions can be shown elsewhere.
- Error: keep previous phase visible with an error pill, not a reset state.

### Interactions

- Phase elements are display-only for MVP unless the ViewModel provides a correction/review action.
- Header retry action, if present, calls `retryCurrentStep()`.
- Header cancel action, if present, calls `cancelCurrentOperation()`.

### Constraints

- Do not let users manually choose backend phases.
- Do not infer phase completion locally from UI controls.
- Do not hide the current phase during backend loading.
- Long labels must not clip at larger Dynamic Type sizes; use shortened phase labels and horizontal scrolling or adaptive wrapping.

---

## Prompt 4: Dynamic Card Renderer

### Context

Build the generic renderer for backend-driven dynamic cards. Cards are how Irshad asks questions, shows summaries, provides recommendations, and displays roadmaps. The renderer must use backend labels, options, titles, subtitles, phase, and slot metadata without embedding business rules.

### File Location

Create:

- `Irshad/Views/DynamicCardRendererView.swift`
- `Irshad/Components/Cards/QuestionCardContainer.swift`
- `Irshad/Components/Cards/SingleSelectCardView.swift`
- `Irshad/Components/Cards/MultiSelectCardView.swift`
- `Irshad/Components/Cards/TextAnswerCardView.swift`
- `Irshad/Components/Cards/NumberAnswerCardView.swift`
- `Irshad/Components/Cards/ToggleAnswerCardView.swift`
- `Irshad/Components/Cards/ChecklistCardView.swift`
- `Irshad/Components/Cards/InfoCardView.swift`
- `Irshad/Components/Cards/SummaryCardView.swift`
- `Irshad/Components/Cards/RecommendationCardView.swift`
- `Irshad/Components/Cards/RoadmapCardView.swift`
- `Irshad/Components/Cards/UnsupportedCardView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `currentCard`, `renderableCards`, `cardAnswerDraft`, `cardValidationMessage`, `isBackendBusy`, `unsupportedCard`, `expandedRecommendationIDs`, `copiedItemID`.
- Calls: `selectSingleOption(cardID:optionID:)`, `toggleMultiOption(cardID:optionID:)`, `updateCardText(cardID:value:)`, `updateCardNumber(cardID:value:)`, `setToggleAnswer(cardID:value:)`, `toggleChecklistItem(cardID:itemID:)`, `submitCardAnswer(_:)`, `expandCard(_:)`, `collapseCard(_:)`, `copyText(_:)`, `retryCurrentStep()`.
- Bindings: answer draft values can be updated through ViewModel calls or bindings exposed by dev.

### Theme References

- Colors: `IrshadTheme.Colors.surface`, `surfaceElevated`, `surfaceTint`, `primaryAccent`, `supportingAccent`, `softHighlight`, `primaryText`, `secondaryText`, `tertiaryText`, `separator`, trust/status tint tokens.
- Typography: `cardTitle`, `primaryBody`, `secondaryLabel`, `statusMicrocopy`.
- Layout: `cardRadius`, `cardHorizontalPadding`, `cardVerticalPadding`, `spacingTight`, `spacingStandard`, `spacingComfortable`, `minimumTapTarget`, `controlRadius`.
- Animations: `cardReveal`, `buttonFeedback`, `progressTransition`.

### Requirements

- `DynamicCardRendererView` switches on backend `DynamicCardType` and delegates to a concrete card view.
- `QuestionCardContainer` provides shared title, subtitle, phase/status, validation message, and confirm area for question cards.
- `SingleSelectCardView` supports exactly one selected option and can either auto-submit or expose confirm based on card metadata or ViewModel state.
- `MultiSelectCardView` supports multiple selected options and requires explicit confirmation.
- `TextAnswerCardView` supports freeform answers with a visible submit action.
- `NumberAnswerCardView` supports numeric entry, AED formatting where relevant, quick ranges if supplied, and unknown/not-sure choices if supplied.
- `ToggleAnswerCardView` shows two-state or yes/no choices with the selected state plainly marked.
- `ChecklistCardView` renders available, missing, unknown, and completed states with icons plus labels.
- `InfoCardView` and `SummaryCardView` are review/output cards with no answer requirement unless action metadata is supplied.
- `RecommendationCardView` supports summary-first display, expand/collapse details, trust badges, pros/cons, requirements, and optional save/copy/open actions.
- `RoadmapCardView` renders ordered steps, immediate next action, confidence, unverified items, and copy/share hooks if supplied.
- `UnsupportedCardView` shows a recoverable fallback and does not crash when the backend returns an unknown type.

### States

- Empty: no card yet; show placeholder only when ViewModel indicates a card is expected.
- Loading: card skeleton or soft progress treatment after backend wait threshold.
- Success: render backend card type and content.
- Partial: hide missing optional fields while preserving required prompt clarity.
- Validation: show specific validation or missing-answer message from ViewModel.
- Unsupported: show fallback title, explanation, and retry/text fallback action.
- Error: keep current session visible and offer retry.

### Interactions

- Select single option: call `selectSingleOption(cardID:optionID:)`.
- Toggle multi option: call `toggleMultiOption(cardID:optionID:)`.
- Edit text: call `updateCardText(cardID:value:)`.
- Edit number: call `updateCardNumber(cardID:value:)`.
- Toggle answer: call `setToggleAnswer(cardID:value:)`.
- Checklist row tap: call `toggleChecklistItem(cardID:itemID:)` only for locally markable checklist items.
- Confirm answer: call `submitCardAnswer(_:)`.
- Expand recommendation: call `expandCard(_:)` or `expandRecommendation(_:)` if the card represents recommendation output.
- Copy question, requirement, or summary: call `copyText(_:)`.

### Constraints

- Do not hardcode journey questions, license names, bank names, fees, authority details, or eligibility rules.
- Do not create custom endpoint behavior in card views.
- Do not treat backend `info`, `summary`, `recommendation`, or `roadmap` cards as user questions unless metadata says they need an action.
- Do not use chat bubbles, stacked message threads, or conversation timelines.

---

## Prompt 5: Profile And Trust Cards

### Context

Build the visible business profile and trust surfaces. As the user speaks and answers cards, Irshad should show profile details filling themselves: activity, founder, location, budget, documents, sales channel, and missing/unknown fields. Trust must be legible through verified, estimated, unverified, missing, unknown, and guidance-only labels.

### File Location

Create:

- `Irshad/Components/Profile/BusinessProfileSummaryView.swift`
- `Irshad/Components/Profile/ProfileSectionCardView.swift`
- `Irshad/Components/Profile/ProfileFieldRow.swift`
- `Irshad/Components/Profile/MissingInfoCardView.swift`
- `Irshad/Components/Profile/ConfidenceMeterView.swift`
- `Irshad/Components/Profile/TrustLegendView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `profileSections`, `missingFields`, `unknownFields`, `confidence`, `verifiedFacts`, `estimatedFacts`, `unverifiedFacts`, `guidanceDisclaimer`, `isProfileExpanded`, `correctionTarget`.
- Calls: `beginCorrection(fieldID:)`, `submitCorrection(_:)`, `cancelCorrection()`, `copyText(_:)`, `dismissBanner()`.
- Bindings: expanded/collapsed state may be read from ViewModel or managed locally for pure presentation where allowed.

### Theme References

- Colors: `IrshadTheme.Colors.surface`, `surfaceTint`, `primaryAccent`, `primaryText`, `secondaryText`, `tertiaryText`, `separator`, `verifiedTint`, `estimatedTint`, `unverifiedTint`, `missingTint`, `unknownTint`, `warning`.
- Typography: `cardTitle`, `primaryBody`, `secondaryLabel`, `statusMicrocopy`.
- Layout: `cardRadius`, `cardHorizontalPadding`, `cardVerticalPadding`, `spacingTight`, `spacingStandard`, `spacingComfortable`, `minimumTapTarget`.
- Animations: `cardReveal`, `progressTransition`, `buttonFeedback`.

### Requirements

- `BusinessProfileSummaryView` groups profile details by activity, founder, business details, budget, and documents.
- Each `ProfileSectionCardView` shows completion/progress state and collapses optional details on small screens.
- `ProfileFieldRow` shows label, value, trust/missing/unknown state, and correction affordance if the field is editable.
- `MissingInfoCardView` makes missing and unknown information approachable; it should never imply user failure.
- `ConfidenceMeterView` displays backend confidence as a readable visual plus label, not as a bare number only.
- `TrustLegendView` explains verified, estimated, unverified, missing, unknown, and guidance-only labels concisely when needed.

### States

- Empty: profile sections exist but show no filled values yet.
- Loading: field update animation or pending marker after answer submission.
- Success: auto-filled fields are clearly saved/reviewable.
- Partial: some fields filled, missing/unknown values explicitly labeled.
- Error: a field update or sync failed; show retry without discarding visible values.
- Correction: selected field shows correction entry while surrounding context remains visible.

### Interactions

- Tap correction on a field: call `beginCorrection(fieldID:)`.
- Submit correction: call `submitCorrection(_:)`.
- Cancel correction: call `cancelCorrection()`.
- Copy a profile summary or field value: call `copyText(_:)`.
- Expand/collapse section: use local UI state or ViewModel state as defined by dev.

### Constraints

- Do not infer missing/unknown/verified status locally.
- Do not invent profile values when backend data is absent.
- Do not display raw backend session JSON.
- Keep profile cards secondary to the current question on small screens.

---

## Prompt 6: Result Cards

### Context

Build structured output cards for the mature journey stages: analysis, license recommendation, banking recommendations, authority verification, next-step checklist, and final roadmap. These cards should make recommendations scannable while preserving uncertainty and trust labels.

### File Location

Create:

- `Irshad/Components/Results/AnalysisSummaryCardView.swift`
- `Irshad/Components/Results/LicenseRecommendationCardView.swift`
- `Irshad/Components/Results/BankRecommendationListView.swift`
- `Irshad/Components/Results/BankRecommendationCardView.swift`
- `Irshad/Components/Results/VerificationCardView.swift`
- `Irshad/Components/Results/NextStepChecklistView.swift`
- `Irshad/Components/Results/FinalRoadmapView.swift`
- `Irshad/Components/Results/OutputStageContainerView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `analysisSummary`, `licenseRecommendation`, `bankingRecommendations`, `verificationSummary`, `nextStepChecklist`, `finalPlan`, `confidence`, `verifiedFacts`, `estimatedFacts`, `unverifiedFacts`, `expandedRecommendationIDs`, `copiedItemID`, `isBackendBusy`, `recoverableError`.
- Calls: `expandRecommendation(_:)`, `savePreferredBank(_:)`, `openURL(_:)`, `callPhoneNumber(_:)`, `copyText(_:)`, `markNextStepDone(_:)`, `shareFinalPlan()`, `copyFinalPlanSummary()`, `retryCurrentStep()`, `continueWithAssistant()`.
- Bindings: checklist done state may be local through ViewModel methods; do not store authoritative backend state in views.

### Theme References

- Colors: `IrshadTheme.Colors.surface`, `surfaceElevated`, `surfaceTint`, `primaryAccent`, `supportingAccent`, `softHighlight`, `primaryText`, `secondaryText`, `tertiaryText`, `separator`, `success`, `warning`, trust/status tint tokens.
- Typography: `sectionTitle`, `cardTitle`, `primaryBody`, `secondaryLabel`, `statusMicrocopy`.
- Layout: `cardRadius`, `cardHorizontalPadding`, `cardVerticalPadding`, `spacingTight`, `spacingStandard`, `spacingComfortable`, `spacingSection`, `minimumTapTarget`, `controlRadius`.
- Animations: `cardReveal`, `progressTransition`, `buttonFeedback`.

### Requirements

- `AnalysisSummaryCardView` shows matched activity, setup cost estimate, candidate license names if present, confidence, and unverified items.
- `LicenseRecommendationCardView` shows best license first, issuer, why recommended, estimated or verified cost, timeline, approvals, pros/cons, alternatives, and verification status.
- `BankRecommendationListView` shows simple comparison before details; each `BankRecommendationCardView` includes suitability, minimum balance if known, required documents, next action, and source/status when supplied.
- `VerificationCardView` separates verified facts from unverified requirements. It shows authority name, official contact URL or phone only when supplied by backend, exact question to ask, and copy/open/call actions.
- `NextStepChecklistView` shows ordered practical steps and lets the user mark items done locally when supported.
- `FinalRoadmapView` groups final plan into business summary, recommended license, estimated cost, documents, approvals, banks, timeline, immediate next action, unverified items, and confidence.
- `OutputStageContainerView` provides a consistent surface for analysis, verification, license, banking, and plan stage loading/success/partial/error displays.

### States

- Empty: output stage is locked or pending until required backend state exists.
- Loading: show active analysis, verification, bank matching, or roadmap generation state while preserving previous content.
- Success: show complete output with confidence and trust labels.
- Partial: output exists but includes missing or unverified items; labels stay visible.
- Error: output generation failed; session context remains visible with retry.
- Expanded: detailed rationale, pros/cons, requirements, and alternatives are visible.

### Interactions

- Expand recommendation: call `expandRecommendation(_:)`.
- Save preferred bank: call `savePreferredBank(_:)`.
- Open website/contact page/map: call `openURL(_:)`.
- Call phone number: call `callPhoneNumber(_:)`, using only backend-provided phone values.
- Copy authority question or summary: call `copyText(_:)`.
- Mark checklist item done: call `markNextStepDone(_:)`.
- Share final plan: call `shareFinalPlan()`.
- Copy final summary: call `copyFinalPlanSummary()`.
- Continue with assistant: call `continueWithAssistant()`.

### Constraints

- Do not create official submission, autonomous phone call, appointment booking, or guaranteed approval UI.
- Do not invent contact details, fees, requirements, bank minimums, sources, or timelines.
- Do not hide unverified labels in collapsed states.
- Do not combine verification and license logic in the UI; display what the ViewModel supplies.

---

## Prompt 7: Main Journey Shell

### Context

Build the primary screen that composes Irshad's continuous journey: background, header, current prompt, dynamic card, profile summary, output cards, and anchored input dock. The screen should feel like one guided voice experience, not separate forms or a chat app.

### File Location

Create:

- `Irshad/Views/JourneyView.swift`
- `Irshad/Views/JourneyContentView.swift`
- `Irshad/Views/JourneyOutputStageView.swift`
- `Irshad/Views/JourneyInputOverlayView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: all state needed by composed child views: `journeyStatus`, `currentPhase`, `phases`, `progress`, `currentPrompt`, `currentAssistantMessage`, `currentCard`, `renderableCards`, `profileSections`, `analysisSummary`, `licenseRecommendation`, `bankingRecommendations`, `verificationSummary`, `nextStepChecklist`, `finalPlan`, `voiceState`, `transcriptState`, `isBackendBusy`, `toast`, `banner`, `recoverableError`.
- Calls: child view actions forwarded to the ViewModel methods listed in the Expected ViewModel Interface.
- Bindings: sheet, toast, banner, text, and transcript presentation state should be owned by ViewModel where cross-screen coordination is needed.

### Theme References

- Colors: all core background, surface, text, status, trust, separator, and accent tokens from `IrshadTheme.Colors`.
- Typography: `largeTitle`, `sectionTitle`, `stepIndicator`, `primaryBody`, `cardTitle`, `secondaryLabel`, `statusMicrocopy`.
- Layout: all spacing, margins, card, dock, phase, voice, touch-target, and safe-area tokens from `IrshadTheme.Layout`.
- Animations: `cardReveal`, `progressTransition`, `listeningPulse`, `waveformResponse`, `buttonFeedback`, reduced-motion fallbacks.

### Requirements

- Root view uses `IrshadBackgroundView` as a full-screen decorative layer.
- Header remains visible enough for orientation during backend loading and output stages.
- Current prompt and active card stay near the center of user attention.
- Profile summary appears as progressive context, not as a dense form; on small screens it may collapse behind a section control.
- Output stage cards appear when `JourneyViewModel` supplies analysis, license, banking, verification, next steps, or final plan state.
- Input dock remains reachable near the lower safe area while respecting keyboard, Dynamic Type, and VoiceOver focus.
- Toasts and banners appear above the input dock without covering primary actions.
- Screen supports iPhone-first portrait layout and reasonable landscape fallback without custom desktop-style layouts.

### States

- Welcome/empty: show `WelcomeView` or embedded welcome content.
- Collecting: show header, prompt, dynamic card, profile summary, and input dock.
- Processing: keep current content visible and show processing state after wait threshold.
- Output stage: show output container and relevant result card while input remains available if the assistant can continue.
- Partial: show missing/unknown/unverified information without blocking all progress.
- Complete: final roadmap, share/copy, saved plan, and continue actions are visible.
- Failed: error banner, preserved content, retry, and fallback input are visible.

### Interactions

- Child components call ViewModel actions for voice, text, card submission, corrections, result actions, retry, share, copy, and continue.
- Scrolling should preserve the active prompt/card and keep input reachable.
- Keyboard appearance should not hide submit actions.
- VoiceOver focus after new backend card should move to the current prompt/card title.

### Constraints

- Do not create navigation that lets users jump to arbitrary backend phases.
- Do not create a tab-based app shell for MVP unless dev later requires saved plans as a separate root.
- Do not implement route calls or ViewModel internals.
- Do not show raw API payloads or backend debug details.

---

## Prompt 8: Saved Plan And Sharing

### Context

Build the saved/final plan presentation and sharing surfaces. The final plan should create momentum: one immediate next action first, then grouped details. Shared or copied content must preserve uncertainty labels.

### File Location

Create:

- `Irshad/Views/SavedPlanView.swift`
- `Irshad/Components/SavedPlanCardView.swift`
- `Irshad/Components/PlanShareToolbar.swift`
- `Irshad/Components/FinalPlanSummaryPanel.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `savedPlanSummary`, `finalPlan`, `confidence`, `unverifiedFacts`, `guidanceDisclaimer`, `sharePayload`, `showShareSheet`, `copiedItemID`, `isBackendBusy`, `recoverableError`.
- Calls: `openSavedPlan()`, `shareFinalPlan()`, `copyFinalPlanSummary()`, `continueWithAssistant()`, `copyText(_:)`, `retryCurrentStep()`.
- Bindings: share sheet presentation if ViewModel owns it.

### Theme References

- Colors: `IrshadTheme.Colors.surface`, `surfaceTint`, `primaryAccent`, `supportingAccent`, `primaryText`, `secondaryText`, `tertiaryText`, `separator`, trust/status tint tokens.
- Typography: `sectionTitle`, `cardTitle`, `primaryBody`, `secondaryLabel`, `statusMicrocopy`.
- Layout: `cardRadius`, `outerMarginCompact`, `spacingStandard`, `spacingComfortable`, `spacingSection`, `minimumTapTarget`, `controlRadius`.
- Animations: `cardReveal`, `buttonFeedback`, `progressTransition`.

### Requirements

- `SavedPlanCardView` shows business title, short summary, progress/checklist status, immediate next action, confidence/trust status, continue, and share/copy actions.
- `SavedPlanView` opens into the final roadmap and keeps grouped plan sections readable.
- `PlanShareToolbar` exposes primary share and secondary copy summary actions.
- `FinalPlanSummaryPanel` displays the business summary, license, estimated cost, documents, approvals, banks, timeline, immediate next action, unverified items, and guidance disclaimer.
- Shared/copy affordances must be disabled or show clear fallback when final plan content is unavailable.

### States

- Empty: saved plan unavailable or final plan not generated.
- Loading: final plan or share payload is preparing.
- Success: saved plan and final roadmap are readable and actionable.
- Partial: saved plan exists with unverified items or missing values; labels are visible.
- Error: share/copy or plan generation failed; keep final plan data visible when available.

### Interactions

- Tap saved plan: call `openSavedPlan()`.
- Tap share: call `shareFinalPlan()`.
- Tap copy summary: call `copyFinalPlanSummary()`.
- Tap continue: call `continueWithAssistant()`.
- Tap retry on failure: call `retryCurrentStep()`.

### Constraints

- Do not generate PDF/text export in views; use ViewModel-supplied `sharePayload`.
- Do not remove uncertainty labels from shared or copied summaries.
- Do not imply official approval, submission, or bank acceptance.
- Do not add user-account or cloud sync UI for MVP.

---

## Prompt 9: Resilient States

### Context

Build reusable empty, loading, partial, error, retry, unsupported-card, permission, and offline-style presentation states. Irshad must never feel blank or broken while backend or speech work is happening. Prior answers and visible session context should remain visible whenever possible.

### File Location

Create:

- `Irshad/Components/States/IrshadEmptyStateView.swift`
- `Irshad/Components/States/IrshadLoadingStateView.swift`
- `Irshad/Components/States/IrshadErrorStateView.swift`
- `Irshad/Components/States/PartialDataStateView.swift`
- `Irshad/Components/States/VoicePermissionFallbackView.swift`
- `Irshad/Components/States/UnsupportedContentStateView.swift`
- `Irshad/Components/States/CardSkeletonView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `journeyStatus`, `voiceState`, `transcriptState`, `isBackendBusy`, `recoverableError`, `inputErrorMessage`, `unsupportedCard`, `missingFields`, `unknownFields`, `banner`, `toast`, `currentPrompt`, `currentCard`.
- Calls: `retryCurrentStep()`, `retryListening()`, `updateTextFallback(_:)`, `submitCurrentAnswer()`, `dismissToast()`, `dismissBanner()`, `copyText(_:)`.
- Bindings: text fallback value where a state offers typed recovery.

### Theme References

- Colors: `IrshadTheme.Colors.surface`, `surfaceTint`, `primaryAccent`, `primaryText`, `secondaryText`, `tertiaryText`, `separator`, `warning`, trust/status tint tokens.
- Typography: `sectionTitle`, `cardTitle`, `primaryBody`, `secondaryLabel`, `statusMicrocopy`.
- Layout: `cardRadius`, `outerMarginCompact`, `spacingStandard`, `spacingComfortable`, `spacingSection`, `minimumTapTarget`, `controlRadius`.
- Animations: `cardReveal`, `orbMotion`, `progressTransition`, `buttonFeedback`, reduced-motion alternatives.

### Requirements

- Empty state explains the next available action in one short message and offers voice/text start if no session exists.
- Loading state shows active progress after the backend wait threshold and preserves current content behind or above the indicator.
- Error state names the failed point plainly, offers retry, and keeps fallback text entry where helpful.
- Partial data state shows what is usable and what remains missing/unknown.
- Voice permission fallback keeps the journey usable through text.
- Unsupported content state handles unknown card types and malformed optional data without crashing.
- Skeletons should match final card dimensions closely enough to avoid large layout jumps.

### States

- App preparing: session or voice setup is in progress.
- Backend processing: current answer submitted and next card/output is pending.
- Voice failed: user can retry voice or type.
- Server failed: previous answers remain visible and retry is available.
- Unsupported card: fallback message and retry/text answer are available.
- Partial data: missing/unknown/unverified items are explicit but non-blocking where backend allows.

### Interactions

- Retry failed backend step: call `retryCurrentStep()`.
- Retry voice: call `retryListening()`.
- Type fallback: call `updateTextFallback(_:)`.
- Submit fallback: call `submitCurrentAnswer()`.
- Dismiss toast/banner: call `dismissToast()` or `dismissBanner()`.
- Copy support/debug-friendly visible error text only if ViewModel supplies user-safe copy.

### Constraints

- Do not reset or clear the session from an error view.
- Do not expose stack traces, raw JSON, or internal backend route names to users.
- Do not invent fallback legal/banking facts when backend output is missing.
- Do not create dead-end error screens.

---

## Prompt 10: Polish And Accessibility

### Context

Perform the final UI pass for Arabic-first usage, right-to-left layout, Dynamic Type, dark mode, reduced motion, VoiceOver, touch targets, and iPhone portrait ergonomics. This prompt should refine existing views and components without adding new business logic.

### File Location

Create:

- `Irshad/Theme/IrshadTheme+Accessibility.swift`

Update:

- `Irshad/Views/JourneyView.swift`
- `Irshad/Views/WelcomeView.swift`
- `Irshad/Views/DynamicCardRendererView.swift`
- `Irshad/Views/SavedPlanView.swift`
- `Irshad/Components/VoiceControlHub.swift`
- `Irshad/Components/InputDockView.swift`
- `Irshad/Components/JourneyHeaderView.swift`
- `Irshad/Components/PhaseStepperView.swift`
- `Irshad/Components/Profile/BusinessProfileSummaryView.swift`
- `Irshad/Components/Results/FinalRoadmapView.swift`

### ViewModel Binding

- ViewModel: `JourneyViewModel`
- Reads: `currentLanguage`, `layoutDirection`, `reduceMotionPreferred`, `journeyStatus`, `currentPhase`, `currentPrompt`, `voiceState`, `isBackendBusy`, `confidence`, `unverifiedFacts`.
- Calls: no new ViewModel behavior. Existing calls from earlier prompts remain unchanged.
- Bindings: none beyond existing presentation state.

### Theme References

- Colors: all light/dark semantic and trust/status tokens.
- Typography: all typography tokens with Dynamic Type behavior.
- Layout: all spacing, touch target, safe-area, phase, card, and dock tokens.
- Animations: all motion tokens plus reduced-motion fallbacks.

### Requirements

- Apply RTL support to primary Arabic journeys using environment layout direction and mirrored icon/layout decisions where appropriate.
- Ensure all text scales with Dynamic Type without clipping card content, buttons, phase labels, or input controls.
- Keep touch targets at least 44x44 pt.
- Provide accessibility labels/hints/values for microphone, stop, retry, send, text fallback, phase progress, trust badges, confidence meter, copy/share, call, website, and checklist actions.
- Preserve visible labels for unfamiliar icon-only controls through tooltips/help labels where supported.
- Make reduced motion replace pulsing/orbiting/waveform animation with static highlights or low-frequency fades.
- Dark mode uses deep neutral surfaces with blue highlights, readable text, and clear card separation.
- iPhone portrait layout keeps primary voice/input controls reachable and avoids overlap with keyboard, safe area, toast, and banners.
- Verify long phase labels use shortened labels or adaptive layout.
- Verify final roadmap and recommendation cards remain readable at large text sizes.

### States

- Arabic RTL: all major journeys read naturally and controls mirror where expected.
- English/development fallback: layout remains usable and does not depend on Arabic-only text.
- Dynamic Type large sizes: cards expand vertically; primary actions remain reachable.
- VoiceOver: focus order follows header, current prompt/card, answer controls, input dock, profile/output secondary content.
- Reduced motion: state remains understandable through color, icon, label, and static emphasis.
- Dark mode: blue glows do not reduce legibility.

### Interactions

- VoiceOver activation of microphone, submit, retry, copy, call, website, share, and checklist controls should trigger the same ViewModel actions as taps.
- Hardware keyboard return in text fallback can submit only when `canSubmitCurrentInput` is true.
- Escape/cancel affordance, if implemented by dev, should call existing cancel/retry/collapse methods and not abandon the session.

### Constraints

- Do not add new routes, models, services, or ViewModel logic.
- Do not use viewport-width font scaling; rely on SwiftUI Dynamic Type.
- Do not let banners, toasts, keyboard, or bottom dock cover required action buttons.
- Do not remove trust labels in compact, dark, RTL, or shared-plan states.
- Do not change the voice-first, non-chat visual direction.

---

## Integration With Dev Build Order

The later dev build order should create the data types and `JourneyViewModel` contract assumed above before UI implementation is wired to real services. The root app entry should inject one `JourneyViewModel` into `JourneyView` or create it at the screen boundary using `@State`.

### ViewModel Reads By UI Area

- Welcome/input: voice state, transcript, text fallback, can-submit, prompt, and input errors.
- Header/progress: current phase, all phases, completed phases, fine-grained progress, and backend busy state.
- Dynamic cards: current/renderable cards, answer draft, validation, expanded card IDs, copied item ID, and unsupported content state.
- Profile/trust: profile sections, missing/unknown fields, confidence, verified/estimated/unverified facts, correction target, and disclaimer.
- Results: analysis, license, banking, verification, next steps, final plan, expanded recommendation IDs, share/copy state, and recoverable errors.
- Shell/states: journey status, toast, banner, backend busy, recoverable error, and presentation flags.

### ViewModel Calls By UI Area

- Welcome/input: start journey, begin/stop/retry listening, accept/update transcript, update text, submit answer.
- Dynamic cards: select/toggle/update/confirm answers, expand/collapse cards, copy text, retry.
- Profile/trust: begin/submit/cancel correction and copy user-safe summary text.
- Results: expand recommendation, save bank, open URL, call backend-provided phone, copy question/summary, mark checklist, share/copy final plan, continue.
- Shell/states: retry current step, cancel operation, dismiss toast/banner.

### Acceptance Checklist

- `files/build-order/ux-ui.md` is non-empty and follows the command output structure.
- Theme prompt extracts colors, typography, spacing, radii, shadows, and motion from `files/styles.md`.
- Every prompt includes file location, ViewModel binding, theme references, requirements, states, interactions, and constraints.
- Every prompt is UI-only and avoids Models, Services, backend logic, recommendation logic, and ViewModel implementation.
- UI route boundaries mention only `/api/journey/start`, `/api/journey/next`, `/api/analyze`, `/api/verify`, `/api/license`, `/api/banking`, and `/api/plan/final`.
- Arabic-first, voice-first, non-chat direction is preserved.
- Trust labels for verified, estimated, unverified, missing, unknown, and guidance-only remain visible across cards and final plan.
- Dynamic cards are backend-rendered and support fallback for unsupported card types.
- Final plan share/copy preserves uncertainty labels.
