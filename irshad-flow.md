# Awwal — Guided Adaptive Journey Spec (Swift ↔ Next.js)

**Model:** the journey follows a **defined path** (an ordered backbone of stages), but the AI adapts *within* it. The server is a journey engine: it walks the fixed stage backbone, and inside each collection stage it generates the specific questions that matter for *this* activity, skips what's irrelevant, and stops asking once the stage is satisfied. When all collection stages are done — the **completeness gate** — it runs the output stages (analyze → license → banking → verify → plan), each separate.

**Design choices this implements:**
- **Defined path:** a fixed stage backbone so the journey is predictable and grounded, not free-roaming.
- **Adaptive within the path:** the server picks the next question based on the idea + what's known. Different ideas → different questions, same backbone.
- **Thorough:** keeps collecting until every stage's required slots are filled before producing the plan.
- **License and banking are separate phases**, not one combined analysis.

**Stack:** SwiftUI client (thin renderer) · Next.js (journey engine + LLM + web_search) · KB (Track B) server-side only.

---

## Core idea: client is dumb, server drives — along a defined path

The client does not know the journey order. It does two things:
1. Render whatever card the server sends.
2. Send the updated session back and ask "what's next?"

But the server is **not** free-roaming. It follows a **defined path** (an ordered backbone of stages). Adaptivity happens *within* and *around* that path, not instead of it:

- The path gives a predictable spine — the journey always moves through the same stages in the same order.
- **Adaptive within a stage:** inside each stage the AI generates the specific question(s) for *this* activity (a stargazing business gets land/hosting questions; a home-food business gets kitchen/food-safety questions).
- **Adaptive skipping:** a stage whose info is already known or irrelevant to this activity is skipped automatically.
- The path is a default, not a cage: the server can ask an extra question a stage didn't anticipate, but it can't wander off the backbone.

### The defined path (backbone)

```
STAGE 1  goal        → capture + classify the idea
STAGE 2  business    → activity details (adaptive questions here)
STAGE 3  founder     → individual/team, residency, existing business, language
STAGE 4  details     → location, jurisdiction pref, channel, office need
STAGE 5  budget      → capital, revenue, employees, growth
STAGE 6  documents   → IDs, assets, permits held vs needed
   ── completeness gate ──
STAGE 7  analyze     → match activity + setup cost + confidence (grounded)
STAGE 8  verify      → web-search the matched option's live facts; if not found, give number to call
STAGE 9  license     → license recommendations (grounded in verified data, separate)
STAGE 10 banking     → banking recommendations (separate)
STAGE 11 plan        → final roadmap + export
```

The server tracks `currentStage`. Within stages 2–6 it loops adaptively (asking only the questions that matter for this activity) before advancing. Stages 7–11 are output stages, each its own phase. **Verify runs before license** so the license card is presented with web-confirmed costs/requirements, not stale KB guesses. This is what "grounded path" means: the AI is free to be smart *inside* a known structure.

```
loop (collection stages 2–6):
  client → POST /api/journey/next  (full session)
  server → { stage, card }  OR  { stage advanced }  OR  { status: "gate_open" }
  if gate_open → run output stages in order: analyze → verify → license → banking → plan
  else render card, collect answer, loop
```


---

## The Session object (single source of truth)

```json
{
  "sessionId": "uuid",
  "goalText": "raw idea in the founder's words",
  "currentStage": "business",
  "filledSlots": {
    "activity": "Desert/astro tourism (overnight, private land)",
    "stage": "idea",
    "founderType": "individual",
    "residency": "citizen",
    "location": "Al Qua'a (rural Abu Dhabi)",
    "jurisdictionPref": "none",
    "channel": "inperson",
    "capital": "10k-50k",
    "employees": 0,
    "assets": ["land"],
    "docs": ["Emirates ID", "Passport"]
  },
  "history": [
    { "cardId": "q_activity_detail", "question": "...", "answer": "..." }
  ]
}
```

`filledSlots` is whatever's known so far. `history` is the full Q&A trail (also your evidence/debug log).

---

## The required-slots checklist (the completeness gate)

The server holds, per activity archetype (from KB), the slots that **must** be filled before analysis — organized by which stage owns them. The path walks the stages in order; within each collection stage the gate checks that stage's required slots are filled before advancing to the next stage. Example for astro-tourism:

```
STAGE 2 business:  [ activity, stage, hostingType, landOwnership ]   ← adaptive, activity-specific
STAGE 3 founder:   [ founderType, residency, hasExistingBusiness, language ]
STAGE 4 details:   [ location, jurisdictionPref, channel, needsOffice ]
STAGE 5 budget:    [ capital, expectedRevenue, employees, growth ]
STAGE 6 documents: [ docs, assets, permitsHeld ]
```

A home-food business swaps stage 2's slots for `[ activity, stage, kitchenType, foodSafetyReg ]` — same path, different stage-2 questions. That's the adaptivity, now contained within a defined backbone.

**The overall gate opens** when every stage's required slots are filled. The server advances stage-by-stage; it does not jump to analysis mid-path.

**Guardrails (important for a stable demo):**
- **Hard cap:** max N questions total (e.g., 8). If cap hit, open the gate anyway and mark empties as `assumed`/`unverified`. Prevents infinite loops on stage.
- **Min floor:** never analyze before the core slots (activity, residency, location, capital) are filled.
- **Stage order is fixed:** the server can't skip ahead to a later stage while an earlier stage's core slots are empty — only skip a stage that's fully satisfied or irrelevant.

---

## PHASE A — Start

**Client sends** → `POST /api/journey/start`
```json
{ "sessionId": "uuid", "goalText": "I want to take tourists stargazing on my land" }
```
**Server does:** LLM classifies goal → activity archetype (constrained to KB list); seeds `filledSlots.activity`; loads that archetype's required-slots checklist.
**Server returns:**
```json
{
  "framing": "Got it — a desert stargazing experience business.",
  "activity": "Desert/astro tourism",
  "card": { /* first card, see card schema below */ }
}
```
**Client then:** shows framing, renders the first card.

---

## PHASE B — The adaptive loop (repeats)

**Client sends** → `POST /api/journey/next`
```json
{ "sessionId": "uuid", "session": { /* full session incl. latest answer */ } }
```
**Server does (each turn):**
1. Update `filledSlots` with the latest answer.
2. Check required slots vs filled. Compute what's missing/ambiguous.
3. If something's missing AND under the question cap → LLM generates the **single next best card**, targeted at the most important missing slot, phrased for this specific activity. (Adaptivity lives here.)
4. If all required filled (or cap hit) → return `status: "ready"`.

**Server returns — still collecting:**
```json
{
  "status": "collecting",
  "currentStage": "business",
  "progress": { "filled": 7, "required": 11, "stagesDone": 1, "stagesTotal": 6 },
  "card": {
    "cardId": "q_land_ownership",
    "kind": "question",
    "type": "single_select",
    "title": "Do you own the land or use public desert?",
    "options": ["Own land", "Public desert"],
    "slot": "landOwnership",
    "stage": "business"
  }
}
```

**Server returns — stage advanced (optional signal for the UI):**
```json
{ "status": "collecting", "currentStage": "founder", "stageJustCompleted": "business", "card": { /* first founder card */ } }
```

**Server returns — gate open (all stages satisfied):**
```json
{ "status": "gate_open", "progress": { "filled": 11, "required": 11, "stagesDone": 6, "stagesTotal": 6 } }
```

**Client then:**
- If `collecting` → render the card by `type`, collect answer, append to session, loop. Use `currentStage` to show which stage of the backbone the user is in (e.g., a stepper: Business · Founder · Details · Budget · Documents).
- If `gate_open` → stop looping, begin the output stages in order: call `/api/analyze`, then `/api/verify`, then `/api/license`, then `/api/banking`, then `/api/plan/final`.

### Card schema (so Swift can render anything without knowing the journey)
```json
{
  "cardId": "string",
  "kind": "question | confirmation | info",
  "type": "single_select | multi_select | text | toggle | none",
  "title": "string",
  "subtitle": "string (optional)",
  "options": ["..."],          // for selects
  "slot": "which slot this fills"
}
```
The client renders purely off `kind` + `type`. Server can introduce new cards without a client change.

**Progress bar** uses `progress.filled / progress.required` for fine-grained progress, and `stagesDone / stagesTotal` for the backbone stepper — adaptive within stages, but the user always sees the defined path.

---

## PHASE C — Analysis (gate passed)

**Client sends** → `POST /api/analyze`
```json
{ "sessionId": "uuid", "session": { /* complete profile */ } }
```
**Server does:** pull KB records for the matched activity → grounding prompt (KB facts only, no invented licenses/fees, "not verified" for gaps) → match suitable activities, estimate setup cost, compute confidence = verified/required. **Analysis only — license and banking are their own phases.**
**Server returns:**
```json
{
  "analysis": {
    "matchedActivities": [{ "id": "astro_tourism", "label": "Desert/astro tourism (overnight, private land)" }],
    "estSetupCostRange": "AED ___ – ___",
    "candidateLicenses": ["Tourism activity license", "Tajer Abu Dhabi"],
    "confidence": 0.82,
    "unverified": ["exact tourism permit fee"]
  },
  "nextStage": "verify"
}
```
**Client then:** show an analysis summary card, proceed to Phase D (verify). `candidateLicenses` tells verify what live facts to confirm before license recommendations are built.

---

## PHASE D — Verification (runs BEFORE license; web-search first; if not found, give the founder the number to call)

**Verify comes before license on purpose:** it confirms the live facts (fees, requirements, approvals) for the candidate license option(s) so the license card is presented with web-confirmed data, not stale KB guesses. **The AI never calls anyone.** It web-searches to confirm the fact. If it can't confirm online, it shows the founder the relevant authority's name + phone number and tells them to call to confirm. No autonomous dialing, no script generation, no simulated call.

**Client sends** → `POST /api/verify`
```json
{ "sessionId": "uuid", "verifyTarget": "tourism activity license fee + requirements 2026" }
```
**Server does:** `web_search` the volatile fact for the best candidate license. (To save time/calls, verify only the best candidate's critical facts — license fee + required approvals — not every option.)
**Returns — found:**
```json
{ "status": "verified", "info": "...", "verifiedFacts": { "licenseFee": "AED ___", "approvals": ["..."] }, "sources": ["dctabudhabi.ae"], "nextStage": "license" }
```
**Returns — not found:**
```json
{
  "status": "not_found",
  "authority": "DCT Abu Dhabi",
  "phone": "+971 2 ___ ____",
  "whatToConfirm": "exact tourism permit fee for overnight desert hosting",
  "message": "I couldn't confirm this online. Call DCT Abu Dhabi to verify.",
  "nextStage": "license"
}
```
**Client then:** if `verified` → show the confirmed info + sources briefly, proceed to Phase C2 (license) where the verified facts are now used. If `not_found` → show a card with the authority name, the phone number as a tappable `tel:` link, and what to ask, then still proceed to license (which will display the KB figure marked "not verified — confirm by phone"). The **user** places any call; the app does nothing further. There is no `/api/verify/call` endpoint.

**Phone numbers come from the KB.** Each authority record in Track B needs a real, verified `phone` field (ADDED, DCT Abu Dhabi, ADAFSA, etc.). If a verified number isn't available, return the authority's official contact-page URL instead of guessing a number — never fabricate a phone number.

**Why this is a scoring win:** the license card a judge sees now shows *verified* costs with live sources; where unconfirmed, it honestly says "confirm by phone" with a real number. "We web-search to confirm live requirements, and where we can't, we point the founder to the exact authority and number" is an honest, falsifiable design. Frame it that way to judges.

---

## PHASE C2 — License Recommendations (separate; uses verified facts)

**Client sends** → `POST /api/license`
```json
{ "sessionId": "uuid" }
```
**Server does:** from the matched activity + founder eligibility, pull license options from the KB, **overlaying the verified facts from Phase D** where available. Grounding + "not verified" rule. Best option + alternatives with pros/cons/timeline/approvals.
**Server returns:**
```json
{
  "license": {
    "best": {
      "type": "Tourism activity license",
      "issuer": "DCT Abu Dhabi",
      "pros": ["Covers guest-hosting legally"],
      "cons": ["Needs activity approval"],
      "timeline": "2–4 weeks",
      "approvals": ["DCT activity approval"],
      "estCost": "AED ___",
      "costStatus": "verified | not_verified_confirm_by_phone",
      "source": "dctabudhabi.ae"
    },
    "alternatives": [
      { "type": "Tajer Abu Dhabi", "issuer": "ADDED", "pros": ["Low cost, phone-based"], "cons": ["May not cover hosting"], "estCost": "AED ___", "source": "added.gov.ae" }
    ]
  },
  "nextStage": "banking"
}
```
**Client then:** hero card — best license prominent with `costStatus` shown (verified badge or "confirm by phone"), alternatives below; proceed to Phase C3 (banking).

---

## PHASE C3 — Banking Recommendations (separate)

**Client sends** → `POST /api/banking`
```json
{ "sessionId": "uuid" }
```
**Server does:** match founder profile (residency, capital, activity, chosen license) to KB bank records. Grounding + "not verified" for any figure not in the KB (bank minimums change — don't invent).
**Server returns:**
```json
{
  "banking": {
    "banks": [
      { "name": "___ Bank", "minBalance": "AED ___", "requirements": ["Trade license", "Emirates ID"], "docsNeeded": ["..."], "likelyToApprove": true, "source": "..." }
    ]
  },
  "nextStage": "plan"
}
```
**Client then:** list banks; proceed to Phase E (plan).

---

## PHASE E — Launch Plan

**Client sends** → `POST /api/plan/final`
```json
{ "sessionId": "uuid" }
```
**Server does:** assemble license + banking + verification into one roadmap; total cost + timeline; carry confidence + unverified through.
**Server returns:**
```json
{
  "plan": {
    "roadmap": ["Apply for tourism license", "Open business account", "Get first booking"],
    "totalEstCost": "AED ___",
    "totalTimeline": "4–6 weeks",
    "nextAction": "Apply for the tourism activity license via DCT Abu Dhabi — start today.",
    "confidence": 0.82,
    "unverified": ["exact permit fee"]
  }
}
```
**Client then:** render roadmap, enable Download/Share + "Continue with AI" grounded chat.

---

## Route table

| Phase | Route | Purpose |
|------|-------|---------|
| A | `POST /api/journey/start` | classify idea → activity, load checklist, enter STAGE 1, first card |
| B | `POST /api/journey/next` | the loop along stages 2–6: next card / advance stage / `gate_open` |
| C | `POST /api/analyze` | grounded match + setup cost + candidate licenses + confidence |
| D | `POST /api/verify` | web-search the candidate license's live facts; if not found, return authority name + phone |
| C2 | `POST /api/license` | license recommendations, overlaid with verified facts (separate) |
| C3 | `POST /api/banking` | banking recommendations (separate) |
| E | `POST /api/plan/final` | final roadmap + export |

The journey is **start → next×K (along the defined stage path) → analyze → verify → license → banking → plan.** K is decided by the server within the backbone; the backbone order is fixed.

---

## Server journey engine — pseudo logic

```
PATH = [goal, business, founder, details, budget, documents]   // fixed backbone

on /journey/next(session):
  updateFilledSlots(session)
  stage   = session.currentStage
  reqs    = checklistFor(session.activity, stage)   // this stage's required slots
  missing = reqs - filled(session)

  if session.history.length >= CAP:                 // guardrail: stop looping
     return { status: "gate_open" }

  if missing.isEmpty:                               // this stage done
     nextStage = advance(PATH, stage)
     if nextStage == null:                          // all collection stages done
        return { status: "gate_open" }
     session.currentStage = nextStage
     // immediately produce first card of next stage (or skip if that stage's slots already known/irrelevant)
     return firstCardOf(nextStage, session)

  if !coreFilled(session):                          // floor guardrail
     nextSlot = pickCore(missing)
  else:
     nextSlot = pickMostImportant(missing)          // adaptive choice WITHIN the stage

  card = llmGenerateCard(nextSlot, session.activity, stage, knownContext)
  return { status: "collecting", currentStage: stage, card }
```

Adaptive lives in `pickMostImportant` + `llmGenerateCard` (which question, phrased for this activity). The **path** is enforced by `PATH` + `advance()` — the spine never changes order.

---

## Build order / parallelization

1. **Together (first hour):** freeze the Session object, the card schema, the **stage backbone (PATH)**, and the per-stage required-slots checklist for **one** activity (your demo persona's). Everything builds off these.
2. **Next.js:** implement `/journey/start` + `/journey/next` with the PATH walker + per-stage checklists + cap/floor guardrails. Stub `analyze / license / banking / verify / plan` with mock JSON first.
3. **Swift:** build the generic card renderer (handles all `kind`+`type` combos) + the loop + the **stage stepper** (Business · Founder · Details · Budget · Documents) against mock cards. The renderer + stepper is the whole client.
4. **Next.js:** wire real LLM card-generation + KB grounding as Track B lands. Start with one activity end to end through the full path.
5. Add `web_search` to verify. Test the `not_found` branch — confirm it returns the authority's real phone (from KB) and the client shows it as a tappable `tel:` link. The AI never calls.
6. Polish analysis → license → banking → plan screens. Rehearse the demo persona's exact path.

## MVP
- `start → next-loop (full stage path) → analyze → verify → license → plan` working on a real iPhone for **one** activity, with the generic card renderer, the stage stepper, and the completeness gate functioning.
- `banking` is a strong add; lighten if time runs short. The `verify` web-search (on the candidate license's fee) is the wow moment and feeds the license card — keep it.
- The headline is the adaptive loop visibly asking *activity-specific* questions **inside a clear, defined path** — the user always sees the backbone (stepper) while the questions adapt. Make sure your demo persona triggers at least 2 questions a different business wouldn't get.

## Demo-safety reminders (adaptive is riskier live)
- **Cap the questions** so it can never loop forever on stage.
- **Rehearse the exact persona** so you know which cards appear.
- **Grounding test:** run a fake/unknown business through it and confirm analysis returns "not verified" instead of inventing — judges may try this.
- Keep one **fallback persona** that you know produces a clean full run, in case the live input wanders.
