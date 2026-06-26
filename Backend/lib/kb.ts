import type { CollectionStage } from './types';

export interface ActivityArchetype {
  id: string;
  label: string;
  keywords: string[];
  stageSlots: Partial<Record<CollectionStage, string[]>>;
  candidateLicenseIds: string[];
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
  pros: string[];
  cons: string[];
  timeline: string;
  approvals: string[];
  estCost: string;
  source: string;
  activityIds: string[];
}

export interface BankKBEntry {
  name: string;
  minBalance: string;
  minBalanceAED: number;
  requirements: string[];
  docsNeeded: string[];
  source: string;
}

export const AUTHORITIES: Record<string, Authority> = {
  dct: {
    id: 'dct',
    name: 'DCT Abu Dhabi',
    phone: '+971 2 444 0444',
    contactUrl: 'https://dctabudhabi.ae/en/contact',
    website: 'dctabudhabi.ae',
  },
  added: {
    id: 'added',
    name: 'ADDED (Abu Dhabi Department of Economic Development)',
    phone: '+971 2 619 1555',
    contactUrl: 'https://www.added.gov.ae/en/contact',
    website: 'added.gov.ae',
  },
  adafsa: {
    id: 'adafsa',
    name: 'ADAFSA (Abu Dhabi Agriculture and Food Safety Authority)',
    phone: '+971 2 813 6000',
    contactUrl: 'https://www.adafsa.gov.ae/en/contact',
    website: 'adafsa.gov.ae',
  },
  tamm: {
    id: 'tamm',
    name: 'TAMM (Abu Dhabi Government Services)',
    phone: '+971 2 666 9999',
    contactUrl: 'https://www.tamm.abudhabi',
    website: 'tamm.abudhabi',
  },
};

export const ARCHETYPES: ActivityArchetype[] = [
  {
    id: 'astro_tourism',
    label: 'Desert / astro tourism (overnight, private land)',
    keywords: ['stargazing', 'desert', 'tourism', 'overnight', 'camping', 'astro', 'telescope', 'stars', 'sky'],
    stageSlots: {
      business: ['activity', 'businessStage', 'hostingType', 'landOwnership'],
      founder: ['founderType', 'residency', 'hasExistingBusiness', 'language'],
      details: ['location', 'jurisdictionPref', 'channel', 'needsOffice'],
      budget: ['capital', 'expectedRevenue', 'employees', 'growth'],
      documents: ['docs', 'assets', 'permitsHeld'],
    },
    candidateLicenseIds: ['tourism_activity_license', 'tajer_abu_dhabi'],
  },
  {
    id: 'home_food',
    label: 'Home food business (cooking, catering, baking)',
    keywords: ['food', 'cooking', 'catering', 'home kitchen', 'baking', 'meal', 'chef', 'cake', 'restaurant', 'eat'],
    stageSlots: {
      business: ['activity', 'businessStage', 'kitchenType', 'foodSafetyReg'],
      founder: ['founderType', 'residency', 'hasExistingBusiness', 'language'],
      details: ['location', 'jurisdictionPref', 'channel', 'needsOffice'],
      budget: ['capital', 'expectedRevenue', 'employees', 'growth'],
      documents: ['docs', 'assets', 'permitsHeld'],
    },
    candidateLicenseIds: ['home_business_license', 'food_business_license'],
  },
  {
    id: 'online_retail',
    label: 'Online retail / e-commerce',
    keywords: ['online', 'e-commerce', 'sell', 'shop', 'store', 'products', 'dropship', 'instagram', 'tiktok'],
    stageSlots: {
      business: ['activity', 'businessStage', 'productType', 'fulfillmentMethod'],
      founder: ['founderType', 'residency', 'hasExistingBusiness', 'language'],
      details: ['location', 'jurisdictionPref', 'channel', 'needsOffice'],
      budget: ['capital', 'expectedRevenue', 'employees', 'growth'],
      documents: ['docs', 'assets', 'permitsHeld'],
    },
    candidateLicenseIds: ['tajer_abu_dhabi', 'ecommerce_license'],
  },
  {
    id: 'freelance_services',
    label: 'Freelance / professional services',
    keywords: ['freelance', 'consulting', 'services', 'design', 'writing', 'coding', 'photography', 'marketing', 'skills'],
    stageSlots: {
      business: ['activity', 'businessStage', 'serviceType', 'clientBase'],
      founder: ['founderType', 'residency', 'hasExistingBusiness', 'language'],
      details: ['location', 'jurisdictionPref', 'channel', 'needsOffice'],
      budget: ['capital', 'expectedRevenue', 'employees', 'growth'],
      documents: ['docs', 'assets', 'permitsHeld'],
    },
    candidateLicenseIds: ['freelancer_permit', 'tajer_abu_dhabi'],
  },
  {
    id: 'camel_farm',
    label: 'Camel farm / agri-business',
    keywords: ['camel', 'farm', 'livestock', 'animal', 'agriculture', 'dairy', 'milk', 'breeding', 'racing'],
    stageSlots: {
      business: ['activity', 'businessStage', 'farmType', 'landOwnership'],
      founder: ['founderType', 'residency', 'hasExistingBusiness', 'language'],
      details: ['location', 'jurisdictionPref', 'channel', 'needsOffice'],
      budget: ['capital', 'expectedRevenue', 'employees', 'growth'],
      documents: ['docs', 'assets', 'permitsHeld'],
    },
    candidateLicenseIds: ['agricultural_license', 'tajer_abu_dhabi'],
  },
  {
    id: 'general_trade',
    label: 'General trading / retail',
    keywords: ['trading', 'import', 'export', 'wholesale', 'retail', 'goods', 'items', 'merchandise'],
    stageSlots: {
      business: ['activity', 'businessStage', 'tradeType', 'storefront'],
      founder: ['founderType', 'residency', 'hasExistingBusiness', 'language'],
      details: ['location', 'jurisdictionPref', 'channel', 'needsOffice'],
      budget: ['capital', 'expectedRevenue', 'employees', 'growth'],
      documents: ['docs', 'assets', 'permitsHeld'],
    },
    candidateLicenseIds: ['commercial_license', 'tajer_abu_dhabi'],
  },
];

export const LICENSES: Record<string, LicenseKBEntry> = {
  tourism_activity_license: {
    id: 'tourism_activity_license',
    type: 'Tourism Activity License',
    issuer: 'DCT Abu Dhabi',
    authorityId: 'dct',
    pros: ['Covers guest-hosting and tourism legally', 'Recognized by partners and booking platforms', 'Enables legal marketing of tours'],
    cons: ['Requires DCT activity approval', 'Annual renewal required', 'Site inspection may be required for overnight hosting'],
    timeline: '2–4 weeks',
    approvals: ['DCT activity approval', 'Emirates ID or passport'],
    estCost: 'AED 1,500 – 3,000',
    source: 'dctabudhabi.ae',
    activityIds: ['astro_tourism'],
  },
  tajer_abu_dhabi: {
    id: 'tajer_abu_dhabi',
    type: 'Tajer Abu Dhabi',
    issuer: 'ADDED',
    authorityId: 'added',
    pros: ['Very low cost', 'Phone/online application — no office visit', 'Fast approval (1–3 days)', 'Covers many home-based and small activities'],
    cons: ['May not cover guest hosting or food service', 'Limited to specific activity categories', 'UAE residents only'],
    timeline: '1–3 days',
    approvals: ['Emirates ID'],
    estCost: 'AED 200 – 600',
    source: 'added.gov.ae',
    activityIds: ['astro_tourism', 'online_retail', 'freelance_services', 'home_food', 'general_trade', 'camel_farm'],
  },
  home_business_license: {
    id: 'home_business_license',
    type: 'Home Business License',
    issuer: 'ADDED',
    authorityId: 'added',
    pros: ['Designed for home-based businesses', 'Affordable', 'No separate office needed'],
    cons: ['Restricted to non-hazardous activities', 'Cannot employ workers at home premises'],
    timeline: '3–7 days',
    approvals: ['Emirates ID', 'Tenancy agreement or property ownership proof'],
    estCost: 'AED 500 – 1,500',
    source: 'added.gov.ae',
    activityIds: ['home_food', 'freelance_services'],
  },
  food_business_license: {
    id: 'food_business_license',
    type: 'Food Business License',
    issuer: 'ADAFSA',
    authorityId: 'adafsa',
    pros: ['Legally required for any food sale in Abu Dhabi', 'Adds credibility with customers', 'Covers home kitchen operations'],
    cons: ['Kitchen inspection required', 'Food handler safety certificate needed', 'Renewal with re-inspection'],
    timeline: '2–6 weeks',
    approvals: ['Kitchen inspection', 'Food safety certificate', 'Emirates ID'],
    estCost: 'AED 1,000 – 3,000',
    source: 'adafsa.gov.ae',
    activityIds: ['home_food'],
  },
  freelancer_permit: {
    id: 'freelancer_permit',
    type: 'Freelancer Permit',
    issuer: 'ADDED',
    authorityId: 'added',
    pros: ['Official permit to invoice clients legally', 'No physical office required', 'Covers wide range of professional services'],
    cons: ['Restricted to listed professional categories', 'Annual renewal', 'Qualification proof may be needed'],
    timeline: '1–2 weeks',
    approvals: ['Emirates ID', 'Professional qualification proof (if applicable)'],
    estCost: 'AED 1,000 – 2,000',
    source: 'added.gov.ae',
    activityIds: ['freelance_services'],
  },
  ecommerce_license: {
    id: 'ecommerce_license',
    type: 'E-commerce License',
    issuer: 'ADDED',
    authorityId: 'added',
    pros: ['Covers online sales legally', 'Allows payment gateway integration', 'Growing category with government support'],
    cons: ['Physical address required', 'Annual renewal'],
    timeline: '1–2 weeks',
    approvals: ['Emirates ID', 'Business plan'],
    estCost: 'AED 2,000 – 5,000',
    source: 'added.gov.ae',
    activityIds: ['online_retail'],
  },
  agricultural_license: {
    id: 'agricultural_license',
    type: 'Agricultural Activity License',
    issuer: 'ADDED / Abu Dhabi Agriculture Authority',
    authorityId: 'added',
    pros: ['Covers farming and livestock legally', 'Government support programs available', 'Eligible for subsidies'],
    cons: ['Land registration may be required', 'Activity-specific permits needed per livestock type'],
    timeline: '2–4 weeks',
    approvals: ['Emirates ID', 'Land ownership or lease', 'Activity description'],
    estCost: 'AED 500 – 2,000',
    source: 'added.gov.ae',
    activityIds: ['camel_farm'],
  },
  commercial_license: {
    id: 'commercial_license',
    type: 'Commercial License',
    issuer: 'ADDED',
    authorityId: 'added',
    pros: ['Full trading rights', 'Can employ staff legally', 'Easier bank account opening'],
    cons: ['Higher cost', 'Physical office or warehouse required', 'More documentation'],
    timeline: '1–3 weeks',
    approvals: ['Emirates ID', 'Trade name approval', 'Office tenancy contract'],
    estCost: 'AED 3,000 – 10,000',
    source: 'added.gov.ae',
    activityIds: ['general_trade'],
  },
};

export const BANKS: BankKBEntry[] = [
  {
    name: 'Wio Bank (digital, SME-friendly)',
    minBalance: 'AED 0 (no minimum balance)',
    minBalanceAED: 0,
    requirements: ['Trade license', 'Emirates ID'],
    docsNeeded: ['Trade license', 'Emirates ID'],
    source: 'wio.io',
  },
  {
    name: 'Mashreq Neo Business',
    minBalance: 'AED 3,000',
    minBalanceAED: 3000,
    requirements: ['Trade license', 'Emirates ID'],
    docsNeeded: ['Trade license', 'Emirates ID', 'Passport'],
    source: 'mashreq.com',
  },
  {
    name: 'Abu Dhabi Commercial Bank (ADCB)',
    minBalance: 'AED 5,000 – 10,000',
    minBalanceAED: 5000,
    requirements: ['Trade license', 'Emirates ID'],
    docsNeeded: ['Trade license', 'Emirates ID', 'Passport', 'Lease agreement (if applicable)'],
    source: 'adcb.com',
  },
  {
    name: 'First Abu Dhabi Bank (FAB)',
    minBalance: 'AED 10,000',
    minBalanceAED: 10000,
    requirements: ['Trade license', 'Emirates ID', 'Passport copy'],
    docsNeeded: ['Trade license', 'Emirates ID', 'Passport', 'Residence visa', 'Business profile'],
    source: 'bankfab.com',
  },
  {
    name: 'Emirates NBD',
    minBalance: 'AED 10,000',
    minBalanceAED: 10000,
    requirements: ['Trade license', 'Emirates ID', 'Company documents'],
    docsNeeded: ['Trade license', 'Emirates ID', 'Passport', 'Company memorandum'],
    source: 'emiratesnbd.com',
  },
];

export function getArchetype(id: string): ActivityArchetype | undefined {
  return ARCHETYPES.find(a => a.id === id);
}

export function findArchetypeByGoal(goalText: string): ActivityArchetype {
  const lower = goalText.toLowerCase();
  let best = ARCHETYPES[0];
  let bestScore = 0;
  for (const arch of ARCHETYPES) {
    const score = arch.keywords.filter(k => lower.includes(k)).length;
    if (score > bestScore) {
      bestScore = score;
      best = arch;
    }
  }
  return best;
}

export function getLicensesForArchetype(archetypeId: string): LicenseKBEntry[] {
  return Object.values(LICENSES).filter(l => l.activityIds.includes(archetypeId));
}

export function getBanksForCapital(capitalRange?: string | string[] | number): BankKBEntry[] {
  const str = String(capitalRange ?? '').toLowerCase();
  if (!str || str.includes('less') || str.includes('under') || str.includes('5k') || str.includes('10k')) {
    return BANKS.filter(b => b.minBalanceAED <= 3000);
  }
  return BANKS;
}

export function getAuthority(id: string): Authority | undefined {
  return AUTHORITIES[id];
}

export function getArchetypeList(): string {
  return ARCHETYPES.map(a => `- ${a.id}: ${a.label}`).join('\n');
}

export function formatLicenseForLLM(l: LicenseKBEntry): string {
  return `### ${l.type} (issued by ${l.issuer})
- **Estimated cost:** ${l.estCost}
- **Timeline:** ${l.timeline}
- **Approvals required:** ${l.approvals.join(', ')}
- **Pros:** ${l.pros.join(' · ')}
- **Cons:** ${l.cons.join(' · ')}
- **Source:** ${l.source}`;
}

export function formatLicensesForLLM(archetypeId: string): string {
  return getLicensesForArchetype(archetypeId).map(formatLicenseForLLM).join('\n\n');
}

export function formatBankForLLM(b: BankKBEntry): string {
  return `### ${b.name}
- **Minimum balance:** ${b.minBalance}
- **Requirements:** ${b.requirements.join(', ')}
- **Documents needed:** ${b.docsNeeded.join(', ')}
- **Source:** ${b.source}`;
}

export function formatBanksForLLM(capitalRange?: string | string[] | number): string {
  return getBanksForCapital(capitalRange).map(formatBankForLLM).join('\n\n');
}

export function formatArchetypeForLLM(a: ActivityArchetype): string {
  const stages = Object.entries(a.stageSlots)
    .map(([stage, slots]) => `  - ${stage}: ${(slots as string[]).join(', ')}`)
    .join('\n');
  return `### ${a.label} (id: ${a.id})
**Required slots by stage:**
${stages}`;
}
