<!-- =============================================================== -->
<!--  HERO WORDMARK                                                  -->
<!--  IMAGE PLACEHOLDER → assets/hero-wordmark.png                   -->
<!--  Description: Full-bleed banner. Deep midnight-indigo (#0B1437) -->
<!--  night sky fading to signal-blue, faint star field (a nod to   -->
<!--  Al Qua'a's stargazing skies). Centered: the Arabic wordmark    -->
<!--  "إرشاد" large in Bricolage Grotesque, with "IRSHAD" beneath in  -->
<!--  tracked-out caps, and a single bright guiding-star ✦ above the  -->
<!--  dot of the letterform. Tagline underneath in star-white.       -->
<!-- =============================================================== -->

<div align="center">

<img src="assets/hero-wordmark.png" alt="Irshad — إرشاد" width="100%" />

# إرشاد · Irshad

**An Arabic, voice-first AI guide that walks a first-time rural founder from “I have an idea” to “here is my first action” — without a single form.**

<sub>✦ &nbsp; Tatweer Hackathon 2026 &nbsp;·&nbsp; Al Qua'a, Al Ain, UAE &nbsp;·&nbsp; Challenge 1 — Taking the First Entrepreneurial Step &nbsp; ✦</sub>

<br/>

`SwiftUI iOS` &nbsp;•&nbsp; `Next.js journey engine` &nbsp;•&nbsp; `Grounded Abu Dhabi knowledge base` &nbsp;•&nbsp; `Arabic + English`

</div>

---

<div align="center"><sub>THE SITUATION</sub></div>

## ✦ &nbsp; Ahmed already has the business. He just can't start it.

> Ahmed is 55. He has kept camels in Al Qua'a his whole life, and his milk is good enough that neighbours already pay for it. He has **AED 20,000** set aside and a real idea: sell camel milk, legally.
>
> He does not know which **licence** he needs. Or which **authority** issues it. Or whether a **bank** will open an account for him. Or what it will **cost**. Or **who to call**. So the idea stays an idea — not for lack of ambition, but for lack of a first move.

Ahmed is not unusual. Across Al Qua'a — a dispersed rural community on the Tropic of Cancer, where many families live off camel farms — the barrier to entrepreneurship is almost never the idea. It is the **invisible procedural wall** between an idea and a registered business: licences, jurisdictions, approvals, documents, eligibility, banking. The knowledge exists, but it is scattered across government portals, written for people who already know the system, and rarely in plain spoken Arabic.

> **Challenge 1 — Taking the first entrepreneurial step.** *“Many people here have a viable idea or a real skill but never take the first step… The barrier is rarely ambition, it is not knowing what the first move is, what is required, or where to begin.”*

This is the specific problem we chose, and the exact person we built for.

---

<div align="center"><sub>WHO WE BUILT FOR</sub></div>

## ✦ &nbsp; The target demographic

| | |
|---|---|
| **Primary** | A first-time founder in a rural UAE community who has an idea or a skill but has never registered a business — and does not know the legal, banking, or government process. |
| **Their reality** | Often more comfortable **speaking Arabic than filling English web forms**; on a phone, not a laptop; on patchy connectivity; with modest starting capital. |
| **The livelihoods** | Camel milk & dairy, dates & honey, home food, tailoring / henna / craft, livestock services, small retail, repair services, tutoring — and the local headline act: **desert & astro-tourism** under Al Qua'a's famously dark skies. |

We encoded these as **11 real business archetypes** (see [the knowledge base](#-the-evidence-the-knowledge-base)) so the guidance is shaped to *this* community's actual economy — not a generic “start a company” wizard.

---

<div align="center"><sub>THE SOLUTION</sub></div>

## ✦ &nbsp; Irshad — guidance, by conversation

The name **إرشاد (irshād)** means *guidance* — and in a place known for its night sky, we took that literally. Irshad is a guide you **talk to**. You say your idea out loud in Arabic; it asks a handful of simple, spoken questions; and it fills in the business profile *for* you. No forms, no jargon, no dead ends.

Underneath the conversation is the idea that makes Irshad work as a **product, not a chatbot**:

> ### A *defined path*, with an AI that adapts *inside* it.
>
> The journey always follows the same ordered backbone of stages — so it is predictable, grounded, and demo-stable. But **within** each stage the AI generates the questions that matter for *this* activity, skips what is irrelevant, and stops asking once the stage is satisfied. A stargazing host gets land & hosting questions; a home-food cook gets kitchen & food-safety questions. **Same path, different questions.**

The client is deliberately “dumb”: a thin SwiftUI renderer that draws whatever card the server sends and asks *“what’s next?”*. All the intelligence — the path, the adaptive questioning, the grounding — lives server-side, so guidance improves without shipping a new app.

<!-- =============================================================== -->
<!--  APP FLOW — 3-UP SCREENSHOTS                                     -->
<!--  IMAGE PLACEHOLDER → assets/flow-3up.png                         -->
<!--  Description: Three iPhone frames side by side on the indigo→blue -->
<!--  gradient. (1) The voice/idea screen: a glowing radial audio orb  -->
<!--  mid-listen with an Arabic prompt. (2) An adaptive question card  -->
<!--  ("Do you own the land or use public desert?") with a stage       -->
<!--  stepper across the top (Business · Founder · Details · Budget ·  -->
<!--  Documents). (3) The final roadmap with a green "verified" badge, -->
<!--  an amber "confirm by phone" badge, and a tappable phone number.  -->
<!-- =============================================================== -->

<div align="center">
<img src="assets/flow-3up.png" alt="Speak an idea → adaptive cards fill the profile → grounded roadmap" width="100%" />
<br/><sub>Speak an idea &nbsp;→&nbsp; adaptive cards fill the profile &nbsp;→&nbsp; a grounded launch roadmap</sub>
</div>

### The journey — an 11-stage path you navigate like stars

The server walks a fixed backbone. Stages **1–6 collect** (adaptive questions). A **completeness gate** then opens, and stages **7–11 produce** the plan — each its own honest step. Because the journey *is* a real ordered sequence, the numbers below mean something; they are not decoration.

```
        COLLECT  ─ adaptive within each stage ───────────────────────────────────

   ✦ 01  GOAL ........... say the idea aloud → AI classifies it to an archetype
   │
   ✦ 02  BUSINESS ....... activity details   ← questions specific to THIS activity
   │
   ✦ 03  FOUNDER ........ individual/team, residency, existing business, language
   │
   ✦ 04  DETAILS ........ location, jurisdiction, sales channel, office need
   │
   ✦ 05  BUDGET ......... capital, revenue, employees, growth
   │
   ✦ 06  DOCUMENTS ...... IDs, assets, permits held vs. needed
   │
   ═════ COMPLETENESS GATE ═══ all required slots filled → produce the plan ══════
   │
   ✦ 07  ANALYZE ........ match activity + estimate setup cost + confidence score
   │
   ✦ 08  VERIFY ......... confirm the live facts; if unsure, hand over the real
   │                      authority's name + phone instead of guessing
   ✦ 09  LICENSE ........ best licence + alternatives (pros, cons, timeline, cost)
   │
   ✦ 10  BANKING ........ banks matched to the founder's profile & eligibility
   │
   ✦ 11  PLAN ........... one roadmap, total cost, total timeline, next action
```

Two guardrails keep it stable and honest in a live demo: a **hard cap of 8 questions** (it can never loop forever), and a **floor** that refuses to analyse before the four core slots — `activity`, `residency`, `location`, `capital` — are known.

---

<div align="center"><sub>WHY YOU CAN TRUST WHAT IT SAYS</sub></div>

## ✦ &nbsp; It is grounded, and it admits what it doesn't know

An AI that confidently invents a licence fee is worse than useless to Ahmed — it is dangerous. So Irshad is built to be **falsifiable on screen**. Every figure it shows carries a trust label, and the agent is prompted **never to invent** a licence, a fee, or a phone number.

| Label | Meaning | Shown when |
|:--|:--|:--|
| ● **Verified** | Confirmed against a source | the fact was confirmed in the verify step |
| ● **Estimated** | A range grounded in the KB | KB gives a range, not an exact figure |
| ● **Unverified — confirm by phone** | Honest gap | the agent could not confirm it → it shows the **real authority + number to call** |
| ● **Missing** | Not yet known | a required slot is still empty |

The agent **never calls anyone**. When it can't confirm a fact online, it does the honest thing: it surfaces the relevant authority's real name and phone number as a tappable `tel:` link and tells the founder exactly what to ask. *The founder stays in control; the app never fabricates and never auto-dials.*

> A judge can break this on purpose: feed Irshad a fake or unknown business and it returns **“not verified”** instead of inventing one. That failure mode is the feature.

---

<div align="center"><sub>THE IMPACT, AS TESTABLE CLAIMS</sub></div>

## ✦ &nbsp; Impact — and how to falsify each claim

We state these as **specific, checkable claims**, not hype. Each one can be verified from this repository or a 5-minute run.

| # | Claim | How to test it |
|:--|:--|:--|
| 1 | **Two founders with different ideas get different questions** along the same path. | Run the journey with *“stargazing on my land”* vs *“sell camel milk”*; compare the Stage-2 cards. They differ (land/hosting vs kitchen/food-safety). |
| 2 | **Idea → action plan in ≤ 8 questions.** The path can never exceed an 8-question cap. | `Backend/lib/journey.ts` → `MAX_QUESTIONS = 8`. Run any persona to a finished roadmap. |
| 3 | **Every shown fact is traceable to a dated source**, or labelled unverified. | `Backend/kb/knowledge.json` carries `last_verified: 2026-06-26`; each authority has a `source_url`. |
| 4 | **The agent will not invent a licence, fee, or phone number.** | Read the grounding prompts in `Backend/lib/llm.ts`; feed an unknown business and watch it return `not_verified` / `not_found`. |
| 5 | **It speaks the founder's language.** Full Arabic (RTL) and English, voice in and out. | Switch language; values come back in Arabic. Voice via Apple Speech + `AVSpeechSynthesizer`. |
| 6 | **It runs on the hardware the community actually has** — one iPhone, one server. | Follow [How to run](#-how-to-run--verify); end-to-end on an iOS 16+ device. |

**The benefit, plainly:** a first-time founder who today would stall — or pay an agent to navigate the process — instead leaves with a named licence, the issuing authority, a cost range, candidate banks, the documents required, and a single concrete next action. That is the gap between an idea and a business, closed in one conversation.

---

<div align="center"><sub>THE EVIDENCE</sub></div>

## ✦ &nbsp; The knowledge base

Irshad’s honesty is only as good as what it stands on. We hand-built a **verified Abu Dhabi business-setup knowledge base** focused on Al Qua'a / Al Ain, dated and sourced. This is the repo's most checkable artifact — open `Backend/kb/knowledge.json` and count.

<div align="center">

| Records | Count | Each carries |
|:--|:--:|:--|
| Government authorities | **7** | real phone, email, website, **source URL** |
| Licence types | **6** | issuer, eligibility, cost basis |
| Banks | **6** | min balance basis, requirements, docs |
| Loan products | **5** | eligibility & terms |
| Government funds & programs | **10** | who they support |
| Business archetypes | **11** | activity-specific required-slots checklist |

</div>

Real authorities, with real numbers: **ADRA / ADDED**, **ADAFSA**, **DCT Abu Dhabi**, **Khalifa Fund**, **EDB**, **ADIO**, **Ma'an** — the actual bodies a rural founder in Abu Dhabi must deal with. The 11 archetypes (astro-tourism, camel dairy, dates/honey, home food, tailoring/henna/craft, livestock services, retail, AgriTech, freelance, repair, tutoring) are drawn straight from Al Qua'a's livelihoods.

---

<div align="center"><sub>FEASIBILITY · DEPLOYMENT · SCALE</sub></div>

## ✦ &nbsp; Built to deploy, designed to replicate

**Feasibility — it is realistic to run, today.** The whole system is a thin SwiftUI client plus one stateless Next.js server and a JSON knowledge base. No GPU, no heavy infra, no per-user database to maintain. The LLM runs through **OpenRouter** (model swappable; default `google/gemini-2.5-flash-lite`) — so inference is a low, per-call cost, not a fixed server bill. Maintenance is mostly *keeping the KB current*, which is a content task a non-engineer can do by editing one file.

**Deployment.** The backend deploys to any Node host (Vercel/Render/a single VM) in minutes; the iOS app distributes via TestFlight / the App Store. A community organisation could stand up its own instance without a dedicated platform team.

**Scalability beyond the event — this is the part we designed for.**

```
   Al Qua'a today              Any rural community tomorrow
   ───────────                 ────────────────────────────
   Abu Dhabi KB        ──►     swap knowledge.json per emirate / region
   11 archetypes       ──►     add an archetype = add one checklist entry
   thin client         ──►     same app, new server, no resubmission
   server-driven path  ──►     improve guidance for everyone, instantly
```

Because the client knows *nothing* about the journey, the entire product can be re-pointed at a new community by **editing data, not code**. The defined-path engine, the trust-label system, the voice layer, and the card renderer are all community-agnostic. Al Qua'a is the first map; the navigator is reusable.

---

<div align="center"><sub>UNDER THE HOOD</sub></div>

## ✦ &nbsp; Architecture & tools

```
   ┌──────────────────────────────┐         ┌────────────────────────────────────┐
   │   iOS · SwiftUI (thin client)│  HTTPS  │      Next.js · journey engine        │
   │                              │ ◄─────► │                                      │
   │  • voice in/out (Apple       │  JSON   │  /journey/start   classify idea      │
   │    Speech + AVSpeechSynth)   │  cards  │  /journey/next    adaptive loop      │
   │  • generic card renderer     │         │  /analyze /verify /license           │
   │  • stage stepper + progress  │         │  /banking /plan/final                │
   │  • trust-label UI            │         │                ▲                     │
   └──────────────────────────────┘         │                │ grounded prompts    │
                                            │     ┌──────────┴──────────┐          │
                                            │     │  LLM (OpenRouter)   │          │
                                            │     └──────────┬──────────┘          │
                                            │     ┌──────────┴──────────┐          │
                                            │     │ knowledge.json (KB) │ sources  │
                                            │     └─────────────────────┘          │
                                            └────────────────────────────────────┘
```

| Layer | Tools |
|:--|:--|
| **Client** | Swift 5.9, SwiftUI, iOS 16+, Apple Speech & `AVSpeechSynthesizer`, **Bricolage Grotesque** type, full RTL / Dynamic Type / VoiceOver / reduced-motion support |
| **Server** | Next.js (App Router), TypeScript, Route Handlers |
| **Intelligence** | OpenRouter LLM (default `google/gemini-2.5-flash-lite`), strict JSON, grounding + “not-verified” prompting |
| **Knowledge** | Hand-curated, sourced `knowledge.json` (Abu Dhabi / Al Qua'a) |

---

<div align="center"><sub>RUN IT YOURSELF</sub></div>

## ✦ &nbsp; How to run & verify

**1 — Backend (the journey engine)**

```bash
cd Backend
cp .env.local.example .env.local      # add OPENROUTER_API_KEY
npm install
npm run dev                           # serves the API on http://localhost:3000
```

Smoke-test the path with no app at all:

```bash
curl -X POST http://localhost:3000/api/journey/start \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"demo","goalText":"I want to take tourists stargazing on my land"}'
```

**2 — iOS app (the experience)**

```text
1. Open  App/Irshad/  in Xcode 15+
2. Set   AppConfig.baseURL  to your running backend
3. Select an iOS 16+ simulator or device → Run (⌘R)
4. Speak an idea in Arabic and follow the guided path to a roadmap
```

**3 — Verify the claims** &nbsp;→&nbsp; see the [falsifiable-claims table](#--impact--and-how-to-falsify-each-claim). The fastest checks: open `Backend/kb/knowledge.json` (counts, sources, `last_verified`), read the grounding prompts in `Backend/lib/llm.ts`, and confirm the 8-question cap in `Backend/lib/journey.ts`.

<!-- =============================================================== -->
<!--  DEMO VIDEO                                                      -->
<!--  IMAGE PLACEHOLDER → assets/demo-thumb.png  (links to video)     -->
<!--  Description: A clean video poster frame — an iPhone held in a    -->
<!--  hand outdoors in daylight (rural/desert), Irshad on screen mid- -->
<!--  conversation, a large centered ✦ play button. Caption: the full -->
<!--  Ahmed run, idea → roadmap, in under two minutes.                -->
<!-- =============================================================== -->

<div align="center">

### ✦ &nbsp; Watch the full run

[<img src="assets/demo-thumb.png" alt="Watch Irshad guide Ahmed from idea to launch roadmap" width="70%" />](#)

<sub>▶ &nbsp; Ahmed’s idea → a grounded launch roadmap, end to end &nbsp;·&nbsp; ~2 min</sub>

</div>

---

<div align="center">

<sub>BUILT FOR</sub>

**Tatweer Hackathon 2026** &nbsp;·&nbsp; Al Qua'a, Al Ain, UAE &nbsp;·&nbsp; Challenge 1

<sub>Repository: [AbdullahSWE/Irshad_TatweerHackathon](https://github.com/AbdullahSWE/Irshad_TatweerHackathon) &nbsp;·&nbsp; built by Abdullah & Rudra</sub>

✦

*Irshad — إرشاد. Guidance, for the first step.*

</div>
