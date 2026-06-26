# Prompt 06.01: Journey API Service Implementation

## Context

Implement the backend API service for Irshad. The iOS client posts to exactly seven Next.js endpoints, decodes flexible backend responses, and preserves user/session state by surfacing errors instead of retrying or clearing data. The ViewModel owns orchestration and retry; this service owns URL construction, request encoding, response status handling, and response decoding.

This prompt implements networking only. Do not implement ViewModel behavior, speech services, local persistence, sharing, SwiftUI views, reusable components, theme files, visual styling, animations, or gesture handlers.

## File Location

Update:

- `Irshad/Services/JourneyAPIService.swift`
- `Irshad/Services/APIResponses.swift`
- `Irshad/Utilities/URL+EndpointJoining.swift`
- API-focused model decoding helpers if needed in `Irshad/Models/`

## Dependencies

- Imports: `Foundation`
- Depends on: `AppConfig`, API request/response DTOs, models, `APIError`, `JourneyEndpoint`
- Later consumers: `JourneyViewModel`, API tests

## Requirements

- Implement `JourneyAPIServiceProtocol` against `URLSession`.
- Encode JSON bodies with `JSONEncoder`.
- Decode JSON responses with `JSONDecoder`.
- Set `Content-Type: application/json` and `Accept: application/json`.
- Apply a reasonable per-request timeout through `URLRequest.timeoutInterval`.
- Normalize endpoint paths with or without a leading slash.
- Reject paths not present in `JourneyEndpoint.allCases`.
- Convert non-2xx responses to `APIError.badStatus`.
- Convert decoding failures to `APIError.decoding`.
- Convert cancellation to `APIError.cancelled`.
- Convert network transport failures to `APIError.transport` or `APIError.timeout`.
- Do not retry automatically.

## Interface

Keep this protocol unchanged:

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
```

Implement the URL helper:

```swift
extension URL {
    func appendingEndpointPath(_ path: String) throws -> URL {
        let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: normalized, relativeTo: self)?.absoluteURL else {
            throw APIError.invalidURL(path)
        }
        return url
    }
}
```

Implement endpoint methods with these path mappings:

```swift
func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse {
    try await post(request, to: .start)
}

func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse {
    try await post(request, to: .next)
}

func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse {
    try await post(request, to: .analyze)
}

func verify(_ request: VerifyRequest) async throws -> VerifyResponse {
    try await post(request, to: .verify)
}

func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse {
    try await post(request, to: .license)
}

func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse {
    try await post(request, to: .banking)
}

func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse {
    try await post(request, to: .finalPlan)
}
```

## Response Decoding Rules

- `JourneyResponseStatus` decodes:
  - `"collecting"` -> `.collecting`
  - `"gate_open"` -> `.gateOpen`
  - `"ready"` -> `.ready`
  - unknown strings -> `.unknown(raw)`
- `StartJourneyResponse` accepts top-level `framing`, `activity`, `card`, `progress`, `currentStage`, `currentPhase`, and optional `session`.
- `NextJourneyResponse` accepts top-level `status`, `session`, `currentStage`, `currentPhase`, `stageJustCompleted`, `progress`, and `card`.
- `AnalyzeResponse` decodes top-level `analysis`.
- `VerifyResponse` may decode either a top-level verification object or fields that map into `VerificationSummary`; support the documented `verified` and `not_found` payloads.
- `LicenseResponse` decodes top-level `license`.
- `BankingResponse` decodes top-level `banking`.
- `FinalPlanResponse` decodes top-level `plan`.

## Implementation Notes

- Keep `URLSession`, `JSONEncoder`, and `JSONDecoder` injected through the initializer for tests.
- Use a private generic helper:

```swift
private func post<Request: Encodable, Response: Decodable>(
    _ request: Request,
    to endpoint: JourneyEndpoint
) async throws -> Response
```

- Preserve backend error body text when safe by attaching it to `APIError.badStatus`.
- Do not inspect response content to decide legal, banking, fee, authority, or journey-stage business rules.
- The ViewModel later handles `ready` compatibility with gate-open behavior only when no card is present and progress indicates completion.

## Acceptance Criteria

- [ ] `url(for: "/api/analyze")` returns `http://localhost:3001/api/analyze`.
- [ ] `url(for: "api/analyze")` returns `http://localhost:3001/api/analyze`.
- [ ] All seven `JourneyEndpoint` cases resolve against `AppConfig.baseURL`.
- [ ] A path outside `JourneyEndpoint.allCases` cannot be posted.
- [ ] Every endpoint method uses POST and the documented path.
- [ ] Non-2xx responses throw `APIError.badStatus`.
- [ ] Malformed JSON throws `APIError.decoding`.
- [ ] Cancellation throws or maps to `APIError.cancelled`.
- [ ] Dynamic cards, flexible JSON slots, and unknown card types decode according to model rules.
- [ ] No automatic retry is performed.
- [ ] No ViewModel, speech, persistence, sharing, UI, component, theme, style, animation, gesture, or business-rule logic is added by this prompt.
