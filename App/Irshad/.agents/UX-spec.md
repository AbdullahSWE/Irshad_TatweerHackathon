# UX Specification: Irshad Rural Business Agent

## Source Inputs

- Source PRD: `files/PRD.md`
- Clarification source: `files/PRD-clarification-sessionc` was not present; `files/dev-clarification-session.md` was present but empty.
- Output purpose: persistent UX handoff for mockup, design, and SwiftUI implementation planning.
- Interface boundary: this spec describes how the iOS app presents the existing PRD-defined backend journey. It does not introduce new API routes, data models, or business-decision logic.

## Pass 1: Mental Model

**Primary user intent:** The user wants to explain a business idea in natural Arabic or English and receive a clear, trustworthy path for starting or formalizing that business without needing to understand government paperwork first.

**Likely misconceptions:**
- The user may think the app can submit government or bank applications directly.
- The user may think every recommendation is officially verified and guaranteed.
- The user may think they must fill a long form before the app can help.
- The user may think one unclear answer will stop the journey.
- The user may expect the app to decide legal, banking, and authority rules locally instead of using the backend.

**UX principle to reinforce/correct:** Irshad is a guided conversation that turns the user's goal into an actionable business launch plan while clearly separating confirmed facts, estimates, missing information, and guidance that still needs authority or bank confirmation.

## Pass 2: Information Architecture

**All user-visible concepts:**
- App name: Irshad
- Arabic AI business concierge
- Welcome message
- Business goal
- Voice input
- Text fallback
- Editable transcription
- AI response
- Conversation history
- Session progress
- 12-phase journey
- Phase completion
- Locked or pending future phases
- Dynamic cards
- Card questions
- Card answers
- Single-select options
- Multi-select options
- Text answers
- Number answers
- Toggle answers
- Checklist items
- Info cards
- Summary cards
- Recommendation cards
- Roadmap cards
- Business activity
- Current business stage
- Founder profile
- Residency or eligibility status
- Preferred language
- Business location
- Jurisdiction preference
- Sales channel
- Physical setup needs
- Budget and capital
- Employees
- Expected revenue
- Documents
- Missing documents
- Unknown documents
- Business analysis
- Confidence level
- License recommendation
- Alternative license options
- Issuing authority
- Estimated setup cost
- Required approvals
- Pros and cons
- Bank recommendations
- Minimum balance
- Bank requirements
- Saved preferred bank
- Verification status
- Verified facts
- Estimated facts
- Unverified facts
- Official contact action
- Phone action
- Website action
- Authority questions to ask
- Next-step checklist
- Appointment or contact options
- Final business launch plan
- Immediate next action
- Share action
- Copy summary action
- Saved plan
- Retry action
- Error messages
- Guidance disclaimer
- Analytics-worthy milestones

**Grouped structure:**

### Journey Orientation
- Irshad identity: Primary
- Welcome message: Primary
- 12-phase journey: Primary
- Phase completion: Primary
- Locked or pending future phases: Secondary
- Session progress: Primary
- Rationale: Users need to know the app is guiding them through a real process, not dropping them into open-ended chat.

### Conversation Input
- Voice input: Primary
- Text fallback: Primary
- Editable transcription: Primary
- AI response: Primary
- Conversation history: Secondary
- Retry action: Secondary
- Rationale: The app must feel conversation-first while preserving a low-stress fallback when speech recognition is imperfect.

### Dynamic Card System
- Dynamic cards: Primary
- Card questions: Primary
- Card answers: Primary
- Single-select options: Primary
- Multi-select options: Primary
- Text answers: Primary
- Number answers: Primary
- Toggle answers: Primary
- Checklist items: Primary
- Info cards: Secondary
- Summary cards: Secondary
- Recommendation cards: Primary
- Roadmap cards: Primary
- Rationale: Cards are how the backend makes the conversation visible and how the user sees the profile filling itself.

### Business Profile
- Business goal: Primary
- Business activity: Primary
- Current business stage: Primary
- Founder profile: Primary
- Residency or eligibility status: Primary
- Preferred language: Secondary
- Business location: Primary
- Jurisdiction preference: Secondary
- Sales channel: Primary
- Physical setup needs: Secondary
- Budget and capital: Primary
- Employees: Secondary
- Expected revenue: Secondary
- Documents: Primary
- Missing documents: Primary
- Unknown documents: Primary
- Rationale: These details are the minimum understandable profile the user can review before recommendations appear.

### Analysis And Recommendations
- Business analysis: Primary
- Confidence level: Primary
- License recommendation: Primary
- Alternative license options: Secondary
- Issuing authority: Primary
- Estimated setup cost: Primary
- Required approvals: Primary
- Pros and cons: Secondary
- Bank recommendations: Primary
- Minimum balance: Secondary
- Bank requirements: Secondary
- Saved preferred bank: Secondary
- Rationale: Recommendations must be easy to scan first and expandable only when the user needs more detail.

### Trust And Verification
- Verification status: Primary
- Verified facts: Primary
- Estimated facts: Primary
- Unverified facts: Primary
- Official contact action: Secondary
- Phone action: Secondary
- Website action: Secondary
- Authority questions to ask: Primary
- Guidance disclaimer: Secondary
- Rationale: Trust depends on making uncertainty legible and giving the user a concrete next action for anything not confirmed.

### Action And Completion
- Next-step checklist: Primary
- Appointment or contact options: Secondary
- Final business launch plan: Primary
- Immediate next action: Primary
- Share action: Primary
- Copy summary action: Primary
- Saved plan: Secondary
- Rationale: The journey should end with practical momentum, not just information.

### System Feedback
- Error messages: Primary
- Loading and progress states: Primary
- Analytics-worthy milestones: Hidden
- Rationale: The user sees system confidence and recovery paths; implementation telemetry remains hidden unless surfaced through product analytics.

## Pass 3: Affordances

| Action | Visual/Interaction Signal |
|--------|---------------------------|
| Start the journey | One dominant start control with microphone meaning, supported by a secondary text entry path. |
| Speak an answer | Microphone control changes state while listening and shows live waveform or recording feedback. |
| Type instead of speaking | Text field is always reachable near the current prompt, with submit available after text entry. |
| Edit transcription | Transcribed speech appears in an editable confirmation area before submission. |
| Submit an answer | Clear confirm/send action appears after voice transcription or manual text entry. |
| Choose one option | Single-select cards allow one selected state at a time and advance or reveal confirm action. |
| Choose multiple options | Multi-select cards retain several selected states and require explicit confirmation. |
| Enter a number | Number cards use numeric input, AED formatting where relevant, and quick budget range choices. |
| Toggle yes/no details | Toggle cards present two-state choices with the current choice plainly marked. |
| Mark checklist item | Checklist rows expose available, missing, unknown, and completed states distinctly. |
| Review auto-filled data | Filled profile fields appear as generated outputs, with edit/correction entry points kept nearby. |
| Correct a previous answer | Correction action is available from profile cards and conversation entries without implying failure. |
| Expand recommendation detail | Recommendation cards show summary first and reveal rationale, pros, cons, and requirements on expand. |
| Save a preferred bank | Bank card has a persistent save affordance separate from opening details. |
| Open phone, website, or map | Contact rows use familiar action icons and platform link behavior. |
| Copy authority question | Verification question has a copy action placed with the exact question text. |
| Retry after an error | Error states include a specific retry action at the failed point. |
| Share final plan | Final plan has a primary share/export action and secondary copy summary action. |
| Return to saved plan | Saved plan entry presents business title, status, and continue action. |

**Affordance rules:**
- If the user sees a question card, they should assume Irshad is waiting for their answer.
- If the user sees a summary or recommendation card, they should assume it is output from the backend and can be reviewed before acting.
- If a value is marked unknown or unverified, the user should assume it is not safe to treat as confirmed.
- If a card is completed, the user should assume they can continue but may still correct the information.
- If a phase is locked or pending, the user should assume it will become available when the backend has enough information.
- If the app is listening, the user should receive immediate feedback that recording has started.
- If backend work is happening, the user should see progress feedback after a short wait instead of a blank screen.
- If a phone number is shown, the user should assume it came from backend knowledge or verification data, never from UI invention.

## Pass 4: Cognitive Load

**Friction points:**

| Moment | Type | Simplification |
|--------|------|----------------|
| First launch | Uncertainty | Explain the promise in one short message and offer one main action: start with voice. |
| Choosing between voice and text | Choice | Default to voice, keep text fallback visible but secondary. |
| Speech recognition transcript appears | Uncertainty | Let the user confirm, edit, or retry before sending. |
| User does not know exact business category | Uncertainty | Accept natural language and let backend classify activity. |
| User does not know jurisdiction preference | Choice | Offer "AI will recommend" as a normal option. |
| User does not know exact budget or revenue | Uncertainty | Allow ranges, unknown values, and later correction. |
| Document questions feel legalistic | Uncertainty | Use checklist status labels: available, missing, not sure. |
| Waiting for analysis | Waiting | Show an active analysis state with what Irshad is checking. |
| Reading license recommendation | Choice | Highlight best option first, keep alternatives collapsed below. |
| Reading bank options | Choice | Present simple comparison and suitability before detailed requirements. |
| Verification cannot confirm a requirement | Uncertainty | Show the authority, what is unverified, and the exact question to ask. |
| Moving from information to action | Choice | Provide one immediate next action before the full checklist. |
| Final plan is long | Cognitive load | Group by summary, recommendation, required documents, timeline, and next action. |
| Backend or speech error | Error recovery | Keep the current session visible and retry at the failed step. |

**Defaults introduced:**
- Voice-first input: Matches the PRD promise and reduces typing for older or rural users.
- Arabic-first language: Matches the target audience; English remains only fallback/testing support.
- Backend-driven next step: Prevents the user from choosing workflow branches manually.
- "I do not know" as acceptable answer: Keeps uncertain users moving without pretending facts are known.
- AI recommendation when jurisdiction is unclear: Avoids forcing legal knowledge before the app can help.
- Best recommendation shown before alternatives: Reduces comparison burden while preserving transparency.
- Estimated and unverified facts labeled by default: Prevents accidental overtrust.
- One immediate next action on final plan: Turns a complex roadmap into a clear first move.

## Pass 5: State Design

### Welcome / Start

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Irshad identity, short Arabic-first promise, microphone start, text fallback, example business prompts. | The app helps them start a business through conversation. | Start speaking or type their idea. |
| Loading | App preparing voice/session capabilities with no blank screen. | Irshad is getting ready. | Wait briefly or use text fallback if available. |
| Success | Goal captured and sent to backend; first AI response or first journey card appears. | The journey has started. | Continue answering. |
| Partial | Text fallback works but voice permission or speech setup is incomplete. | They can still use the app without voice. | Type the idea or adjust permissions. |
| Error | Plain message that server or speech setup could not start. | The app cannot proceed through that path right now. | Retry, type instead, or return later. |

### Voice And Transcription

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Microphone idle state and current question. | Irshad is ready to listen. | Tap to speak or type. |
| Loading | Listening indicator, waveform, or recording feedback. | The app is capturing speech. | Speak, stop recording, or cancel. |
| Success | Editable transcript and confirm/send action. | Speech was understood enough to review. | Submit, edit, or retry. |
| Partial | Low-confidence or incomplete transcript with helpful retry path. | Irshad may not have heard clearly. | Edit the text, retry, or type. |
| Error | "I could not hear clearly" style message with alternatives. | Voice failed but the journey is not lost. | Retry voice or answer by text. |

### Main Journey

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Phase stepper at the beginning and first prompt/card. | The process is structured and starts with their goal. | Answer the first prompt. |
| Loading | Current phase remains visible while next card or AI message is fetched. | Irshad is processing the answer. | Wait, with no need to repeat input. |
| Success | Completed phases checked, active phase highlighted, next card shown. | Progress is being made through the 12 steps. | Continue answering. |
| Partial | Missing slot or incomplete phase message with a targeted follow-up question. | One more detail is needed before recommendations. | Provide the missing detail or choose "I do not know." |
| Error | Server error at the current phase, previous answers preserved. | The journey paused because connection or backend failed. | Retry the request or continue when server returns. |

### Dynamic Card Renderer

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Placeholder or current prompt area waiting for backend card. | Irshad is about to ask or show something. | Wait briefly. |
| Loading | Card skeleton or progress treatment after the 500ms threshold. | The backend is preparing the next card. | Wait without losing context. |
| Success | Rendered card matching backend type and phase. | This is the next useful step. | Answer, expand, save, mark, copy, or continue depending on card type. |
| Partial | Card with unavailable optional fields hidden and required prompt still clear. | The card can still be used even if not all metadata exists. | Answer the available prompt or retry if required content is missing. |
| Error | Unsupported or malformed card fallback message. | Irshad received something it cannot render cleanly. | Retry or continue with text support if backend provides a next prompt. |

### Business Profile Cards

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Profile sections with no filled values yet. | Irshad has not collected these details. | Answer the current question. |
| Loading | Field update animation or pending marker after answer submission. | Irshad is applying the new information. | Wait. |
| Success | Auto-filled activity, budget, founder, location, documents, or channel values. | The app understood and saved those details. | Review, continue, or correct. |
| Partial | Some fields filled, others marked missing or unknown. | The profile is useful but incomplete. | Fill missing details or leave unknown where allowed. |
| Error | Field could not update or session sync failed. | The latest answer may not have been saved. | Retry syncing or answer again. |

### Analysis And Recommendations

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Recommendation area not yet available and future phases pending. | Irshad needs more profile detail first. | Continue the journey. |
| Loading | "Analyzing your business" state with relevant checks in progress. | Irshad is matching activity, cost, license, approvals, and gaps. | Wait. |
| Success | Analysis summary, confidence, best license option, alternatives, cost estimate, and required approvals. | Irshad has a recommended path based on provided answers. | Expand details, compare alternatives, continue to banking/verification. |
| Partial | Recommendation includes missing or unverified items. | The path is useful but not fully confirmed. | Provide more info, continue with caveats, or verify. |
| Error | Analysis or recommendation failed message. | Irshad cannot generate this section right now. | Retry or return to previous phase. |

### Banking Recommendations

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Banking phase pending until license/profile inputs are ready. | Banks cannot be recommended yet. | Complete earlier steps. |
| Loading | Bank matching state. | Irshad is checking suitability. | Wait. |
| Success | Bank cards with suitability, minimum balance if known, requirements, next action, and verification status. | These are possible bank paths, not guaranteed approvals. | Save preferred bank or open details. |
| Partial | Some bank requirements marked unknown or unverified. | They may need to confirm details before acting. | Save, compare, or proceed to verification. |
| Error | Banking recommendations unavailable. | The app cannot show bank matches now. | Retry or continue to general checklist if available. |

### Authority Verification

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Verification phase pending. | Irshad has not checked live or knowledge-base facts yet. | Continue through analysis and recommendations. |
| Loading | Verification in progress. | Irshad is checking requirements and sources. | Wait. |
| Success | Verified facts with source status and official contact actions where available. | Some information is confirmed enough to rely on. | Open website, call, copy question, or continue. |
| Partial | Unverified requirement with authority name, contact route if known, and exact question to ask. | This item needs confirmation outside the app. | Copy the question or contact the authority. |
| Error | Verification failed message with no invented fallback facts. | Irshad could not verify live information. | Retry or continue with unverified labels. |

### Final Plan And Saved Plan

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | Final plan locked or unavailable until required phases complete. | More steps are needed before the roadmap is ready. | Continue journey. |
| Loading | Roadmap generation progress. | Irshad is assembling the plan. | Wait. |
| Success | Business summary, license, estimated cost, documents, approvals, banks, timeline, immediate next action, unverified items, and confidence. | They have a practical launch path. | Share, copy, save, or continue with assistant. |
| Partial | Final plan generated with gaps clearly marked. | The plan is actionable but certain items need confirmation. | Share with caveats, verify items, or complete missing answers. |
| Error | Final plan generation failed and session data remains available. | The journey data is not lost. | Retry final generation or copy available summary. |

## Pass 6: Flow Integrity

**Flow risks:**

| Risk | Where | Mitigation |
|------|-------|------------|
| User thinks this is a form instead of a conversation | Welcome and early journey | Lead with voice, short prompts, and auto-filling cards instead of dense input screens. |
| User gets lost in the 12 phases | Main journey | Keep compact phase progress visible, with active phase and completed phases always clear. |
| User overtrusts estimates | Analysis, license, banking, verification, final plan | Mark estimated, verified, unverified, and guidance-only information wherever it appears. |
| User assumes Irshad guarantees approval | Recommendations and final plan | Use trust language that frames recommendations as guidance and preserves review before action. |
| User cannot answer a government or business detail | Business details, documents, jurisdiction | Provide "I do not know," "AI will recommend," and follow-up question paths. |
| User is older or uncomfortable typing | Input moments | Keep voice primary, tap targets large, and text entry optional. |
| Backend latency makes the app feel broken | Every API transition | Preserve current context and show active loading after 500ms. |
| Dynamic card schema changes | Card renderer | Render known backend card types generically and show a recoverable fallback for unsupported cards. |
| Verification lacks a live source | Verification phase | Do not invent facts; show official contact route and exact question to ask. |
| Final plan feels overwhelming | Results and saved plan | Lead with immediate next action, then group details into summary sections. |

**Visibility decisions:**
- Must be visible: current phase, completed phase status, current prompt, input method, transcribed answer before submission, auto-filled business details, missing information, confidence, verification status, estimated/unverified labels, immediate next action, retry paths, share/copy actions.
- Can be implied: backend route names, raw session object, analytics events, card schema internals, exact classification rules, server-side recommendation logic, future feature flags.

**UX constraints:** The visual phase must preserve a calm Arabic-first, voice-first iOS experience for rural entrepreneurs; must never imply official submission, guaranteed approval, or locally hardcoded legal decision-making; and must keep the app's role as a thin renderer of backend-driven journey state.

---

## Visual Specifications

### Screen Model

**Welcome / Start**
- Purpose: introduce Irshad and capture the first business idea.
- Primary content: app name, short Arabic-first promise, one large microphone action, text fallback, and a few example prompts.
- Behavior: pressing microphone starts recording immediately; text fallback can start the same `/api/journey/start` flow.
- Empty and error handling: if speech permission fails, keep text fallback active; if backend start fails, preserve the entered goal and offer retry.

**Journey**
- Purpose: keep the guided conversation, phase progress, and auto-filling business profile in one continuous experience.
- Primary content: compact 12-phase stepper, latest AI prompt, user response area, dynamic card renderer, microphone/text input, and visible profile cards.
- Behavior: backend cards drive all questions and phase changes through `/api/journey/next`; the UI only renders the returned state.
- Progress behavior: completed phases show completion, current phase is emphasized, future phases are pending/locked without looking like errors.

**Results**
- Purpose: show analysis, license, banking, verification, and final roadmap outputs as the journey matures.
- Primary content: analysis summary, confidence, recommended license, alternatives, estimated costs, bank cards, verification card, and roadmap.
- Behavior: call existing PRD-defined endpoints as each phase becomes available: `/api/analyze`, `/api/license`, `/api/banking`, `/api/verify`, and `/api/plan/final`.
- Trust behavior: every recommendation section exposes verified, estimated, unverified, and guidance-only status where applicable.

**Saved Plan**
- Purpose: let the user return to a generated business launch plan.
- Primary content: business title, short summary, progress/checklist status, immediate next action, and continue/share actions.
- Behavior: saved plan opens into the final roadmap and allows continuing with the assistant when the user wants more help.

### Navigation And Flow

- The first screen starts with a single primary path: speak the business idea.
- The journey should feel continuous, not like switching between unrelated forms.
- The 12 phases are always represented in this order: Goal, Business, Founder, Details, Budget, Documents, Analysis, License, Banking, Verify, Next Steps, Plan.
- The user should not manually choose backend endpoints or phases; backend state decides the next card and available output.
- The back path should preserve context and avoid losing captured answers.
- Correction should be possible from filled profile values and relevant conversation entries.

### Component Specifications

**Phase Stepper**
- Shows all 12 phases in compact form.
- Completed phases display completion.
- Current phase is visually active.
- Future phases are pending or locked.
- Long phase labels may be shortened to the PRD labels: Goal, Business, Founder, Details, Budget, Documents, Analysis, License, Banking, Verify, Next Steps, Plan.

**Voice Control**
- Large, easy-to-reach microphone action.
- Distinct states: idle, listening, processing, transcript ready, failed.
- Includes waveform or equivalent active recording feedback.
- Supports retry without clearing the current question.

**Text Fallback**
- Available from every question state.
- Uses the same submit path as voice transcript confirmation.
- Does not replace voice as the primary interaction.

**AI Message**
- Short, respectful, simple Arabic-first copy.
- Avoids legal density.
- Can include English fallback only for development/testing support.
- Should not claim certainty beyond backend-provided status.

**Dynamic Card Renderer**
- Renders these backend-defined card types: `single_select`, `multi_select`, `text`, `number`, `toggle`, `checklist`, `info`, `summary`, `recommendation`, and `roadmap`.
- Uses backend labels, options, phase, title, subtitle, and slot without hardcoding business logic.
- Provides recoverable fallback for unsupported or malformed cards.

**Business Profile Cards**
- Show information filling itself as answers are collected.
- Group profile details by activity, founder, business details, budget, and documents.
- Mark missing and unknown fields clearly.
- Provide correction affordances without making the user feel they made a mistake.

**Recommendation Cards**
- Show best option first.
- Keep alternatives below or collapsed until needed.
- Include issuing authority, why recommended, estimated cost, timeline, approvals, pros/cons, confidence, and verification status when provided by backend.
- Use badges for statuses such as recommended, cheaper, needs approval, confirm fee, verified, estimated, and unverified.

**Verification Card**
- Separates verified facts from unverified requirements.
- Shows authority name, official contact page or phone only when provided by backend.
- Makes phone numbers tappable with platform phone behavior.
- Includes exact authority question to ask and a copy action.
- Never displays fake call progress or invented contact details.

**Next-Step Checklist**
- Shows a concrete ordered checklist after recommendations.
- Lets users mark items done locally.
- Includes copy/open actions for authority, bank, website, or map links when available.

**Final Roadmap**
- Groups the final plan into business summary, recommended license, estimated cost, required documents, approvals, banks, timeline, immediate next action, unverified items, and confidence.
- Provides share as PDF/text if supported by implementation and copy summary as a lower-friction fallback.
- Keeps guidance and uncertainty labels visible in shared content.

### Design System Direction

- Overall style: warm, rural-friendly, trustworthy, calm, and simple.
- Platform fit: native iOS patterns, Dynamic Type support, dark mode readiness, right-to-left layout support, and accessible tap targets.
- Composition: uncluttered screens with one dominant task at a time, progressive details, and clear action hierarchy.
- Cards: simple, readable, and status-rich; avoid dense legal paragraphs in the primary view.
- Motion: use gentle transitions for phase completion, card arrival, profile auto-fill, loading, and voice waveform; motion must clarify state rather than distract.
- Status language: use plain labels for verified, estimated, unverified, missing, unknown, and guidance.

### Interaction Specifications

- Voice flow: tap microphone, record, transcribe, allow edit, submit answer, show backend response, render next card.
- Text flow: type answer, submit, show backend response, render next card.
- Card answer flow: select or enter response, confirm when needed, send to backend, update session and visible profile.
- Loading flow: if backend response takes more than 500ms, show active progress while preserving current content.
- Correction flow: open the relevant field/card, provide corrected answer, send updated session to backend, update visible profile.
- Error flow: show specific error, keep previous session state, offer retry and fallback where possible.
- Share flow: generate or use final plan content, include uncertainty labels, open native share/copy behavior.

### Responsive And Accessibility Requirements

- Support iPhone-first portrait layouts.
- Support right-to-left Arabic layout for all primary journeys.
- Support large text without hiding primary actions or clipping phase/card content.
- Keep primary controls reachable in the middle or lower part of the screen where possible.
- Avoid requiring exact numeric input when ranges or unknown values satisfy the journey.
- Preserve voice-first operation for users who are less comfortable typing.
- Maintain clear contrast and plain language for older users.

### Interface Boundaries

- Keep the existing `baseURL` unchanged.
- Do not hardcode license, bank, authority, fee, or eligibility logic in the iOS UX.
- Do not invent new routes beyond the PRD routes: `/api/journey/start`, `/api/journey/next`, `/api/analyze`, `/api/license`, `/api/banking`, `/api/verify`, and `/api/plan/final`.
- Treat the backend session as the single source of truth for current phase, missing slots, cards, recommendations, and verification status.
- Analytics events are implementation details and should not appear as user-facing UI.

### Demo Acceptance Path

- User opens Irshad and starts with voice.
- User says: "I sell camel milk. I have AED 20,000. I want to start legally."
- The app transcribes and submits the goal.
- Business activity and budget cards begin filling automatically.
- Irshad asks follow-up questions for land, employees, sales channel, documents, and other missing details.
- Analysis appears with confidence and missing or unverified items.
- License recommendation appears with estimate and required approvals.
- Bank recommendation cards appear with suitability and requirements.
- Verification card identifies confirmed facts and authority questions for unresolved requirements.
- Final roadmap shows summary, license, cost, documents, banks, timeline, unverified items, confidence, and one immediate next action.
- User can share or copy the roadmap.
