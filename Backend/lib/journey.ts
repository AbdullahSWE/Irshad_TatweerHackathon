import { getArchetype } from './kb';
import type { CollectionStage, Session, Progress } from './types';

export const STAGE_PATH: CollectionStage[] = [
  'business',
  'founder',
  'details',
  'budget',
  'documents',
];

export const STAGE_TOTAL = STAGE_PATH.length;

export const MAX_QUESTIONS = 8;

const CORE_SLOTS = ['activity', 'residency', 'location', 'capital'];

export function advanceStage(current: CollectionStage): CollectionStage | null {
  const idx = STAGE_PATH.indexOf(current);
  if (idx === -1 || idx === STAGE_PATH.length - 1) return null;
  return STAGE_PATH[idx + 1];
}

export function stageIndex(stage: CollectionStage): number {
  return STAGE_PATH.indexOf(stage);
}

export function checklistFor(archetypeId: string, stage: CollectionStage): string[] {
  const arch = getArchetype(archetypeId);
  return arch?.stageSlots[stage] ?? [];
}

export function computeMissing(archetypeId: string, stage: CollectionStage, filledSlots: Record<string, unknown>): string[] {
  const required = checklistFor(archetypeId, stage);
  return required.filter(slot => {
    const val = filledSlots[slot];
    if (val === undefined || val === null) return true;
    if (typeof val === 'string' && val.trim() === '') return true;
    if (Array.isArray(val) && val.length === 0) return true;
    return false;
  });
}

export function coreFilled(filledSlots: Record<string, unknown>): boolean {
  return CORE_SLOTS.every(slot => {
    const val = filledSlots[slot];
    return val !== undefined && val !== null && val !== '';
  });
}

export function computeProgress(session: Session): Progress {
  const allRequired: string[] = [];
  const allFilled: string[] = [];

  for (const stage of STAGE_PATH) {
    const required = checklistFor(session.archetypeId, stage);
    allRequired.push(...required);
    for (const slot of required) {
      const val = session.filledSlots[slot];
      const isFilled = val !== undefined && val !== null && val !== '' && !(Array.isArray(val) && val.length === 0);
      if (isFilled) allFilled.push(slot);
    }
  }

  const currentIdx = stageIndex(session.currentStage);
  const stagesDone = STAGE_PATH.slice(0, currentIdx).filter(stage => {
    const missing = computeMissing(session.archetypeId, stage, session.filledSlots);
    return missing.length === 0;
  }).length;

  return {
    filled: allFilled.length,
    required: allRequired.length,
    stagesDone,
    stagesTotal: STAGE_TOTAL,
  };
}

export function syncFilledSlotsFromHistory(session: Session): void {
  if (session.history.length === 0) return;
  const last = session.history[session.history.length - 1];
  if (last.slot && session.filledSlots[last.slot] === undefined) {
    session.filledSlots[last.slot] = last.answer as string | string[];
  }
}
