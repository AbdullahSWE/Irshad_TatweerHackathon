import OpenAI from 'openai';
import { getArchetypeList, getAuthority, getLicensesForArchetype, formatLicensesForLLM, formatBanksForLLM, formatFundingForLLM } from './kb';
import type {
  Session,
  Card,
  CollectionStage,
  AnalysisResult,
  VerifyResult,
  LicenseResult,
  BankingResult,
  PlanResult,
  SupportedLang,
} from './types';

const client = new OpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
  defaultHeaders: {
    'HTTP-Referer': 'https://irshad.app',
    'X-Title': 'Irshad',
  },
});

const MODEL = process.env.OPENROUTER_MODEL ?? 'google/gemini-2.5-flash-lite';

function langInstruction(lang: SupportedLang): string {
  return lang === 'ar'
    ? 'IMPORTANT: All human-readable text values in the JSON must be in Arabic (العربية). JSON field names stay in English. Numbers and codes stay as-is.'
    : 'Respond in English.';
}

async function llmJSON<T>(system: string, user: string, lang: SupportedLang = 'en'): Promise<T> {
  const res = await client.chat.completions.create({
    model: MODEL,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: `${system}\n\n${langInstruction(lang)}` },
      { role: 'user', content: user },
    ],
  });
  const text = res.choices[0].message.content ?? '{}';
  return JSON.parse(text) as T;
}

function profileSummary(filledSlots: Record<string, unknown>): string {
  return Object.entries(filledSlots)
    .filter(([, v]) => v !== undefined && v !== null && v !== '')
    .map(([k, v]) => `${k}: ${Array.isArray(v) ? (v as string[]).join(', ') : v}`)
    .join('\n');
}

export async function classifyGoal(goalText: string, lang: SupportedLang = 'en'): Promise<{
  archetypeId: string;
  archetypeLabel: string;
  framing: string;
}> {
  return llmJSON(
    'You are a business activity classifier for Abu Dhabi entrepreneurs. Return only valid JSON.',
    `Classify this founder's goal to the best matching archetype.

Archetypes:
${getArchetypeList()}

Founder goal: "${goalText}"

Return JSON:
{
  "archetypeId": "<exact id from list>",
  "archetypeLabel": "<exact label from list>",
  "framing": "Got it — a [friendly 1-line description of what they want to build]."
}`,
    lang
  );
}

export async function generateCard(
  slot: string,
  archetypeId: string,
  archetypeLabel: string,
  stage: CollectionStage,
  filledSlots: Record<string, unknown>,
  history: Session['history'],
  lang: SupportedLang = 'en'
): Promise<Card> {
  const known = profileSummary(filledSlots) || 'nothing yet';
  const asked = history.map(h => h.slot).join(', ') || 'none';

  return llmJSON<Card>(
    'You generate question cards for a business setup journey in Abu Dhabi. Return only valid JSON.',
    `Activity: ${archetypeLabel}
Stage: ${stage}
Slot to fill: ${slot}
What we know: ${known}
Already asked: ${asked}

Generate ONE question card for slot "${slot}", phrased for a "${archetypeLabel}" business.

Return JSON:
{
  "cardId": "q_${slot}",
  "kind": "question",
  "type": "<single_select|multi_select|text|toggle>",
  "title": "<concise question, max 12 words>",
  "subtitle": "<optional hint>",
  "options": ["<opt1>", "<opt2>"],
  "slot": "${slot}",
  "stage": "${stage}"
}

Rules:
- text: free-form (names, descriptions)
- single_select: one-of-many or yes/no (2–4 options)
- multi_select: multiple OK (docs, assets) — include "None" as last option
- toggle: binary on/off
- Omit options for text type
- Keep title conversational and specific to ${archetypeLabel}`,
    lang
  );
}

export async function runAnalysis(session: Session): Promise<AnalysisResult> {
  return llmJSON<AnalysisResult>(
    'You are a business setup advisor for Abu Dhabi. Use only provided KB data — do NOT invent fees. Return only valid JSON.',
    `Analyze this founder's profile.

Activity: ${session.archetypeId}
Goal: ${session.goalText}

Profile:
${profileSummary(session.filledSlots)}

## KB licenses for this activity
${formatLicensesForLLM(session.archetypeId)}

Return JSON:
{
  "matchedActivities": [{ "id": "<archetypeId>", "label": "<friendly label>" }],
  "estSetupCostRange": "AED X – Y",
  "candidateLicenses": ["<license type name>"],
  "confidence": <0.0–1.0>,
  "unverified": ["<uncertain items>"]
}

Confidence guide: 0.9 = all slots filled + KB match; 0.6 = partial profile; 0.4 = many gaps.`,
    session.language
  );
}

export async function runVerify(
  verifyTarget: string,
  archetypeId: string,
  candidateLicenses: string[],
  lang: SupportedLang = 'en'
): Promise<VerifyResult> {
  const licenses = getLicensesForArchetype(archetypeId);
  const best = licenses[0];
  const authority = best ? getAuthority(best.authorityId) : undefined;

  try {
    const result = await llmJSON<{
      status: 'verified' | 'not_found';
      info?: string;
      verifiedFacts?: Record<string, string>;
      sources?: string[];
      confidence?: number;
    }>(
      'You are verifying Abu Dhabi business license requirements from your training knowledge. Be conservative — only report facts you are highly confident about. Return only valid JSON.',
      `Verify current requirements for: "${verifyTarget}"

Candidate licenses: ${candidateLicenses.join(', ')}
Authority: ${authority?.name ?? 'ADDED / DCT Abu Dhabi'}

From your knowledge of Abu Dhabi business regulations, report what you know about:
- License fee in AED
- Required approvals and documents
- Processing timeline
- Issuing authority

If you are highly confident (>80%) in the information, return:
{
  "status": "verified",
  "info": "<1-2 sentence summary>",
  "verifiedFacts": {
    "licenseFee": "AED ...",
    "approvals": "<list>",
    "timeline": "..."
  },
  "sources": ["knowledge base"]
}

If you are not confident or the information may be outdated, return:
{
  "status": "not_found",
  "confidence": <0.0-1.0>
}`,
      lang
    );

    if (result.status === 'verified') {
      return {
        status: 'verified',
        info: result.info,
        verifiedFacts: result.verifiedFacts,
        sources: result.sources,
        nextStage: 'license',
      };
    }

    throw new Error('not_found');
  } catch {
    return {
      status: 'not_found',
      authority: authority?.name ?? 'ADDED',
      phone: authority?.phone,
      contactUrl: authority?.contactUrl,
      whatToConfirm: verifyTarget,
      message: lang === 'ar'
        ? `لم يتم التحقق إلكترونياً. يرجى التواصل مع ${authority?.name ?? 'الجهة المختصة'} للتأكد من المتطلبات.`
        : `Could not verify online. Contact ${authority?.name ?? 'the relevant authority'} to confirm exact requirements.`,
      nextStage: 'license',
    };
  }
}

export async function runLicenseRec(session: Session, verifyResult: VerifyResult): Promise<LicenseResult> {
  const verifiedInfo =
    verifyResult.status === 'verified'
      ? `Confirmed facts:\n- Fee: ${verifyResult.verifiedFacts?.licenseFee ?? 'see KB'}\n- Approvals: ${verifyResult.verifiedFacts?.approvals ?? 'see KB'}\n- Timeline: ${verifyResult.verifiedFacts?.timeline ?? 'see KB'}\n- Sources: ${verifyResult.sources?.join(', ')}`
      : `Not confirmed online. Founder must call ${verifyResult.authority} (${verifyResult.phone ?? verifyResult.contactUrl}) to verify: ${verifyResult.whatToConfirm}`;

  return llmJSON<LicenseResult>(
    'You recommend business licenses for Abu Dhabi founders. Use KB data. Return only valid JSON.',
    `Activity: ${session.archetypeId}
Goal: ${session.goalText}
Profile: ${profileSummary(session.filledSlots)}

## KB licenses for this activity
${formatLicensesForLLM(session.archetypeId)}

## Verification result
${verifiedInfo}

Pick the BEST license and 1–2 alternatives.
Set costStatus to "verified" if cost was web-confirmed, else "not_verified_confirm_by_phone".

Return JSON:
{
  "best": {
    "type": "...", "issuer": "...", "pros": ["..."], "cons": ["..."],
    "timeline": "...", "approvals": ["..."], "estCost": "AED ...",
    "costStatus": "verified"|"not_verified_confirm_by_phone", "source": "..."
  },
  "alternatives": [{ same fields }]
}`,
    session.language
  );
}

export async function runBankingRec(session: Session): Promise<BankingResult> {
  return llmJSON<BankingResult>(
    'You recommend bank accounts for Abu Dhabi small business founders. Return only valid JSON.',
    `Profile: ${profileSummary(session.filledSlots)}
Activity: ${session.archetypeId}

## Available banks
${formatBanksForLLM(session.archetypeId)}

Rank by likelihood of approval. Set likelyToApprove: true if capital meets minimum balance AND profile is straightforward.

Return JSON:
{
  "banks": [{
    "name": "...", "minBalance": "...", "requirements": ["..."],
    "docsNeeded": ["..."], "likelyToApprove": true|false, "source": "..."
  }]
}

Order: most likely to approve first.`,
    session.language
  );
}

export async function runPlan(
  session: Session,
  analysisResult: AnalysisResult,
  verifyResult: VerifyResult,
  licenseResult: LicenseResult,
  bankingResult: BankingResult
): Promise<PlanResult> {
  const bestBank = bankingResult.banks.find(b => b.likelyToApprove) ?? bankingResult.banks[0];

  return llmJSON<PlanResult>(
    'You create business launch roadmaps for Abu Dhabi founders. Concrete, ordered steps. Return only valid JSON.',
    `Goal: ${session.goalText}
Activity: ${session.archetypeId}
Best license: ${licenseResult.best.type} — ${licenseResult.best.estCost}, ${licenseResult.best.timeline}
Best bank: ${bestBank?.name ?? 'TBD'}
Verify: ${verifyResult.status === 'verified' ? 'facts confirmed' : 'not verified — founder to call authority'}
Confidence: ${analysisResult.confidence}
Unverified: ${analysisResult.unverified.join(', ') || 'none'}

## Funding options (use ONLY these — do not invent grants or loans)
${formatFundingForLLM(session.archetypeId)}

Create 4–7 step roadmap. Steps must be concrete and ordered. nextAction = first thing they can do today.
If a government fund or loan from the KB above fits this founder, include a funding step in the roadmap and list matches in "funding". Government funds usually require an Emirati founder — respect the eligibility notes.

Return JSON:
{
  "roadmap": ["Step 1: ...", "Step 2: ..."],
  "totalEstCost": "AED X – Y",
  "totalTimeline": "X–Y weeks",
  "nextAction": "<one clear action they can take today>",
  "funding": [{ "name": "<product name>", "provider": "<provider>", "fundingUpTo": "AED ...", "note": "<eligibility/fit, 1 line>" }],
  "confidence": <from analysis>,
  "unverified": ["..."]
}`,
    session.language
  );
}
