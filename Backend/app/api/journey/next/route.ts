import { NextRequest, NextResponse } from 'next/server';
import { generateCard } from '@/lib/llm';
import { getArchetype } from '@/lib/kb';
import { updateServerSession } from '@/lib/session';
import {
  MAX_QUESTIONS,
  advanceStage,
  computeMissing,
  coreFilled,
  computeProgress,
  syncFilledSlotsFromHistory,
} from '@/lib/journey';
import type { Session, CollectionStage } from '@/lib/types';

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' },
  });
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json() as { sessionId: string; session: Session };
    const { session } = body;

    if (!session?.sessionId) {
      return NextResponse.json({ error: 'session is required' }, { status: 400 });
    }

    const archetype = getArchetype(session.archetypeId);
    if (!archetype) {
      return NextResponse.json({ error: 'Unknown archetypeId in session' }, { status: 400 });
    }

    const lang = session.language ?? 'en';

    syncFilledSlotsFromHistory(session);
    updateServerSession(session.sessionId, { filledSlots: session.filledSlots });

    if (session.history.length >= MAX_QUESTIONS) {
      return NextResponse.json({ status: 'gate_open', reason: 'cap_hit' });
    }

    let currentStage: CollectionStage = session.currentStage;
    let stageJustCompleted: CollectionStage | undefined;

    while (true) {
      const missing = computeMissing(session.archetypeId, currentStage, session.filledSlots);
      if (missing.length > 0) break;

      const next = advanceStage(currentStage);
      if (!next) {
        return NextResponse.json({ status: 'gate_open' });
      }
      stageJustCompleted = currentStage;
      currentStage = next;
      session.currentStage = next;
    }

    const stillMissing = computeMissing(session.archetypeId, currentStage, session.filledSlots);

    const slotToAsk = coreFilled(session.filledSlots)
      ? stillMissing[0]
      : stillMissing.find(s => ['activity', 'residency', 'location', 'capital'].includes(s)) ?? stillMissing[0];

    if (!slotToAsk) {
      return NextResponse.json({ status: 'gate_open' });
    }

    const card = await generateCard(
      slotToAsk,
      session.archetypeId,
      archetype.label,
      currentStage,
      session.filledSlots,
      session.history,
      lang
    );

    const progress = computeProgress({ ...session, currentStage });

    return NextResponse.json({
      status: 'collecting',
      currentStage,
      ...(stageJustCompleted ? { stageJustCompleted } : {}),
      progress,
      card,
    });
  } catch (err) {
    console.error('/api/journey/next error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
