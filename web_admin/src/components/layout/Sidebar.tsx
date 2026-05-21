'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard, Package, Tag, ShoppingBag, Ticket, ImageIcon,
  CreditCard, Truck, Bell, BarChart3, Users, HeadphonesIcon,
  FileText, LogOut, Zap, ChevronLeft,
} from 'lucide-react'
import { useState } from 'react'

const GROUPS = [
  {
    label: null,
    items: [{ name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard }],
  },
  {
    label: 'Catalogue',
    items: [
      { name: 'Products',   href: '/products',   icon: Package },
      { name: 'Categories', href: '/categories', icon: Tag },
      { name: 'Banners',    href: '/banners',    icon: ImageIcon },
      { name: 'Stock',      href: '/stock',      icon: BarChart3 },
    ],
  },
  {
    label: 'Commerce',
    items: [
      { name: 'Orders',          href: '/orders',          icon: ShoppingBag },
      { name: 'Coupons',         href: '/coupons',         icon: Ticket },
      { name: 'Payment Types',   href: '/payment-types',   icon: CreditCard },
      { name: 'Delivery Types',  href: '/delivery-types',  icon: Truck },
    ],
  },
  {
    label: 'Manage',
    items: [
      { name: 'Users',         href: '/users',         icon: Users },
      { name: 'Notifications', href: '/notifications', icon: Bell },
      { name: 'Support',       href: '/support',       icon: HeadphonesIcon },
      { name: 'Content',       href: '/content',       icon: FileText },
    ],
  },
]

export default function Sidebar() {
  const pathname  = usePathname()
  const { logout, user } = useAuth()
  const [collapsed, setCollapsed] = useState(false)

  const initials = (user?.displayName || user?.email || 'A')
    .split(' ').map((w: string) => w[0]).join('').slice(0, 2).toUpperCase()

  return (
    <aside
      className={cn(
        'flex flex-col h-screen sticky top-0 z-30 overflow-hidden transition-[width] duration-300 ease-in-out',
        'bg-white border-r border-gray-100',
        collapsed ? 'w-[64px]' : 'w-[220px]'
      )}
    >
      {/* ── Logo ──────────────────────────────────────────────────────────── */}
      <div className={cn(
        'flex items-center gap-2.5 h-16 px-4 border-b border-gray-100 flex-shrink-0',
        collapsed && 'justify-center px-2'
      )}>
        <div className="w-8 h-8 rounded-xl bg-brand-600 flex items-center justify-center flex-shrink-0 shadow-sm">
          <Zap size={15} className="text-white" fill="white" />
        </div>
        {!collapsed && (
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-gray-900 leading-tight">Forest Shoes</p>
            <p className="text-[10px] text-gray-400 uppercase tracking-widest">Admin</p>
          </div>
        )}
        <button
          onClick={() => setCollapsed(c => !c)}
          className="p-1 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-all flex-shrink-0 ml-auto"
        >
          <ChevronLeft size={13} className={cn('transition-transform duration-300', collapsed && 'rotate-180')} />
        </button>
      </div>

      {/* ── Nav ───────────────────────────────────────────────────────────── */}
      <nav className="flex-1 overflow-y-auto overflow-x-hidden py-4 px-2.5 space-y-5">
        {GROUPS.map((group, gi) => (
          <div key={gi}>
            {group.label && !collapsed && (
              <p className="px-2 mb-1.5 text-[10px] font-semibold uppercase tracking-[0.12em] text-gray-400">
                {group.label}
              </p>
            )}
            {group.label && collapsed && (
              <div className="mx-auto w-6 border-t border-gray-100 mb-2" />
            )}
            <div className="space-y-0.5">
              {group.items.map(item => {
                const active = pathname === item.href || pathname.startsWith(item.href + '/')
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    title={collapsed ? item.name : undefined}
                    className={cn(
                      'nav-link',
                      active ? 'nav-active' : 'nav-idle',
                      collapsed && 'justify-center px-0 py-2.5'
                    )}
                  >
                    {/* Active left indicator */}
                    {active && !collapsed && (
                      <span className="absolute left-0 top-1/2 -translate-y-1/2 h-4 w-[3px] bg-brand-600 rounded-r-full" />
                    )}
                    <item.icon
                      size={16}
                      className={cn('flex-shrink-0', active ? 'text-brand-600' : 'text-gray-400')}
                    />
                    {!collapsed && (
                      <span className="truncate">{item.name}</span>
                    )}
                  </Link>
                )
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* ── Upgrade card ──────────────────────────────────────────────────── */}
      {!collapsed && (
        <div className="mx-2.5 mb-3 rounded-xl bg-brand-600 p-3.5 text-white flex-shrink-0">
          <p className="text-xs font-semibold leading-snug">Upgrade to Pro</p>
          <p className="text-[10px] text-white/70 mt-0.5 mb-2.5 leading-relaxed">
            Unlock analytics, exports &amp; more.
          </p>
          <button className="w-full py-1.5 rounded-lg bg-white text-brand-600 text-[11px] font-semibold hover:bg-brand-50 transition-all">
            Upgrade
          </button>
        </div>
      )}

      {/* ── Footer ────────────────────────────────────────────────────────── */}
      <div className={cn(
        'flex-shrink-0 border-t border-gray-100 px-2.5 py-3',
        collapsed ? 'flex flex-col items-center gap-2' : 'space-y-1'
      )}>
        <button
          onClick={logout}
          title={collapsed ? 'Sign out' : undefined}
          className={cn(
            'nav-link w-full text-gray-400 hover:text-red-500 hover:bg-red-50',
            collapsed && 'justify-center px-0 py-2'
          )}
        >
          <LogOut size={15} className="flex-shrink-0" />
          {!collapsed && <span>Sign out</span>}
        </button>

        {!collapsed ? (
          <div className="flex items-center gap-2.5 px-2 py-2 rounded-xl bg-gray-50 border border-gray-100">
            <div className="w-7 h-7 rounded-lg bg-brand-600 flex items-center justify-center text-white text-[11px] font-bold flex-shrink-0">
              {initials}
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-[11px] font-semibold text-gray-800 truncate">{user?.displayName || 'Admin'}</p>
              <p className="text-[10px] text-gray-400 truncate">{user?.email}</p>
            </div>
          </div>
        ) : (
          <div className="w-7 h-7 rounded-lg bg-brand-600 flex items-center justify-center text-white text-[11px] font-bold">
            {initials}
          </div>
        )}
      </div>
    </aside>
  )
}
