# Prompt 08: Integration And Verification

## Context

Run final integration only after the dev prompts and the UX/UI build order have both been implemented. This prompt verifies that the non-UI Swift implementation, the UX/UI views, the backend contract, and the shared `JourneyViewModel` interface work together without crossing ownership boundaries.

This is a joint verification prompt. It may fix wiring mismatches, compile failures, and contract drift, but it must not introduce new product scope, new backend routes, new legal/banking rules, or UI concepts that bypass the build orders.

## File Location

Inspect and update only as needed:

- `Irshad/App/`
- `Irshad/Models/`
- `Irshad/Services/`
- `Irshad/ViewModels/`
- `Irshad/Navigation/`
- `Irshad/Utilities/`
- UX/UI-owned `Irshad/Theme/`, `Irshad/Views/`, and `Irshad/Components/` only for wiring fixes required by the shared contract
- `IrshadTests/`

## Dependencies

- Depends on: completed dev foundation, completed UX/UI build order implementation, backend or mocked backend responses
- Tools: Xcode build/test, simulator or device, local backend at `http://localhost:3001/` when available

## Requirements

- Verify the root app creates one shared `JourneyViewModel` and passes it to the UX/UI root view.
- Verify the UI reads only ViewModel properties and calls only ViewModel methods.
- Verify services are not called directly from views.
- Verify the app references only seven backend routes:
  - `/api/journey/start`
  - `/api/journey/next`
  - `/api/analyze`
  - `/api/verify`
  - `/api/license`
  - `/api/banking`
  - `/api/plan/final`
- Verify output network order:

```text
start -> next* -> analyze -> verify -> license -> banking -> plan
```

- Verify `verify` runs before `license`.
- Verify `nextSteps` is local checklist/final-plan presentation state, not a backend route.
- Verify the UI does not invent license, bank, authority, fee, approval, phone, or eligibility data.

## Test Cases

### Build And Contract

- [ ] App target compiles after UX/UI root view exists.
- [ ] Test target compiles.
- [ ] `JourneyViewModel` exposes every read required by the UX/UI build order.
- [ ] `JourneyViewModel` exposes every call required by the UX/UI build order.
- [ ] Views do not instantiate services or construct API requests.

### Endpoint And Decoding

- [ ] `AppConfig.baseURL` is `http://localhost:3001/`.
- [ ] URL joining works for `"/api/analyze"` and `"api/analyze"`.
- [ ] All seven endpoints resolve correctly.
- [ ] No route outside the seven allowed paths appears in the Swift code.
- [ ] Decode `/api/journey/start` sample with framing, activity, and card.
- [ ] Decode `/api/journey/next` collecting response with current stage, progress, and card.
- [ ] Decode stage-advanced response.
- [ ] Decode `gate_open` response.
- [ ] Decode `ready` compatibility response safely.
- [ ] Decode card options from string arrays and object arrays.
- [ ] Decode unknown card type as unsupported.
- [ ] Decode `filledSlots` with strings, numbers, booleans, arrays, objects, and null.
- [ ] Decode verify `verified` response.
- [ ] Decode verify `not_found` response with authority, phone or contact URL, and message.
- [ ] Decode license, banking, and final plan responses with optional fields missing.

### ViewModel State

- [ ] Start from text creates session, posts current language, stores first card, and enters collecting state.
- [ ] Voice permission denial keeps text fallback usable.
- [ ] Card submit appends history and sends the full session.
- [ ] Current card is preserved while `/api/journey/next` is in flight.
- [ ] Collecting response updates card, progress, phase, and profile.
- [ ] Gate-open triggers analyze, verify, license, banking, final plan in order.
- [ ] Verification not found proceeds to license with unverified labels.
- [ ] API failure during banking preserves previous outputs and retries banking only.
- [ ] Cancel stops busy state without clearing session/card/output data.
- [ ] Final plan success creates checklist, saves locally, and marks complete.

### Persistence And Sharing

- [ ] Save, load, and delete latest final plan.
- [ ] Saved plan opens offline if already saved.
- [ ] Save failure keeps final plan visible and shows recoverable warning.
- [ ] Share unavailable keeps final plan visible.
- [ ] Copy/share text includes trust labels and guidance caveats.

### Trust And Safety

- [ ] Phone links are created only from backend-provided phone values.
- [ ] Empty or fabricated phone values are rejected.
- [ ] Official URLs are opened only when supplied by backend or generated locally for safe app actions.
- [ ] Unknown, missing, unverified, estimated, and guidance-only facts are not displayed as verified.
- [ ] The app does not fabricate fees, banks, licenses, authorities, approvals, timelines, or phone numbers.

### UX/UI Boundary

- [ ] Theme, views, components, layout, animations, gestures, overlays, and visual states remain in UX/UI-owned files.
- [ ] Models, services, ViewModel logic, endpoint orchestration, persistence, and share payload generation remain in dev-owned files.
- [ ] `@Bindable` usage is limited to ViewModel-owned editable state intended for two-way UI editing.
- [ ] RTL and Dynamic Type visual behavior are handled in UX/UI, while `currentLanguage` and `layoutDirection` come from the ViewModel.

## Implementation Notes

- Prefer contract fixes over broad refactors.
- If the backend is unavailable, use protocol-based mock services and documented sample payloads for integration tests.
- If a mismatch exists between UX/UI and dev contracts, update the smallest side necessary while preserving the explicit `JourneyViewModel` interface.
- Do not change route order to match visual phase order. The visible phase list can show license, banking, verify, but network order remains analyze, verify, license, banking, plan.
- Do not add PDF export, accounts, cloud sync, OCR, appointment booking, autonomous calls, or chat beyond the existing `continueWithAssistant()` handoff.

## Acceptance Criteria

- [ ] The app builds after both pipelines are implemented.
- [ ] The test suite covers endpoint, decoding, ViewModel state, persistence, sharing, and trust/safety scenarios listed above.
- [ ] A mocked happy-path journey reaches final plan.
- [ ] A mocked verification-not-found journey still reaches license, banking, and final plan with unverified labels.
- [ ] A mocked banking failure preserves earlier outputs and supports retry.
- [ ] Saved final plan can be opened without backend access.
- [ ] No new routes or client-owned business rules are introduced during integration.
