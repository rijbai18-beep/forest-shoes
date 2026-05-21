'use client'

import { useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { useBranding } from '@/contexts/BrandingContext'
import { Eye, EyeOff, ShieldCheck } from 'lucide-react'

export default function LoginPage() {
  const { login } = useAuth()
  const { logoUrl } = useBranding()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      await login(email, password)
    } catch (err: any) {
      setError(err.message || 'Login failed. Please check your credentials.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex" style={{ background: 'linear-gradient(135deg, #201e66 0%, #1a3c1f 50%, #6c63ff 100%)' }}>
      {/* Left decorative panel */}
      <div className="hidden lg:flex flex-col justify-between flex-1 p-12 text-white relative overflow-hidden">
        <div className="absolute inset-0 opacity-10"
          style={{ backgroundImage: 'radial-gradient(circle at 20% 50%, #4CAF50 0%, transparent 50%), radial-gradient(circle at 80% 20%, #81C784 0%, transparent 40%)' }} />
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white/15 rounded-2xl flex items-center justify-center backdrop-blur-sm border border-white/20 overflow-hidden">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={logoUrl ?? '/favicon.svg'} alt="Forest Shoes" className="w-7 h-7 object-contain"
                onError={(e) => { (e.target as HTMLImageElement).src = '/favicon.svg' }} />
            </div>
            <span className="text-xl font-bold">Forest Shoes</span>
          </div>
        </div>
        <div className="relative z-10 space-y-4">
          <h2 className="text-4xl font-extrabold leading-tight">
            Manage your<br />store with ease.
          </h2>
          <p className="text-white/60 text-lg max-w-xs">
            Products, orders, customers — everything you need in one place.
          </p>
        </div>
        <div className="relative z-10 flex items-center gap-2 text-white/40 text-xs">
          <ShieldCheck size={14} />
          <span>Secured admin access</span>
        </div>
      </div>

      {/* Right login card */}
      <div className="flex items-center justify-center w-full lg:w-[480px] p-6 bg-white">
        <div className="w-full max-w-sm">
          {/* Mobile logo */}
          <div className="lg:hidden text-center mb-8">
            <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl mb-3 overflow-hidden bg-brand-600">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={logoUrl ?? '/favicon.svg'} alt="Forest Shoes" className="w-10 h-10 object-contain"
                onError={(e) => { (e.target as HTMLImageElement).src = '/favicon.svg' }} />
            </div>
            <p className="text-sm text-gray-500">Forest Shoes Admin</p>
          </div>

          <h1 className="text-2xl font-extrabold text-gray-900 mb-1">Welcome back</h1>
          <p className="text-sm text-gray-400 mb-8">Sign in to your admin account</p>

          {error && (
            <div className="mb-5 flex items-start gap-2.5 p-3.5 bg-red-50 border border-red-200 rounded-xl">
              <span className="text-red-500 mt-0.5 flex-shrink-0">⚠</span>
              <p className="text-sm text-red-700">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Email Address</label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                className="input-field"
                placeholder="admin@forestshoes.mu"
                autoComplete="email"
                required
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-xs font-semibold text-gray-600">Password</label>
              </div>
              <div className="relative">
                <input
                  type={showPass ? 'text' : 'password'}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  className="input-field pr-11"
                  placeholder="••••••••"
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPass(s => !s)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                >
                  {showPass ? <EyeOff size={17} /> : <Eye size={17} />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full py-3 text-sm mt-2 disabled:opacity-60"
            >
              {loading ? (
                <span className="flex items-center gap-2">
                  <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  Signing in…
                </span>
              ) : 'Sign In'}
            </button>
          </form>

          <p className="text-center text-[11px] text-gray-300 mt-10">
            Forest Shoes Admin — Authorized Personnel Only
          </p>
        </div>
      </div>
    </div>
  )
}
