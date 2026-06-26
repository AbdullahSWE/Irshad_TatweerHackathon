import { NextRequest, NextResponse } from 'next/server';
import { runVerify } from '@/lib/llm';
import { getServerSession, updateServerSession } from '@/lib/session';

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' },
  });
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json() as { sessionId: string; verifyTarget?: string };
    const { sessionId, verifyTarget } = body;

    if (!sessionId) {
      return NextResponse.json({ error: 'sessionId is required' }, { status: 400 });
    }

    const serverSession = getServerSession(sessionId);
    if (!serverSession) {
      return NextResponse.json({ error: 'Session not found — run /api/analyze first' }, { status: 404 });
    }

    const candidateLicenses = serverSession.analysisResult?.candidateLicenses ?? [];
    const lang = serverSession.language ?? 'en';
    const target = verifyTarget || `${candidateLicenses[0] ?? 'business license'} fee and requirements 2025 Abu Dhabi`;

    const result = await runVerify(target, serverSession.archetypeId, candidateLicenses, lang);

    updateServerSession(sessionId, { verifyResult: result });

    return NextResponse.json(result);
  } catch (err) {
    console.error('/api/verify error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
