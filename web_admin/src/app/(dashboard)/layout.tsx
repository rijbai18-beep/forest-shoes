'use client'

import { useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { signOut } from 'firebase/auth'
import { auth } from '@/lib/firebase'
import { useAuth } from '@/contexts/AuthContext'
import { useBranding } from '@/contexts/BrandingContext'
import Sidebar from '@/components/layout/Sidebar'

const SESSION_TIMEOUT_MS = 5 * 60 * 1000 // 5 minutes

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { user, isAdmin, isLoading } = useAuth()
  const { logoUrl } = useBranding()
  const router = useRouter()
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  // Dynamically update the browser favicon when a custom logo is set
  useEffect(() => {
    if (!logoUrl) return
    const link = (document.querySelector("link[rel~='icon']") as HTMLLinkElement) ??
      Object.assign(document.createElement('link'), { rel: 'icon' })
    link.type = 'image/png'
    link.href = logoUrl
    document.head.appendChild(link)
  }, [logoUrl])

  useEffect(() => {
    if (!isLoading && (!user || !isAdmin)) {
      router.push('/login')
    }
  }, [user, isAdmin, isLoading, router])

  // Session timeout: sign out after 5 minutes of inactivity
  useEffect(() => {
    if (!user) return

    const resetTimer = () => {
      if (timerRef.current) clearTimeout(timerRef.current)
      timerRef.current = setTimeout(async () => {
        await signOut(auth)
        router.push('/login?timeout=true')
      }, SESSION_TIMEOUT_MS)
    }

    const events = ['mousemove', 'keydown', 'click', 'touchstart', 'scroll'] as const
    events.forEach(e => window.addEventListener(e, resetTimer, { passive: true }))
    resetTimer() // start the initial timer on mount

    return () => {
      events.forEach(e => window.removeEventListener(e, resetTimer))
      if (timerRef.current) clearTimeout(timerRef.current)
    }
  }, [user, router])

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F4F6FA]">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
          <p className="text-sm text-gray-400">Loading admin panel…</p>
        </div>
      </div>
    )
  }

  if (!user || !isAdmin) return null

  return (
    <div className="flex h-screen overflow-hidden bg-[#F4F6FA]">
      <Sidebar />
      <main className="flex-1 overflow-y-auto min-w-0">
        {children}
      </main>
    </div>
  )
}
