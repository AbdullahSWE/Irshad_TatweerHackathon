# Prompt 05: App Entry And Environment

## Context

Create the app-level wiring for Irshad: runtime service construction, root ViewModel creation, simple navigation/external-action helpers, and the handoff point where the UX/UI build order will attach the real root view. This prompt wires non-UI infrastructure only. Full launch verification waits until the UX/UI build order creates the root SwiftUI view.

Do not create screen views, reusable UI components, theme files, visual styling, animations, or gesture handlers.

## File Location

Create:

- `Irshad/App/AppEnvironment.swift`
- `Irshad/App/IrshadApp.swift`
- `Irshad/Navigation/JourneyRouter.swift`
- `Irshad/Utilities/ClipboardClient.swift`
- `Irshad/Utilities/DateFormatting.swift`
- `Irshad/Utilities/URL+EndpointJoining.swift`

## Dependencies

- Imports: `Foundation`, `SwiftUI`, `UIKit`
- Depends on: `AppConfig`, models, service protocols, concrete service stubs, `JourneyViewModel`
- Later consumers: UX/UI root view, ViewModel implementation, integration tests

## Requirements

- Build a lightweight environment factory for runtime dependencies.
- Create one shared `JourneyViewModel` at the app/root screen boundary.
- Provide a handoff contract for the UX/UI build order: the UI will supply `JourneyView(viewModel:)` or equivalent.
- Add small utility types needed by service and ViewModel implementations.
- Do not use a dependency injection framework.
- Do not introduce routes outside the seven allowed backend paths.

## Interface

### App Environment

`Irshad/App/AppEnvironment.swift`

```swift
struct AppEnvironment: Sendable {
    let apiService: JourneyAPIServiceProtocol
    let speechRecognitionService: SpeechRecognitionServiceProtocol
    let speechSynthesisService: SpeechSynthesisServiceProtocol
    let localPlanStore: LocalPlanStoreProtocol
    let shareService: ShareServiceProtocol
    let analyticsService: AnalyticsServiceProtocol

    static var live: AppEnvironment { get }

    func makeJourneyViewModel() -> JourneyViewModel
}
```

`AppEnvironment.live` creates:

- `JourneyAPIService()`
- `SpeechRecognitionService()`
- `SpeechSynthesisService()`
- `LocalPlanStore()`
- `ShareService()`
- `AnalyticsService()` or `NoopAnalyticsService()` if analytics should be silent for MVP

### App Entry

`Irshad/App/IrshadApp.swift`

```swift
@main
struct IrshadApp: App {
    @State private var viewModel = AppEnvironment.live.makeJourneyViewModel()

    var body: some Scene {
        WindowGroup {
            JourneyView(viewModel: viewModel)
        }
    }
}
```

The `JourneyView` type is owned by the UX/UI build order. If this prompt is implemented before the UI exists, it is acceptable for the app target not to build until the UX/UI build order creates that root view.

### Router

`Irshad/Navigation/JourneyRouter.swift`

```swift
struct JourneyRouter {
    func canOpenBackendProvidedURL(_ url: URL) -> Bool
    func makeTelephoneURL(from backendPhoneNumber: String) -> URL?
}
```

### Clipboard Client

`Irshad/Utilities/ClipboardClient.swift`

```swift
@MainActor
struct ClipboardClient {
    func copy(_ text: String)
}
```

### Date Formatting

`Irshad/Utilities/DateFormatting.swift`

```swift
enum DateFormatting {
    static func savedPlanTitleDate(_ date: Date) -> String
}
```

### Endpoint Joining

`Irshad/Utilities/URL+EndpointJoining.swift`

```swift
extension URL {
    func appendingEndpointPath(_ path: String) throws -> URL
}
```

The endpoint joining implementation must trim leading slashes before resolving against `AppConfig.baseURL`.

## Implementation Notes

- `JourneyRouter` only validates and creates system handoff URLs. It must not fabricate phone numbers or contact URLs.
- `makeTelephoneURL(from:)` returns `nil` for empty strings or values that cannot become a safe `tel:` URL.
- `ClipboardClient` may wrap `UIPasteboard.general.string`.
- Do not present UIKit controllers here. UI presentation belongs to the UX/UI build order.
- `IrshadApp.swift` may be added now as the contract, even if compilation waits for `JourneyView`.
- Do not add any route, endpoint, or network call here.

## Acceptance Criteria

- [ ] `AppEnvironment.live` constructs all runtime services.
- [ ] `AppEnvironment.makeJourneyViewModel()` injects protocol-typed dependencies into `JourneyViewModel`.
- [ ] `IrshadApp` creates one shared `JourneyViewModel` at the root boundary.
- [ ] The app entry references the UX/UI-owned root view without implementing that view.
- [ ] `JourneyRouter` rejects empty or fabricated phone handoff values.
- [ ] Endpoint joining utility trims leading slashes before URL resolution when implemented.
- [ ] No screen view, reusable UI component, theme file, visual style, animation, gesture handler, new route, or backend business rule is added by this prompt.
