'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import Sidebar from '@/components/layout/Sidebar'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { user, isAdmin, isLoading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!isLoading && (!user || !isAdmin)) {
      router.push('/login')
    }
  }, [user, isAdmin, isLoading, router])

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
