'use client'

// Kept for pages that still use it — now mostly replaced by inline page headers.
// Pages that have their own header can omit this component.

import { Bell, Search } from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'

interface HeaderProps {
  title?: string
  subtitle?: string
  action?: React.ReactNode
  noBorder?: boolean
}

export default function Header({ title, subtitle, action, noBorder }: HeaderProps) {
  const { user } = useAuth()
  const initials = (user?.displayName || user?.email || 'A')
    .split(' ').map((w: string) => w[0]).join('').slice(0, 2).toUpperCase()

  return (
    <div className={"bg-white px-7 py-5 " + (noBorder ? '' : 'border-b border-gray-100')}>
      <div className="flex items-center justify-between gap-4">
        <div>
          {title && <h1 className="text-xl font-extrabold text-gray-900">{title}</h1>}
          {subtitle && <p className="text-xs text-gray-400 mt-0.5">{subtitle}</p>}
        </div>
        <div className="flex items-center gap-2 flex-shrink-0">
          <div className="relative hidden lg:block">
            <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input type="search" placeholder="Search…"
              className="pl-8 pr-3 py-2 text-xs border border-gray-200 rounded-xl bg-gray-50 focus:outline-none focus:ring-2 focus:ring-brand-600/20 focus:border-brand-600 w-40 focus:w-52 transition-all" />
          </div>
          <button className="relative p-2.5 text-gray-400 hover:text-gray-700 hover:bg-gray-100 rounded-xl transition-all">
            <Bell size={16} />
            <span className="absolute top-2 right-2 w-1.5 h-1.5 bg-red-500 rounded-full animate-pulse-dot" />
          </button>
          {action}
          <div className="w-8 h-8 rounded-xl bg-brand-600 flex items-center justify-center text-white text-xs font-bold">
            {initials}
          </div>
        </div>
      </div>
    </div>
  )
}
