'use client'

import { createContext, useContext, useEffect, useState } from 'react'
import { User, onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '@/lib/firebase'
import { useRouter } from 'next/navigation'

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

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        const tokenResult = await firebaseUser.getIdTokenResult()
        const isAdminUser = tokenResult.claims.admin === true

        if (!isAdminUser) {
          // Also check Firestore as fallback
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
    const cred = await signInWithEmailAndPassword(auth, email, password)
    const tokenResult = await cred.user.getIdTokenResult()
    const isAdminUser = tokenResult.claims.admin === true

    if (!isAdminUser) {
      const userDoc = await getDoc(doc(db, 'users', cred.user.uid))
      if (!userDoc.data()?.isAdmin) {
        await signOut(auth)
        throw new Error('Access denied. Admin accounts only.')
      }
    }

    router.push('/dashboard')
  }

  const logout = async () => {
    await signOut(auth)
    router.push('/login')
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
