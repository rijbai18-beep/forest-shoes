'use client'

import { createContext, useContext, useEffect, useRef, useCallback, useState } from 'react'
import { User, onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '@/lib/firebase'
import { logAction, logError } from '@/lib/audit'
import { useRouter } from 'next/navigation'
import toast from 'react-hot-toast'

const IDLE_TIMEOUT = 5 * 60 * 1000
const WARN_BEFORE = 60 * 1000

const ACTIVITY_EVENTS = ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart'] as const

interface AuthContextType {
  user: User | null
  isAdmin: boolean
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()

  const idleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const warnTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const warnToastIdRef = useRef<string | null>(null)
  const lastActivityRef = useRef(0)

  const clearTimers = useCallback(() => {
    if (idleTimerRef.current) { clearTimeout(idleTimerRef.current); idleTimerRef.current = null }
    if (warnTimerRef.current) { clearTimeout(warnTimerRef.current); warnTimerRef.current = null }
    if (warnToastIdRef.current) { toast.dismiss(warnToastIdRef.current); warnToastIdRef.current = null }
  }, [])

  const logout = useCallback(async () => {
    logAction('admin.logout')
    clearTimers()
    await signOut(auth)
    router.push('/login')
  }, [clearTimers, router])

  const resetIdleTimer = useCallback(() => {
    const now = Date.now()
    if (now - lastActivityRef.current < 500) return
    lastActivityRef.current = now
    clearTimers()
    warnTimerRef.current = setTimeout(() => {
      warnToastIdRef.current = toast(
        'You will be logged out in 1 minute due to inactivity.',
        { duration: WARN_BEFORE }
      ) as string
    }, IDLE_TIMEOUT - WARN_BEFORE)
    idleTimerRef.current = setTimeout(logout, IDLE_TIMEOUT)
  }, [clearTimers, logout])

  useEffect(() => {
    if (!user) {
      clearTimers()
      return
    }
    resetIdleTimer()
    const onActivity = () => resetIdleTimer()
    ACTIVITY_EVENTS.forEach(ev => window.addEventListener(ev, onActivity, { passive: true }))
    return () => {
      clearTimers()
      ACTIVITY_EVENTS.forEach(ev => window.removeEventListener(ev, onActivity))
    }
  }, [user, resetIdleTimer, clearTimers])

  useEffect(() => {
    const onError = (event: ErrorEvent) => {
      logError(event.error ?? event.message, 'window.onerror', { message: event.message })
    }
    const onUnhandled = (event: PromiseRejectionEvent) => {
      logError(event.reason, 'unhandled_rejection')
    }
    window.addEventListener('error', onError)
    window.addEventListener('unhandledrejection', onUnhandled)
    return () => {
      window.removeEventListener('error', onError)
      window.removeEventListener('unhandledrejection', onUnhandled)
    }
  }, [])

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        const tokenResult = await firebaseUser.getIdTokenResult()
        const isAdminUser = tokenResult.claims.admin === true

        if (!isAdminUser) {
          const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid))
          const userData = userDoc.data()
          if (!userData?.isAdmin) {
            await signOut(auth)
            setUser(null)
            setIsAdmin(false)
            setIsLoading(false)
            return
          }
        }

        setUser(firebaseUser)
        setIsAdmin(true)
      } else {
        setUser(null)
        setIsAdmin(false)
      }
      setIsLoading(false)
    })
    return unsub
  }, [])

  const login = async (email: string, password: string) => {
    try {
      const cred = await signInWithEmailAndPassword(auth, email, password)
      const tokenResult = await cred.user.getIdTokenResult()
      const isAdminUser = tokenResult.claims.admin === true

      if (!isAdminUser) {
        const userDoc = await getDoc(doc(db, 'users', cred.user.uid))
        if (!userDoc.data()?.isAdmin) {
          await signOut(auth)
          logError(new Error('Access denied'), 'admin.login_denied', { email })
          throw new Error('Access denied. Admin accounts only.')
        }
      }

      logAction('admin.login', { email })
      router.push('/dashboard')
    } catch (e) {
      if (!(e instanceof Error && e.message === 'Access denied. Admin accounts only.')) {
        logError(e, 'admin.login_failed', { email })
      }
      throw e
    }
  }

  return (
    <AuthContext.Provider value={{ user, isAdmin, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
