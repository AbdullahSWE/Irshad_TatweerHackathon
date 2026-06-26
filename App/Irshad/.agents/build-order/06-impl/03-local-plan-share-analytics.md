# Prompt 06.03: Local Plan, Share, And Analytics Services Implementation

## Context

Implement the local persistence, share/copy payload, and lightweight analytics services for Irshad. The MVP stores one latest final plan locally, prepares user-safe share/copy text, and records analytics events locally/no-op without adding external SDKs. Shared content must preserve trust labels so the user never loses which facts are verified, estimated, unverified, missing, unknown, or guidance-only.

This prompt implements local services only. Do not implement ViewModel orchestration, UI presentation, SwiftUI views, reusable components, theme files, visual styling, animations, gestures, backend calls, or speech services.

## File Location

Update:

- `Irshad/Services/LocalPlanStore.swift`
- `Irshad/Services/ShareService.swift`
- `Irshad/Services/AnalyticsService.swift`
- `Irshad/Utilities/DateFormatting.swift`
- `Irshad/Utilities/ClipboardClient.swift` only if needed by ViewModel copy behavior

## Dependencies

- Imports: `Foundation`, `UIKit` for clipboard utility only
- Depends on: `FinalPlan`, `JourneySession`, `NextStepChecklistItem`, `SavedPlanSummary`, `SharePayload`, `TrustFactBundle`, `PlanStoreError`, `ShareError`, `AnalyticsEvent`
- Later consumers: `JourneyViewModel`, saved-plan tests, sharing tests

## Requirements

- Persist exactly one latest saved plan for MVP.
- Use application support directory by default for JSON persistence.
- Create the storage directory if it does not exist.
- Encode and decode with injected `JSONEncoder` and `JSONDecoder`.
- Keep a final plan visible to the ViewModel if saving fails by throwing an error instead of mutating UI state inside the service.
- Share/copy text must include trust labels and unverified/guidance caveats.
- Analytics must not require network, user identity, or an external SDK.

## Interface

Keep local store protocol unchanged:

```swift
protocol LocalPlanStoreProtocol: Sendable {
    func loadSavedPlan() async throws -> SavedPlanSummary?
    func save(plan: FinalPlan, session: JourneySession, checklist: [NextStepChecklistItem]) async throws -> SavedPlanSummary
    func deleteSavedPlan() async throws
}
```

`save(plan:session:checklist:)` creates a `SavedPlanSummary` with:

- stable `id` generated locally
- `title` from `plan.nextAction`, session goal, or a generic saved plan title
- `sessionId` from `session.sessionId`
- `savedAt` as current date
- the full `FinalPlan`
- the full `JourneySession`
- checklist items

Keep share service protocol unchanged:

```swift
protocol ShareServiceProtocol: Sendable {
    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload
    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String
}
```

Share/copy text must include these sections when data exists:

```text
Irshad Plan
Next action
Roadmap
Estimated total cost
Estimated timeline
Verified facts
Estimated facts
Unverified facts
Missing or unknown facts
Guidance note
```

Keep analytics protocol unchanged:

```swift
protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent) async
}
```

## Implementation Notes

- Prefer an `actor LocalPlanStore` to serialize file access.
- Store JSON at a deterministic filename such as `latest-plan.json` inside application support.
- Use `.atomic` writes when possible.
- `deleteSavedPlan()` should be idempotent if no file exists.
- `ShareService` only prepares `SharePayload`; it must not present `UIActivityViewController`.
- `ClipboardClient` may wrap `UIPasteboard.general.string`, but actual copy calls are ViewModel-owned.
- `AnalyticsService` can log locally in debug builds. `NoopAnalyticsService` should do nothing.
- Do not fabricate facts to make share text look complete.

## Acceptance Criteria

- [ ] Saving a final plan writes one JSON payload locally and returns a `SavedPlanSummary`.
- [ ] Loading returns nil when no saved plan exists.
- [ ] Loading returns the saved summary after a successful save.
- [ ] Deleting removes the saved summary and is safe when no file exists.
- [ ] Save failures throw `PlanStoreError.writeFailed` or equivalent and do not mutate UI state.
- [ ] Share payload generation includes roadmap, next action, cost/timeline when present.
- [ ] Share/copy text includes verified, estimated, unverified, missing/unknown, and guidance labels when facts exist.
- [ ] Analytics can track events without network or external SDKs.
- [ ] No ViewModel behavior, UI presentation, view, component, theme, style, animation, gesture, backend, or speech logic is added by this prompt.
