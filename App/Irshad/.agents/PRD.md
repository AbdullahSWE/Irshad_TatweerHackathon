# PRD: Irshad Rural Business Agent

## Swift iOS App + Next.js Backend

## 1. Product Name

**Irshad**
Arabic AI Business Concierge for rural entrepreneurs.

## 2. One-Line Pitch

**An Arabic AI agent that helps rural entrepreneurs start and grow a legal business through conversation instead of paperwork.**

## 3. Product Vision

Irshad helps rural entrepreneurs in places like Al Qua’a understand, plan, and launch small businesses by speaking naturally in Arabic.

The app guides the user through a clear business setup journey. Instead of showing forms, the app asks simple questions by voice or text, fills the business profile automatically, recommends the right license, estimates cost, suggests banks, verifies requirements, prepares next steps, and helps the user move from idea to action.

The product is not only “AI company setup.”
It is a **Rural Business Agent** that can support:

* Starting a business
* Applying for grants
* Finding financing
* Connecting to buyers
* Registering for government programs
* Scheduling appointments
* Explaining documents in spoken Arabic
* Preparing application checklists
* Helping users understand government and bank requirements

### Packages to Use (SPM):
- Apple Speech + AVSpeechSynthesizer for TextToSpeech and SpeechToText: Native Apple packages for smooth fast integration


## 4. Target Users

### Primary User

A rural UAE resident or small entrepreneur who wants to start or formalize a business but does not know the legal, banking, or government process.

Example persona:

**Mr. Ahmed, 55 years old, camel farmer in Al Qua’a**

He wants to sell camel milk legally. He has AED 20,000. He is not sure which license he needs, which authority handles it, which bank will accept him, what documents are required, or who to call.

### Secondary Users

* Young family members helping parents start a business
* Rural women running home-based businesses
* Farmers selling agricultural or animal products
* Small shop owners
* Local craft, tailoring, henna, honey, dates, or food sellers
* Community development teams supporting rural entrepreneurship

## 5. Problem Statement

Rural entrepreneurs often know their business idea clearly, but they struggle with the setup process.

They do not know:

* Which license they need
* Whether mainland or free zone is suitable
* Which authority handles their activity
* Which documents are required
* What the real cost range is
* Which bank is suitable
* Whether they are eligible as a citizen or resident
* Which government programs or support options apply
* What the next concrete action is

This creates friction, delay, dependency on others, and discouragement.

## 6. Product Goal

Build a Swift iOS app that guides a rural entrepreneur through a structured 12-phase business launch journey using Arabic voice conversation and adaptive AI-generated cards.

The backend will remain a separate **Next.js server**. The iOS app will act as a thin client that renders whatever the server sends.

The existing `baseURL` must remain unchanged for now.

## 7. Success Criteria

The MVP is successful if a user can:

1. Open the app.
2. Speak a business idea in Arabic.
3. Answer guided questions through voice or simple UI cards.
4. Watch the app automatically populate business setup sections.
5. Receive a recommended license option.
6. See estimated costs, requirements, banks, and next steps.
7. Get a final launch roadmap.
8. Share or download the summary.

For the demo, the experience should feel like:

> “I spoke to the app, and it handled the business setup journey for me.”

## 8. Core Product Principles

### 8.1 Conversation First

#### Few Instructions
- Initial screen is a simple screen telling what the app is in short like: Title - Start your business with a conversation | Subtitle - Answer a few simple questions and we'll guide you step by step
- Then the user presses one button and is not sent into the phase by phase mode for queries and live conversational style business setup helper
- The entire experience needs to be seamless and feel like a conversation.
- Integration with the API server needs to be seamless, keep placeholder BASE_URL for now but use the same endpoints.
- Use nice simple animations in between screens and nice loading progress where needed so the screen is always doing something and a nice audio wave when speaking.

The user should not feel like they are filling a form.
They should feel like they are talking to a helpful Arabic assistant.

### 8.2 Guided Journey, Not Random Chat

The experience should follow a clear 12-phase journey.
The AI can adapt questions inside each phase, but the user should always see progress.

### 8.3 Cards Fill Themselves

As the user speaks, visible cards should appear and update automatically.

Example cards:

* Business activity
* Founder profile
* Budget
* License recommendation
* Estimated cost
* Required documents
* Bank options
* Timeline
* Next action

### 8.4 Backend Drives Logic

The Swift app should not decide the journey logic.
The Next.js backend decides:

* Current phase
* Next question
* Which slots are missing
* Which cards to display
* When the profile is complete
* Which recommendations to generate

### 8.5 Trust and Grounding

The app must clearly show when information is verified, estimated, or needs confirmation.

No fake phone numbers.
No fake fees.
No invented authority requirements.

## 9. Scope

## 9.1 MVP Scope

The MVP should support one polished end-to-end business journey.

Recommended demo archetype:

**Camel milk / dairy product business in Al Qua’a**

The app should support:

* Arabic voice input
* Arabic AI responses
* English fallback for development/testing
* 12-phase visual journey
* Dynamic card renderer
* Session-based backend flow
* License recommendation
* Banking recommendation
* Verification card
* Final launch roadmap
* Share/export summary
* Existing `baseURL` unchanged

## 9.2 Post-MVP Scope

Future versions can add:

* Real AI phone call integration
* Appointment booking
* Government program application support
* Buyer matching
* Grant matching
* Document upload and OCR
* Multi-language support
* User accounts
* Saved business profiles
* Admin dashboard
* Full Track B knowledge base expansion

## 10. Non-Goals for MVP

The MVP will not:

* Directly submit official government applications
* Guarantee license approval
* Guarantee bank account approval
* Replace legal or financial advice
* Support every UAE business type on day one
* Require a complex user account system
* Change the existing backend baseURL
* Hardcode business logic inside Swift

## 11. 12-Phase User Journey

The app experience is structured around 12 visible phases.

Each phase appears as a card or section in the iOS app.
Completed phases show a checkmark.
The active phase is highlighted.
Future phases are shown as locked, dimmed, or pending.

---

# Phase 1: Welcome & Goal

## Purpose

Let the user understand what Irshad does and start the journey by speaking naturally.

## User Experience

The user sees:

* Friendly welcome message
* Microphone button
* Short explanation
* Example prompts

Example text:

> “Tell me what business you want to start. I will help you understand the license, cost, documents, bank options, and next steps.”

Example user voice input:

> “I sell camel milk. I have AED 20,000. I want to start legally.”

## iOS Requirements

* Show welcome screen.
* Show primary microphone button.
* Show secondary text input option.
* Convert speech to text.
* Send goal text to backend.
* Display AI response in Arabic.
* Move to Phase 2 after backend starts the session.

## Backend Interaction

Route:

`POST /api/journey/start`

Request:

```json
{
  "sessionId": "uuid",
  "goalText": "I sell camel milk. I have AED 20,000. I want to start legally."
}
```

Expected backend result:

* Session created
* Activity classified
* First journey card returned

---

# Phase 2: Understand the Business

## Purpose

Understand what the user wants to sell or provide.

## Questions May Include

* What product or service do you want to offer?
* Are you already selling, or is it still an idea?
* Is it camel milk, dairy product, tourism, dates, honey, food, tailoring, retail, or another activity?
* Will you produce it yourself or resell it?
* Will customers buy in person, online, or both?

## User Experience

Cards begin appearing while the user answers.

Example cards:

* Business type: Camel milk / dairy
* Current stage: Already selling / idea / expanding
* Sales channel: In-person / online / both

## iOS Requirements

* Render server-provided question cards.
* Support single-select, multi-select, text, and voice answers.
* Append answer to local session.
* Send updated session to backend.
* Update visible business profile cards.

## Backend Interaction

Route:

`POST /api/journey/next`

The backend decides which business question to ask next.

---

# Phase 3: Learn About the Founder

## Purpose

Understand who is starting the business and whether they meet basic eligibility requirements.

## Questions May Include

* Are you applying as an individual or team?
* Are you a UAE citizen, resident, or visitor?
* Do you already have a business license?
* What language do you prefer?
* Is this your first business?

## User Experience

The app shows a founder profile card.

Example fields:

* Founder type
* Residency status
* Existing business status
* Preferred language

## iOS Requirements

* Show founder profile card.
* Allow quick tap answers.
* Allow correction if user says something changed.
* Store values in session object.

---

# Phase 4: Business Details

## Purpose

Understand location, jurisdiction, sales method, and physical setup.

## Questions May Include

* Where will the business operate?
* Is the business in Al Qua’a or another rural area?
* Do you own the land?
* Do you need a physical shop or office?
* Will you sell online?
* Will you export outside the UAE?
* Do you prefer mainland or free zone, or do you want the AI to decide?

## User Experience

The app shows a business details card.

Example fields:

* Location: Al Qua’a
* Jurisdiction preference: No preference
* Office needed: No
* Sales channel: Local / online
* Export: No

## iOS Requirements

* Display dynamic form-like card.
* Use backend-provided labels.
* Do not hardcode jurisdiction rules in Swift.
* Show “AI will recommend” when user has no preference.

---

# Phase 5: Budget & Scale

## Purpose

Understand financial capacity and business size.

## Questions May Include

* How much capital do you have?
* How much do you expect to earn monthly?
* Will you employ anyone?
* Is this a small home/farm business or larger company?
* Do you want to start immediately or grow later?

## User Experience

The app shows a budget card.

Example fields:

* Available capital: AED 20,000
* Employees: 0
* Expected revenue: Unknown
* Growth plan: Start small

## iOS Requirements

* Support numeric input.
* Support budget range chips.
* Format AED values cleanly.
* Avoid requiring exact numbers when the user is unsure.

---

# Phase 6: Documents & Eligibility

## Purpose

Identify what documents the user has and what may be missing.

## Questions May Include

* Do you have Emirates ID?
* Do you have passport copy?
* Do you have land ownership or tenancy proof?
* Do you already have product approvals?
* Do you have livestock, farm, or production documents?
* Do you need food safety or agricultural approval?

## User Experience

The app shows a checklist.

Example:

* Emirates ID: Available
* Passport: Available
* Land proof: Need to confirm
* Food safety permit: May be required
* Trade name: Not selected

## iOS Requirements

* Render checklist cards.
* Show available, missing, and unknown statuses.
* Allow users to mark documents manually.
* Allow “I don’t know” answers.

---

# Phase 7: AI Analysis

## Purpose

Analyze all collected information and match the user to suitable business setup paths.

## User Experience

The UI shows an “Analyzing your business” state.

Then it displays:

* Matched business activity
* Possible license types
* Estimated setup cost range
* Confidence score
* Missing or unverified items

Example:

> “Based on your answers, this looks like a camel milk / dairy product business in rural Abu Dhabi. You may need a mainland commercial or food-related license, plus relevant food safety approval.”

## iOS Requirements

* Show loading state.
* Show analysis summary card.
* Show confidence badge.
* Show unverified items clearly.
* Continue automatically to license recommendation when complete.

## Backend Interaction

Route:

`POST /api/analyze`

---

# Phase 8: License Recommendations

## Purpose

Recommend the best license option and alternatives.

## User Experience

The app shows a clear hero card:

* Best license option
* Issuing authority
* Why this is recommended
* Estimated cost
* Timeline
* Required approvals
* Pros and cons

Example sections:

* Best option
* Alternative option
* Why not free zone
* Required government approvals
* Confidence level

## iOS Requirements

* Show best option as the main card.
* Show alternatives below.
* Use badges: Recommended, Cheaper, Needs approval, Confirm fee.
* Allow user to expand details.
* Do not make the user read long legal text first.

## Backend Interaction

Route:

`POST /api/license`

---

# Phase 9: Banking Recommendations

## Purpose

Recommend banks that are suitable for the user’s business, budget, and license type.

## User Experience

The app shows bank cards.

Each bank card may include:

* Bank name
* Minimum balance
* Required documents
* Suitability
* Why recommended
* Contact or next action
* Verification status

Example:

> “This bank may be suitable because it supports small business accounts and requires standard trade license documents.”

## iOS Requirements

* Show bank recommendation list.
* Use simple comparison layout.
* Clearly show unknown or unverified requirements.
* Allow user to save preferred bank.

## Backend Interaction

Route:

`POST /api/banking`

---

# Phase 10: Authority Verification

## Purpose

Help the user confirm live requirements, fees, and edge cases.

## MVP Version

The MVP should verify information through backend web search and trusted knowledge base sources.

If the backend cannot verify a requirement online, the app should show:

* Authority name
* Phone number if available from KB
* Official contact page if phone is unavailable
* What the user should ask
* Verification status

Example:

> “I could not confirm the latest food safety approval fee online. Please contact ADAFSA and ask: ‘What approval is required for selling camel milk products from Al Qua’a?’”

## Future Version

A future version may support:

* User-approved AI phone call
* Live call summary
* Appointment booking
* Call transcript
* Follow-up task creation

## iOS Requirements

* Show verification card.
* Show verified facts with source badge.
* Show unverified facts with “confirm by phone” badge.
* Make phone numbers tappable using `tel:`.
* Do not invent phone numbers.
* Do not show fake call progress.
* Keep AI call feature behind a future feature flag.

## Backend Interaction

Route:

`POST /api/verify`

---

# Phase 11: Appointments & Next Steps

## Purpose

Turn recommendations into action.

## User Experience

The app shows a next-step checklist.

Example:

1. Choose trade name.
2. Confirm dairy/food approval requirement.
3. Prepare Emirates ID and passport copy.
4. Apply for recommended license.
5. Open business bank account.
6. Start selling legally.

Possible appointment cards:

* Licensing authority appointment
* Bank appointment
* Advisor appointment
* Document preparation reminder

## MVP Version

For MVP, the app should prepare the action checklist and show contact options.

## Future Version

Future releases can integrate real appointment booking.

## iOS Requirements

* Show action checklist.
* Allow checking items as done.
* Allow copying authority questions.
* Allow opening phone, website, or map links.
* Allow saving next action.

---

# Phase 12: Business Launch Plan

## Purpose

Give the user one final roadmap they can understand, share, or download.

## User Experience

The final screen should feel like a completed plan.

It should include:

* Business summary
* Recommended license
* Estimated setup cost
* Required documents
* Required approvals
* Recommended banks
* Timeline
* Immediate next action
* Unverified items
* Confidence score

Example next action:

> “Your next action is to confirm food safety approval requirements, then apply for the recommended Abu Dhabi mainland license.”

## iOS Requirements

* Render final roadmap.
* Allow share as PDF/text.
* Allow copy summary.
* Allow continue with AI assistant.
* Save session locally if user returns later.

## Backend Interaction

Route:

`POST /api/plan/final`

---

## 12. Swift iOS App Requirements

## 12.1 Main Screens

### Screen 1: Welcome / Start

Purpose:

* Introduce Irshad
* Capture the user’s business idea
* Start voice journey

Main components:

* App logo/name
* Arabic welcome message
* Microphone button
* Text fallback
* Example prompts

### Screen 2: Journey

Purpose:

* Main guided experience
* Show conversation and auto-filling cards

Main components:

* Phase stepper
* AI message bubble
* User response bubble
* Dynamic card renderer
* Microphone button
* Text input fallback
* Progress indicator

### Screen 3: Results

Purpose:

* Show analysis, license, banking, verification, and final plan

Main components:

* Analysis card
* License recommendation card
* Banking cards
* Verification card
* Roadmap card
* Share/export button

### Screen 4: Saved Plan

Purpose:

* Allow user to return to the generated business plan

Main components:

* Business title
* Summary
* Checklist
* Continue button

## 12.2 Dynamic Card Renderer

The Swift app must render cards from the backend using a generic schema.

Supported card types:

* `single_select`
* `multi_select`
* `text`
* `number`
* `toggle`
* `checklist`
* `info`
* `summary`
* `recommendation`
* `roadmap`

The iOS app should not need a new build every time the backend changes a question.

## 12.3 Voice Input

The app should support:

* Press-to-talk microphone button
* Speech-to-text
* Editable transcription
* Submit answer
* Arabic-first experience
* Text fallback

Voice flow:

1. User taps microphone.
2. App records speech.
3. Speech becomes text.
4. User can confirm or edit.
5. Text is sent to backend.
6. Backend returns next card and AI response.

## 12.4 Arabic AI Response

The AI should respond in spoken or written Arabic.

MVP:

* Show Arabic text response.
* Optional system TTS if available.

Future:

* More natural Arabic voice.
* Emirati dialect mode.
* Voice persona selection.

## 12.5 Auto-Filling UI

The UI should visibly update as information is collected.

Example:

User says:

> “I sell camel milk and I have AED 20,000.”

The app should populate:

* Business activity: Camel milk
* Budget: AED 20,000
* Stage: Starting legally
* Possible authority: Pending analysis

This creates the “Cursor-like” wow effect.

## 12.6 Progress Stepper

The app should show the 12 phases as progress.

Recommended compact display:

1. Goal
2. Business
3. Founder
4. Details
5. Budget
6. Documents
7. Analysis
8. License
9. Banking
10. Verify
11. Next Steps
12. Plan

Completed phases show checkmarks.
The current phase is highlighted.

## 13. Backend Architecture

The backend is a separate **Next.js server**.

The iOS app communicates with the backend using the existing baseURL.

Important requirement:

**Do not change the current baseURL for now.**

The Swift API client should keep the existing baseURL constant and only add or update route paths.

## 13.1 Backend Responsibilities

The backend handles:

* Session creation
* Activity classification
* Journey stage management
* Adaptive question generation
* Slot filling
* Completeness gate
* KB lookup
* Web verification
* License recommendation
* Banking recommendation
* Final plan generation

## 13.2 iOS Responsibilities

The iOS app handles:

* Voice input
* Text input
* Rendering cards
* Showing progress
* Sending session updates
* Displaying results
* Sharing/exporting final plan
* Local UI state

The iOS app should not decide:

* Which license is correct
* Which bank is suitable
* Which question comes next
* Whether a phase is complete
* Whether information is verified

## 14. API Routes

The iOS app should call these backend routes.

| Phase        | Route                     | Purpose                         |
| ------------ | ------------------------- | ------------------------------- |
| Start        | `POST /api/journey/start` | Start session and classify idea |
| Journey Loop | `POST /api/journey/next`  | Get next adaptive card          |
| Analysis     | `POST /api/analyze`       | Analyze business profile        |
| Verify       | `POST /api/verify`        | Verify live facts               |
| License      | `POST /api/license`       | Recommend license               |
| Banking      | `POST /api/banking`       | Recommend banks                 |
| Final Plan   | `POST /api/plan/final`    | Generate launch roadmap         |

## 15. Session Object

The session is the single source of truth.

Example:

```json
{
  "sessionId": "uuid",
  "goalText": "I sell camel milk. I have AED 20,000. I want to start legally.",
  "currentPhase": "business",
  "filledSlots": {
    "activity": "camel_milk_dairy",
    "stage": "already_selling",
    "founderType": "individual",
    "residency": "uae_resident",
    "location": "Al Qua'a",
    "jurisdictionPref": "no_preference",
    "channel": "in_person",
    "capital": 20000,
    "employees": 0,
    "language": "ar"
  },
  "history": [
    {
      "cardId": "q_business_activity",
      "question": "What do you want to sell?",
      "answer": "Camel milk"
    }
  ]
}
```

## 16. Card Schema

The backend returns cards.
The Swift app renders them.

Example:

```json
{
  "cardId": "q_land_ownership",
  "kind": "question",
  "type": "single_select",
  "phase": "business_details",
  "title": "Do you already own the land?",
  "subtitle": "This helps me understand which approvals may apply.",
  "options": [
    "Yes, I own the land",
    "No, I rent it",
    "I am not sure"
  ],
  "slot": "landOwnership"
}
```

## 17. Swift Data Models

Recommended Swift models:

```swift
struct JourneySession: Codable {
    var sessionId: String
    var goalText: String?
    var currentPhase: JourneyPhase
    var filledSlots: [String: String]
    var history: [JourneyHistoryItem]
}

struct JourneyHistoryItem: Codable, Identifiable {
    var id: String { cardId }
    let cardId: String
    let question: String
    let answer: String
}

struct JourneyCard: Codable, Identifiable {
    let id: String
    let kind: CardKind
    let type: CardType
    let phase: JourneyPhase
    let title: String
    let subtitle: String?
    let options: [String]?
    let slot: String?
}

enum CardKind: String, Codable {
    case question
    case confirmation
    case info
    case recommendation
    case roadmap
}

enum CardType: String, Codable {
    case singleSelect = "single_select"
    case multiSelect = "multi_select"
    case text
    case number
    case toggle
    case checklist
    case info
    case summary
    case recommendation
    case roadmap
}

enum JourneyPhase: String, Codable, CaseIterable {
    case welcomeGoal = "welcome_goal"
    case understandBusiness = "understand_business"
    case founder = "founder"
    case businessDetails = "business_details"
    case budgetScale = "budget_scale"
    case documentsEligibility = "documents_eligibility"
    case aiAnalysis = "ai_analysis"
    case licenseRecommendations = "license_recommendations"
    case bankingRecommendations = "banking_recommendations"
    case authorityVerification = "authority_verification"
    case appointmentsNextSteps = "appointments_next_steps"
    case businessLaunchPlan = "business_launch_plan"
}
```

## 18. API Client Requirement

The existing baseURL must stay unchanged.

Example structure:

```swift
final class APIClient {
    static let shared = APIClient()

    private let baseURL = AppConfig.baseURL

    func post<T: Encodable, R: Decodable>(
        path: String,
        body: T
    ) async throws -> R {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw APIError.badResponse
        }

        return try JSONDecoder().decode(R.self, from: data)
    }
}
```

Route usage:

```swift
try await api.post(path: "/api/journey/start", body: request)
try await api.post(path: "/api/journey/next", body: request)
try await api.post(path: "/api/analyze", body: request)
try await api.post(path: "/api/verify", body: request)
try await api.post(path: "/api/license", body: request)
try await api.post(path: "/api/banking", body: request)
try await api.post(path: "/api/plan/final", body: request)
```

## 19. Main User Flow

1. User opens app.
2. User taps microphone.
3. User says business idea.
4. iOS sends goal text to backend.
5. Backend starts session.
6. iOS renders first card.
7. User answers by voice or tap.
8. iOS sends updated session.
9. Backend returns next card.
10. Loop continues until required information is complete.
11. Backend generates analysis.
12. Backend generates license recommendation.
13. Backend generates banking recommendation.
14. Backend verifies important facts.
15. Backend generates next steps.
16. Backend generates final business launch plan.
17. User shares or saves the plan.

## 20. MVP Demo Flow

Demo input:

> “I sell camel milk. I have AED 20,000. I want to start legally.”

Expected visible flow:

1. App recognizes camel milk business.
2. Business activity card appears.
3. Budget card auto-fills AED 20,000.
4. AI asks whether the user owns land.
5. AI asks whether the user will employ anyone.
6. AI asks whether the user will sell online or in person.
7. AI analyzes the setup.
8. License recommendation appears.
9. Estimated cost appears.
10. Required documents appear.
11. Bank options appear.
12. Verification card appears.
13. Final roadmap appears.

The demo should visually show cards being completed as the user talks.

## 21. UX Tone

The tone should be:

* Respectful
* Simple
* Arabic-first
* Helpful
* Calm
* Trustworthy
* Non-technical

Avoid:

* Complicated legal language
* Long paragraphs
* Too many forms
* Making the user feel judged
* Showing uncertain information as fact

## 22. Error States

The app should handle:

### Backend Error

Message:

> “I could not reach the server. Please try again.”

### Speech Recognition Error

Message:

> “I could not hear clearly. You can try again or type your answer.”

### Missing Information

Message:

> “I still need one more detail before I can recommend the best option.”

### Unverified Requirement

Message:

> “This detail needs confirmation from the authority.”

### No Matching Business Type

Message:

> “I could not confidently match this business activity yet. I can still prepare a general startup checklist.”

## 23. Trust & Safety Requirements

The app must:

* Mark estimates clearly.
* Mark unverified information clearly.
* Never invent license fees.
* Never invent bank requirements.
* Never invent phone numbers.
* Never guarantee approval.
* Show that final recommendations are guidance, not legal advice.
* Let the user review information before taking action.

## 24. Analytics Events

Track these events:

* `journey_started`
* `voice_input_started`
* `voice_input_completed`
* `card_rendered`
* `card_answered`
* `phase_completed`
* `analysis_generated`
* `license_generated`
* `banking_generated`
* `verification_completed`
* `plan_generated`
* `plan_shared`
* `journey_abandoned`

Useful properties:

* `sessionId`
* `phase`
* `cardType`
* `activityType`
* `language`
* `completionTime`
* `errorType`

## 25. Performance Requirements

* App launch should feel instant.
* Card transitions should be smooth.
* Backend loading states should be shown after 500ms.
* Voice recording should start immediately after tapping microphone.
* The user should never see a blank screen while waiting.
* API timeout should show a retry option.

## 26. Accessibility Requirements

The app should support:

* Large text
* Voice-first interaction
* Clear contrast
* Simple buttons
* Arabic right-to-left layout
* Tap targets large enough for older users
* Minimal typing requirement

## 27. Design Direction

Visual style:

* Warm
* Rural-friendly
* Government-service trustworthy
* Simple cards
* Large microphone button
* Clear progress
* Minimal clutter

Recommended UI elements:

* Stepper
* Checkmarked cards
* Voice waveform
* Auto-filling summary cards
* Recommendation badges
* Final roadmap timeline

## 28. Build Priority

### Priority 1

* Keep existing baseURL.
* Build API client.
* Build welcome screen.
* Build microphone/text input.
* Build dynamic card renderer.
* Build 12-phase stepper.
* Connect `/api/journey/start`.
* Connect `/api/journey/next`.

### Priority 2

* Build analysis screen.
* Build license card.
* Build banking card.
* Build verification card.
* Build final plan screen.

### Priority 3

* Add share/export.
* Add saved plan.
* Add better Arabic voice output.
* Add animations.
* Add future call/appointment feature flags.

## 29. Acceptance Criteria

The MVP is accepted when:

* The app runs on a real iPhone.
* The existing baseURL remains unchanged.
* The user can start with a voice business idea.
* The app creates a session.
* The app renders backend cards dynamically.
* The user can complete the 12-phase journey.
* The app displays analysis, license, banking, verification, and final plan.
* The final plan can be shared or copied.
* The app clearly marks unverified information.
* The iOS app does not hardcode licensing logic.
* The journey works smoothly for the camel milk demo persona.

## 30. Final Demo Narrative

A 55-year-old camel farmer in Al Qua’a opens Irshad.

He presses one microphone button and says:

> “I sell camel milk. I have AED 20,000. I want to start legally.”

The AI replies in Arabic and starts asking simple questions.

As he answers, the screen fills itself:

* Business activity
* Budget
* Founder details
* Documents
* License
* Cost
* Banks
* Timeline
* Next steps

At the end, he receives a clear roadmap showing how to legally start his business.

The user does not need to understand government forms first.
He only needs to explain his goal.

Irshad turns that goal into a practical business launch path.
