import type { CollectionStage } from './types';
import knowledge from '@/kb/knowledge.json';

// ---------------------------------------------------------------------------
// Raw JSON shapes (Backend/kb/knowledge.json)
// ---------------------------------------------------------------------------

interface RawAuthority {
  id: string;
  name: string;
  short_name?: string;
  role?: string;
  phone?: string;
  secondary_phone?: string;
  email?: string;
  main_website?: string;
  service_platform?: string;
  source_url?: string;
}

interface RawLicenseCosts {
  base_cost_aed?: number;
  official_max_range_aed?: number;
  extra_activity_fee_aed_each?: number;
  fee_warning?: string;
}

interface RawLicense {
  id: string;
  name: string;
  issuing_authority_id: string;
  best_for?: string[];
  information_source?: string;
  official_application_source?: string;
  costs?: RawLicenseCosts;
  office_requirement?: { office_required?: boolean; note?: string };
  required_documents?: string[];
  step_sequence?: string[];
  concrete_next_action?: string;
}

interface RawBankPlan {
  plan_id?: string;
  account_name?: string;
  monthly_fee_aed?: number;
  best_for?: string;
  included_features?: string[];
}

interface RawBank {
  id: string;
  bank_name: string;
  best_for?: string[];
  website?: string;
  source_url?: string;
  plan_options?: RawBankPlan[];
  notes?: string;
}

interface RawArchetype {
  id: string;
  name: string;
  recommended_license_ids: string[];
  extra_authority_ids?: string[];
  likely_bank_ids?: string[];
  funding_or_investment_ids?: string[];
  eligibility_summary?: string;
  step_sequence?: string[];
  concrete_next_action?: string;
}

interface RawBankLoan {
  id: string;
  provider: string;
  type?: string;
  best_for?: string[];
  required_documents?: string[];
  website?: string;
  source_url?: string;
  important_note?: string;
}

interface RawFund {
  id: string;
  provider: string;
  type?: string;
  product_name: string;
  best_for?: string[];
  funding_up_to_aed?: number;
  project_cost_coverage?: string;
  repayment_period_months?: number;
  grace_period_months?: number;
  eligibility_note?: string;
  website?: string;
  source_url?: string;
  concrete_next_action?: string;
}

interface KnowledgeFile {
  authorities: RawAuthority[];
  licenses: RawLicense[];
  banks: RawBank[];
  bank_loans: RawBankLoan[];
  government_investments_and_funds: RawFund[];
  archetypes: RawArchetype[];
}

const KB = knowledge as unknown as KnowledgeFile;

// ---------------------------------------------------------------------------
// Public interfaces (consumed by lib/llm.ts, lib/journey.ts, API routes)
// ---------------------------------------------------------------------------

export interface ActivityArchetype {
  id: string;
  label: string;
  stageSlots: Partial<Record<CollectionStage, string[]>>;
  candidateLicenseIds: string[];
  likelyBankIds: string[];
  fundingIds: string[];
}

export interface Authority {
  id: string;
  name: string;
  phone?: string;
  contactUrl: string;
  website: string;
}

export interface LicenseKBEntry {
  id: string;
  type: string;
  issuer: string;
  authorityId: string;
  bestFor: string[];
  estCost: string;
  officeRequired?: string;
  approvals: string[];
  stepSequence: string[];
  source: string;
  activityIds: string[];
}

export interface BankPlan {
  name: string;
  monthlyFee: string;
  bestFor: string;
  features: string[];
}

export interface BankKBEntry {
  id: string;
  name: string;
  bestFor: string[];
  plans: BankPlan[];
  notes: string;
  source: string;
}

export interface BankLoanKBEntry {
  id: string;
  provider: string;
  bestFor: string[];
  requiredDocuments: string[];
  note: string;
  source: string;
}

export interface FundingKBEntry {
  id: string;
  provider: string;
  productName: string;
  bestFor: string[];
  fundingUpTo: string;
  coverage: string;
  repayment: string;
  eligibility: string;
  nextAction: string;
  source: string;
}

// ---------------------------------------------------------------------------
// Journey question-flow config (slots collected per stage). This is app flow,
// not business KB — knowledge.json holds facts, not the interview script.
// ---------------------------------------------------------------------------

const STAGE_SLOTS: Partial<Record<CollectionStage, string[]>> = {
  business: ['activity', 'businessStage', 'operatingModel'],
  founder: ['founderType', 'residency', 'hasExistingBusiness', 'language'],
  details: ['location', 'jurisdictionPref', 'channel', 'needsOffice'],
  budget: ['capital', 'expectedRevenue', 'employees', 'growth'],
  documents: ['docs', 'assets', 'permitsHeld'],
};

// ---------------------------------------------------------------------------
// Adapters: raw JSON -> public interfaces
// ---------------------------------------------------------------------------

function formatAED(n: number): string {
  return n.toLocaleString('en-US');
}

function licenseCostRange(costs?: RawLicenseCosts): string {
  if (!costs || costs.base_cost_aed === undefined) return 'Verify current fee with authority';
  const base = costs.base_cost_aed;
  if (costs.official_max_range_aed && costs.official_max_range_aed > base) {
    return `AED ${formatAED(base)} – ${formatAED(costs.official_max_range_aed)}`;
  }
  return `AED ${formatAED(base)}+`;
}

// archetypeId -> license.id is in archetype.recommended_license_ids.
// Invert once so each license knows which archetypes recommend it.
const LICENSE_TO_ARCHETYPES: Record<string, string[]> = (() => {
  const map: Record<string, string[]> = {};
  for (const arch of KB.archetypes) {
    for (const licId of arch.recommended_license_ids) {
      (map[licId] ??= []).push(arch.id);
    }
  }
  return map;
})();

function adaptAuthority(a: RawAuthority): Authority {
  return {
    id: a.id,
    name: a.short_name ? `${a.name} (${a.short_name})` : a.name,
    phone: a.phone,
    contactUrl: a.source_url ?? a.service_platform ?? a.main_website ?? '',
    website: (a.main_website ?? '').replace(/^https?:\/\//, ''),
  };
}

function adaptLicense(l: RawLicense): LicenseKBEntry {
  const auth = AUTHORITIES[l.issuing_authority_id];
  return {
    id: l.id,
    type: l.name,
    issuer: auth?.name ?? l.issuing_authority_id,
    authorityId: l.issuing_authority_id,
    bestFor: l.best_for ?? [],
    estCost: licenseCostRange(l.costs),
    officeRequired:
      l.office_requirement?.office_required === undefined
        ? undefined
        : l.office_requirement.office_required
        ? l.office_requirement.note ?? 'Office required'
        : 'No office required',
    approvals: l.required_documents ?? [],
    stepSequence: l.step_sequence ?? [],
    source: l.information_source ?? l.official_application_source ?? '',
    activityIds: LICENSE_TO_ARCHETYPES[l.id] ?? [],
  };
}

function adaptBank(b: RawBank): BankKBEntry {
  return {
    id: b.id,
    name: b.bank_name,
    bestFor: b.best_for ?? [],
    plans: (b.plan_options ?? []).map(p => ({
      name: p.account_name ?? p.plan_id ?? 'Plan',
      monthlyFee: p.monthly_fee_aed !== undefined ? `AED ${formatAED(p.monthly_fee_aed)}/mo` : 'see bank',
      bestFor: p.best_for ?? '',
      features: p.included_features ?? [],
    })),
    notes: b.notes ?? '',
    source: (b.source_url ?? b.website ?? '').replace(/^https?:\/\//, ''),
  };
}

function adaptArchetype(a: RawArchetype): ActivityArchetype {
  return {
    id: a.id,
    label: a.name,
    stageSlots: STAGE_SLOTS,
    candidateLicenseIds: a.recommended_license_ids,
    likelyBankIds: a.likely_bank_ids ?? [],
    fundingIds: a.funding_or_investment_ids ?? [],
  };
}

function adaptBankLoan(l: RawBankLoan): BankLoanKBEntry {
  return {
    id: l.id,
    provider: l.provider,
    bestFor: l.best_for ?? [],
    requiredDocuments: l.required_documents ?? [],
    note: l.important_note ?? '',
    source: (l.source_url ?? l.website ?? '').replace(/^https?:\/\//, ''),
  };
}

function adaptFund(f: RawFund): FundingKBEntry {
  return {
    id: f.id,
    provider: f.provider,
    productName: f.product_name,
    bestFor: f.best_for ?? [],
    fundingUpTo: f.funding_up_to_aed !== undefined ? `AED ${formatAED(f.funding_up_to_aed)}` : 'see provider',
    coverage: f.project_cost_coverage ?? '',
    repayment:
      f.repayment_period_months !== undefined
        ? `${f.repayment_period_months}mo${f.grace_period_months ? ` (+${f.grace_period_months}mo grace)` : ''}`
        : '',
    eligibility: f.eligibility_note ?? '',
    nextAction: f.concrete_next_action ?? '',
    source: (f.source_url ?? f.website ?? '').replace(/^https?:\/\//, ''),
  };
}

// ---------------------------------------------------------------------------
// Built lookups
// ---------------------------------------------------------------------------

export const AUTHORITIES: Record<string, Authority> = Object.fromEntries(
  KB.authorities.map(a => [a.id, adaptAuthority(a)])
);

export const LICENSES: Record<string, LicenseKBEntry> = Object.fromEntries(
  KB.licenses.map(l => [l.id, adaptLicense(l)])
);

export const BANKS: BankKBEntry[] = KB.banks.map(adaptBank);

export const BANK_LOANS: BankLoanKBEntry[] = KB.bank_loans.map(adaptBankLoan);

export const FUNDS: Record<string, FundingKBEntry> = Object.fromEntries(
  KB.government_investments_and_funds.map(f => [f.id, adaptFund(f)])
);

export const ARCHETYPES: ActivityArchetype[] = KB.archetypes.map(adaptArchetype);

// ---------------------------------------------------------------------------
// Accessors (stable API for consumers)
// ---------------------------------------------------------------------------

export function getArchetype(id: string): ActivityArchetype | undefined {
  return ARCHETYPES.find(a => a.id === id);
}

export function getLicensesForArchetype(archetypeId: string): LicenseKBEntry[] {
  const arch = getArchetype(archetypeId);
  if (!arch) return [];
  return arch.candidateLicenseIds
    .map(id => LICENSES[id])
    .filter((l): l is LicenseKBEntry => l !== undefined);
}

export function getBanksForArchetype(archetypeId: string): BankKBEntry[] {
  const arch = getArchetype(archetypeId);
  if (!arch || arch.likelyBankIds.length === 0) return BANKS;
  const ranked = arch.likelyBankIds.map(id => BANKS.find(b => b.id === id)).filter((b): b is BankKBEntry => !!b);
  return ranked.length ? ranked : BANKS;
}

export function getAuthority(id: string): Authority | undefined {
  return AUTHORITIES[id];
}

export function getFundingForArchetype(archetypeId: string): FundingKBEntry[] {
  const arch = getArchetype(archetypeId);
  if (!arch) return [];
  return arch.fundingIds.map(id => FUNDS[id]).filter((f): f is FundingKBEntry => f !== undefined);
}

export function getBankLoans(): BankLoanKBEntry[] {
  return BANK_LOANS;
}

export function getArchetypeList(): string {
  return ARCHETYPES.map(a => `- ${a.id}: ${a.label}`).join('\n');
}

// ---------------------------------------------------------------------------
// LLM formatters
// ---------------------------------------------------------------------------

export function formatLicenseForLLM(l: LicenseKBEntry): string {
  const lines = [
    `### ${l.type} (issued by ${l.issuer})`,
    `- **Estimated cost:** ${l.estCost}`,
    `- **Best for:** ${l.bestFor.join(' · ') || 'general'}`,
  ];
  if (l.officeRequired) lines.push(`- **Office:** ${l.officeRequired}`);
  if (l.approvals.length) lines.push(`- **Required documents:** ${l.approvals.join(', ')}`);
  if (l.stepSequence.length) lines.push(`- **Steps:** ${l.stepSequence.join(' → ')}`);
  if (l.source) lines.push(`- **Source:** ${l.source}`);
  return lines.join('\n');
}

export function formatLicensesForLLM(archetypeId: string): string {
  return getLicensesForArchetype(archetypeId).map(formatLicenseForLLM).join('\n\n');
}

export function formatBankForLLM(b: BankKBEntry): string {
  const lines = [`### ${b.name}`, `- **Best for:** ${b.bestFor.join(' · ') || 'general'}`];
  for (const p of b.plans) {
    lines.push(`- **${p.name}** (${p.monthlyFee})${p.bestFor ? ` — ${p.bestFor}` : ''}`);
  }
  if (b.notes) lines.push(`- **Notes:** ${b.notes}`);
  if (b.source) lines.push(`- **Source:** ${b.source}`);
  return lines.join('\n');
}

export function formatBanksForLLM(archetypeId?: string): string {
  const banks = archetypeId ? getBanksForArchetype(archetypeId) : BANKS;
  return banks.map(formatBankForLLM).join('\n\n');
}

export function formatFundForLLM(f: FundingKBEntry): string {
  const lines = [
    `### ${f.productName} — ${f.provider}`,
    `- **Funding up to:** ${f.fundingUpTo}${f.coverage ? ` (covers ${f.coverage})` : ''}`,
  ];
  if (f.repayment) lines.push(`- **Repayment:** ${f.repayment}`);
  if (f.bestFor.length) lines.push(`- **Best for:** ${f.bestFor.join(' · ')}`);
  if (f.eligibility) lines.push(`- **Eligibility:** ${f.eligibility}`);
  if (f.source) lines.push(`- **Source:** ${f.source}`);
  return lines.join('\n');
}

export function formatBankLoanForLLM(l: BankLoanKBEntry): string {
  const lines = [`### ${l.provider} business loan`];
  if (l.bestFor.length) lines.push(`- **Best for:** ${l.bestFor.join(' · ')}`);
  if (l.note) lines.push(`- **Note:** ${l.note}`);
  if (l.source) lines.push(`- **Source:** ${l.source}`);
  return lines.join('\n');
}

export function formatFundingForLLM(archetypeId: string): string {
  const funds = getFundingForArchetype(archetypeId).map(formatFundForLLM);
  const loans = BANK_LOANS.map(formatBankLoanForLLM);
  const sections: string[] = [];
  if (funds.length) sections.push(`**Government funds / grants (matched to activity):**\n${funds.join('\n\n')}`);
  if (loans.length) sections.push(`**Bank loans (post-licence financing):**\n${loans.join('\n\n')}`);
  return sections.join('\n\n') || 'No specific funding matched.';
}

export function formatArchetypeForLLM(a: ActivityArchetype): string {
  const stages = Object.entries(a.stageSlots)
    .map(([stage, slots]) => `  - ${stage}: ${(slots as string[]).join(', ')}`)
    .join('\n');
  return `### ${a.label} (id: ${a.id})
**Required slots by stage:**
${stages}`;
}
