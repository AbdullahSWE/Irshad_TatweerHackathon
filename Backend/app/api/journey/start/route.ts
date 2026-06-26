import { NextRequest, NextResponse } from 'next/server';
import { v4 as uuidv4 } from 'uuid';
import { classifyGoal, generateCard } from '@/lib/llm';
import { getArchetype } from '@/lib/kb';
import { setServerSession } from '@/lib/session';
import { computeMissing } from '@/lib/journey';
import type { Session, SupportedLang } from '@/lib/types';

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' },
  });
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json() as { sessionId?: string; goalText: string; language?: SupportedLang };
    const { goalText } = body;
    const lang: SupportedLang = body.language === 'ar' ? 'ar' : 'en';

    if (!goalText?.trim()) {
      return NextResponse.json({ error: 'goalText is required' }, { status: 400 });
    }

    const sessionId = body.sessionId ?? uuidv4();

    const { archetypeId, archetypeLabel, framing } = await classifyGoal(goalText, lang);
    const archetype = getArchetype(archetypeId);

    if (!archetype) {
      return NextResponse.json({ error: 'Could not classify activity' }, { status: 500 });
    }

    const session: Session = {
      sessionId,
      goalText,
      language: lang,
      currentStage: 'business',
      archetypeId,
      filledSlots: {
        activity: archetypeLabel,
        language: lang,
      },
      history: [],
    };

    const missing = computeMissing(archetypeId, 'business', session.filledSlots);
    const slotToAsk = missing[0] ?? 'businessStage';

    const card = await generateCard(
      slotToAsk,
      archetypeId,
      archetypeLabel,
      'business',
      session.filledSlots,
      [],
      lang
    );

    setServerSession(sessionId, {
      archetypeId,
      goalText,
      language: lang,
      filledSlots: session.filledSlots,
    });

    return NextResponse.json({
      sessionId,
      framing,
      activity: archetypeLabel,
      language: lang,
      session,
      card,
    });
  } catch (err) {
    console.error('/api/journey/start error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
