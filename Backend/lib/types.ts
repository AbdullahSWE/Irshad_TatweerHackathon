export type CollectionStage = 'business' | 'founder' | 'details' | 'budget' | 'documents';

export type CardKind = 'question' | 'confirmation' | 'info';
export type CardType = 'single_select' | 'multi_select' | 'text' | 'toggle' | 'none';

export interface Card {
  cardId: string;
  kind: CardKind;
  type: CardType;
  title: string;
  subtitle?: string;
  options?: string[];
  slot: string;
  stage: CollectionStage;
}

export interface HistoryEntry {
  cardId: string;
  question: string;
  answer: string | string[];
  slot: string;
  stage: CollectionStage;
}

export interface FilledSlots {
  [key: string]: string | string[] | number | undefined;
}

export type SupportedLang = 'en' | 'ar';

export interface Session {
  sessionId: string;
  goalText: string;
  currentStage: CollectionStage;
  archetypeId: string;
  language: SupportedLang;
  filledSlots: FilledSlots;
  history: HistoryEntry[];
}

export interface Progress {
  filled: number;
  required: number;
  stagesDone: number;
  stagesTotal: number;
}

export interface AnalysisResult {
  matchedActivities: Array<{ id: string; label: string }>;
  estSetupCostRange: string;
  candidateLicenses: string[];
  confidence: number;
  unverified: string[];
}

export interface VerifyResult {
  status: 'verified' | 'not_found';
  info?: string;
  verifiedFacts?: Record<string, string>;
  sources?: string[];
  authority?: string;
  phone?: string;
  contactUrl?: string;
  whatToConfirm?: string;
  message?: string;
  nextStage: 'license';
}

export interface LicenseOption {
  type: string;
  issuer: string;
  pros: string[];
  cons: string[];
  timeline: string;
  approvals: string[];
  estCost: string;
  costStatus: 'verified' | 'not_verified_confirm_by_phone';
  source: string;
}

export interface LicenseResult {
  best: LicenseOption;
  alternatives: LicenseOption[];
}

export interface BankOption {
  name: string;
  minBalance: string;
  requirements: string[];
  docsNeeded: string[];
  likelyToApprove: boolean;
  source: string;
}

export interface BankingResult {
  banks: BankOption[];
}

export interface PlanResult {
  roadmap: string[];
  totalEstCost: string;
  totalTimeline: string;
  nextAction: string;
  confidence: number;
  unverified: string[];
}

export interface ServerSession {
  archetypeId: string;
  goalText: string;
  language: SupportedLang;
  filledSlots: FilledSlots;
  analysisResult?: AnalysisResult;
  verifyResult?: VerifyResult;
  licenseResult?: LicenseResult;
  bankingResult?: BankingResult;
}
