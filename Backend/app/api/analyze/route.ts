import { NextRequest, NextResponse } from 'next/server';
import { runAnalysis } from '@/lib/llm';
import { updateServerSession } from '@/lib/session';
import type { Session } from '@/lib/types';

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

    const analysis = await runAnalysis(session);

    updateServerSession(session.sessionId, {
      archetypeId: session.archetypeId,
      goalText: session.goalText,
      language: session.language ?? 'en',
      filledSlots: session.filledSlots,
      analysisResult: analysis,
    });

    return NextResponse.json({ analysis, nextStage: 'verify' });
  } catch (err) {
    console.error('/api/analyze error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
