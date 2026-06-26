import type { ServerSession, SupportedLang } from './types';
export type { SupportedLang };

declare global {
  // eslint-disable-next-line no-var
  var __irshadSessions: Map<string, ServerSession> | undefined;
}

function getStore(): Map<string, ServerSession> {
  if (!global.__irshadSessions) {
    global.__irshadSessions = new Map();
  }
  return global.__irshadSessions;
}

export function getServerSession(sessionId: string): ServerSession | undefined {
  return getStore().get(sessionId);
}

export function setServerSession(sessionId: string, data: ServerSession): void {
  getStore().set(sessionId, data);
}

export function updateServerSession(sessionId: string, patch: Partial<ServerSession>): void {
  const existing = getStore().get(sessionId);
  if (existing) {
    getStore().set(sessionId, { ...existing, ...patch });
  }
}
