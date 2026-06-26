# Prompt 01: Project Scaffold

## Context

Create the native iOS project foundation for Irshad, an Arabic-first SwiftUI client for a Next.js backend. This prompt establishes the app target, folder structure, framework settings, and backend configuration that all later model, service, ViewModel, and UI prompts depend on.

This build order is non-UI. Create empty `Theme/`, `Views/`, and `Components/` folders for the UX/UI build order, but do not create SwiftUI view files, reusable components, design tokens, visual states, animations, or gesture code.

## File Location

Create or configure:

- `Irshad.xcodeproj`
- `Irshad/App/AppConfig.swift`
- `Irshad/App/Info.plist` or target build settings for privacy strings
- `Irshad/Models/`
- `Irshad/Services/`
- `Irshad/ViewModels/`
- `Irshad/Navigation/`
- `Irshad/Utilities/`
- `Irshad/Theme/`
- `Irshad/Views/`
- `Irshad/Components/`
- `IrshadTests/`

## Dependencies

- Imports needed in this prompt: `Foundation`
- Minimum deployment target: iOS 17
- Swift language: Swift 5.9 or newer
- Swift packages: none
- Apple frameworks required by the planned app: `SwiftUI`, `Observation`, `Foundation`, `Speech`, `AVFoundation`, `UIKit`

## Requirements

- Create an iOS app project named `Irshad`.
- Use SwiftUI app lifecycle and Swift Observation.
- Configure the main app target to include `Speech.framework`, `AVFoundation.framework`, and `UIKit`.
- Add speech and microphone privacy usage strings for the app target:
  - `NSSpeechRecognitionUsageDescription`
  - `NSMicrophoneUsageDescription`
- Do not add third-party Swift Package Manager dependencies for the MVP.
- Create the exact top-level folders listed in the file location section.
- Keep `Theme/`, `Views/`, and `Components/` empty for the UX/UI build order.
- Add the backend configuration namespace exactly as specified below.

## Interface

Create `Irshad/App/AppConfig.swift`:

```swift
import Foundation

enum AppConfig {
    static let baseURL = URL(string: "http://localhost:3001/")!
}
```

## Implementation Notes

- Do not add environment switching, staging URLs, feature flags, or remote config.
- Do not create placeholder view files to make the app compile. The UX/UI build order owns view creation.
- Do not add license, bank, authority, fee, phone, or journey-stage business rules to the client.
- The canonical backend route order for the app is:

```text
start -> next* -> analyze -> verify -> license -> banking -> plan
```

- Allowed backend paths are:

```text
/api/journey/start
/api/journey/next
/api/analyze
/api/verify
/api/license
/api/banking
/api/plan/final
```

## Acceptance Criteria

- [ ] The Xcode project has an iOS 17+ SwiftUI app target named `Irshad`.
- [ ] `Irshad/App/AppConfig.swift` exists and exposes `AppConfig.baseURL` exactly as `http://localhost:3001/`.
- [ ] `Models/`, `Services/`, `ViewModels/`, `Navigation/`, and `Utilities/` exist for dev prompts.
- [ ] Empty `Theme/`, `Views/`, and `Components/` folders exist for the UX/UI build order.
- [ ] Speech and microphone privacy usage strings are present.
- [ ] No third-party packages are added.
- [ ] No SwiftUI view, reusable component, theme token, styling, animation, or visual layout file is created by this prompt.
