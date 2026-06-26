import { NextRequest, NextResponse } from 'next/server';
import { runBankingRec } from '@/lib/llm';
import { getServerSession, updateServerSession } from '@/lib/session';
import type { Session } from '@/lib/types';

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' },
  });
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json() as { sessionId: string };
    const { sessionId } = body;

    if (!sessionId) {
      return NextResponse.json({ error: 'sessionId is required' }, { status: 400 });
    }

    const serverSession = getServerSession(sessionId);
    if (!serverSession) {
      return NextResponse.json({ error: 'Session not found — run /api/analyze first' }, { status: 404 });
    }

    const syntheticSession: Session = {
      sessionId,
      goalText: serverSession.goalText,
      language: serverSession.language ?? 'en',
      currentStage: 'documents',
      archetypeId: serverSession.archetypeId,
      filledSlots: serverSession.filledSlots,
      history: [],
    };

    const bankingResult = await runBankingRec(syntheticSession);

    updateServerSession(sessionId, { bankingResult });

    return NextResponse.json({ banking: bankingResult, nextStage: 'plan' });
  } catch (err) {
    console.error('/api/banking error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
