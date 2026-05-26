import { collection, addDoc, serverTimestamp } from 'firebase/firestore'
import { db, auth } from '@/lib/firebase'

type AuditType = 'action' | 'error'
type Platform = 'web_admin'

function write(payload: Record<string, unknown>) {
  addDoc(collection(db, 'audit_logs'), {
    ...payload,
    timestamp: serverTimestamp(),
  }).catch(() => {}) // fire-and-forget; never block the caller
}

export function logAction(action: string, details?: Record<string, unknown>) {
  const user = auth.currentUser
  write({
    type: 'action' as AuditType,
    platform: 'web_admin' as Platform,
    userId: user?.uid ?? null,
    userEmail: user?.email ?? null,
    action,
    details: details ?? null,
    errorMessage: null,
    stackTrace: null,
  })
}

export function logError(error: unknown, context = 'uncaught_error', details?: Record<string, unknown>) {
  const user = auth.currentUser
  const message = error instanceof Error ? error.message : String(error)
  const stack = error instanceof Error ? (error.stack ?? null) : null
  write({
    type: 'error' as AuditType,
    platform: 'web_admin' as Platform,
    userId: user?.uid ?? null,
    userEmail: user?.email ?? null,
    action: context,
    details: details ?? null,
    errorMessage: message,
    stackTrace: stack,
  })
}
