# Irshad Agent Guide

Use this file as reusable guidance for Codex work in the Irshad iOS repo. Keep changes aligned with the product docs in:

- `/Users/pacos/Desktop/925Apps/0xDesigner/925designer/files/PRD.md`
- `/Users/pacos/Desktop/925Apps/0xDesigner/925designer/files/API-endpoints.md`

## Product Summary

Irshad is an Arabic AI business concierge for rural UAE entrepreneurs. The MVP helps a user speak a business idea in Arabic, answer a guided journey, and receive license, verification, banking, and launch-plan cards.

The demo target is one polished end-to-end journey, especially a rural Abu Dhabi business such as camel milk, dairy, farm, food, dates, honey, tailoring, retail, or desert tourism.

## Repo Layout

- `IrshadApp.swift` - SwiftUI app entry point.
- `ContentView.swift` - current root view.
- `Assets.xcassets/` - app assets and colors.
- `AppIcon.icon/` - icon source assets.
- `../Irshad.xcodeproj` - Xcode project for target `Irshad`.

This repo is the Swift iOS client. The Next.js backend is separate. Do not add backend journey logic to Swift.

## Run, Build, Test

Open in Xcode:

```sh
open ../Irshad.xcodeproj
```

Build from terminal:

```sh
xcodebuild -project ../Irshad.xcodeproj -scheme Irshad -destination 'platform=iOS Simulator,name=iPhone 17' build
```

If the simulator name is unavailable, list devices and choose an installed iPhone simulator:

```sh
xcrun simctl list devices available
```

There are no tests yet. When tests are added, prefer focused tests for session/state handling, card decoding, and API client behavior.

## Core Architecture Rules

The iOS app is a thin client. It should:

- Render whatever the server sends.
- Send session updates back to the server.
- Show progress, cards, loading states, voice/text input, and share/export UI.
- Keep `baseURL` unchanged unless explicitly asked.

The iOS app must not:

- Decide journey order.
- Hardcode license, banking, cost, authority, or eligibility logic.
- Invent fees, phone numbers, requirements, approvals, or government facts.
- Simulate autonomous phone calls.
- Bypass the backend for final recommendations.

## Journey Contract

The server owns a fixed stage backbone with adaptive questions inside stages:

```text
goal -> business -> founder -> details -> budget -> documents
-> analyze -> verify -> license -> banking -> plan
```

Client route sequence:

```text
POST /api/journey/start
POST /api/journey/next  repeated until status == gate_open
POST /api/analyze
POST /api/verify
POST /api/license
POST /api/banking
POST /api/plan/final
```

The collection loop must handle:

- `status: "collecting"` with a renderable card.
- `stageJustCompleted` when present.
- `status: "gate_open"` to begin output stages.
- A question cap enforced server-side; Swift should not assume unlimited loops.

## Session Model

Treat the session as the single source of truth. It generally includes:

- `sessionId`
- `goalText`
- `currentStage`
- `filledSlots`
- `history`

Append user answers to session/history and send the full updated session to `/api/journey/next`. Avoid scattering duplicated source-of-truth state across views.

## Card Rendering

Build generic renderers around the server card schema:

```json
{
  "cardId": "string",
  "kind": "question | confirmation | info",
  "type": "single_select | multi_select | text | toggle | none",
  "title": "string",
  "subtitle": "string",
  "options": ["..."],
  "slot": "string",
  "stage": "string"
}
```

Swift should switch on `kind` and `type`, not on hardcoded business phases. New server cards should render without an app update when they fit the schema.

## UI / UX Principles

- Conversation first: the user should feel they are talking to a helpful Arabic assistant, not filling forms.
- Initial screen: concise title, concise subtitle, one primary microphone action, secondary text input.
- Arabic is primary. English fallback is acceptable for development and testing.
- Support voice input with Apple Speech and text-to-speech with `AVSpeechSynthesizer`.
- Include a clear audio wave or listening indicator when recording.
- Keep the screen alive during backend work with polished loading/progress states.
- Show a visible backbone stepper/progress indicator for Business, Founder, Details, Budget, Documents, then output stages.
- Cards should visibly fill themselves as answers arrive.
- Completed phases show a checkmark; active phase is highlighted; future phases are dimmed, locked, or pending.
- Use native SwiftUI patterns and accessibility-friendly controls.

## Trust And Verification

Irshad must clearly distinguish:

- verified facts
- estimates
- assumptions
- unverified items that need confirmation

Verification happens before license recommendations. `/api/verify` web-searches live facts for the best candidate license. If online confirmation fails, the server returns an authority name plus a real phone number from the KB or an official contact URL. The UI may show a tappable `tel:` link, but the user places the call.

Never fabricate:

- phone numbers
- license fees
- authority requirements
- bank minimums
- eligibility rules
- source URLs

## API Response Screens

Render these output phases as separate screens or cards:

- Analysis: matched activity, candidate licenses, setup cost range, confidence, unverified items.
- Verification: verified facts and sources, or authority contact instructions when not found.
- License: best option, issuer, why recommended, cost status, approvals, pros/cons, alternatives.
- Banking: bank options, minimum balance, requirements, docs, approval likelihood, source.
- Final plan: roadmap, estimated total cost, timeline, next action, confidence, unverified items, share/export.

## Engineering Conventions

- Prefer small SwiftUI views and focused model types.
- Put API DTOs and decoding models near the API client once the codebase grows.
- Use `async/await` for networking.
- Make network errors visible and recoverable.
- Use `Codable` for API contracts.
- Preserve unknown or optional server fields where possible so the client remains tolerant.
- Avoid local business-rule branching that belongs to the server.
- Keep UI state explicit: idle, recording, transcribing, sending, collecting, analyzing, verifying, complete, error.
- Add comments only when they clarify non-obvious behavior.

## PR Expectations

Before calling work done:

- The app builds in Xcode or with `xcodebuild`.
- The main journey can be exercised with mocked or live API data.
- Arabic text is not clipped on common iPhone sizes.
- Voice/text input paths both work or unfinished paths are clearly called out.
- Loading, error, empty, and retry states are handled for API calls.
- Verified vs unverified data is visually clear.
- No new hardcoded license/bank/government facts were added to Swift.

For demo-critical work, rehearse the fallback persona: a rural Abu Dhabi entrepreneur starting a camel milk or dairy business with about AED 20,000.

## Documentation Rules

If a Swift, SwiftUI, Apple Speech, AVFoundation, networking, or package-management question comes up, fetch current documentation first using Context7 or Apple docs tooling when available. Use the docs to answer API syntax, setup, migration, and framework behavior questions.

Keep this file short and practical. When guidance becomes too detailed, move task-specific notes into separate markdown files and link them from here.
