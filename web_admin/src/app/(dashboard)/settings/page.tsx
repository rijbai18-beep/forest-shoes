'use client'

import { useEffect, useRef, useState } from 'react'
import { useBranding } from '@/contexts/BrandingContext'
import { useAuth } from '@/contexts/AuthContext'
import { collection, getDocs, query, where } from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { db, functions } from '@/lib/firebase'
import { User } from '@/types'
import { formatDate } from '@/lib/utils'
import {
  Upload, AlertCircle, CheckCircle2, Plus, ShieldCheck,
  ShieldOff, X, Eye, EyeOff,
} from 'lucide-react'
import toast from 'react-hot-toast'

export default function SettingsPage() {
  const { logoUrl, uploadLogo } = useBranding()
  const { user: currentUser } = useAuth()

  // ── Logo ──────────────────────────────────────────────────────────────────
  const [uploading, setUploading]   = useState(false)
  const [preview, setPreview]       = useState<string | null>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    const allowed = ['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp']
    if (!allowed.includes(file.type)) { toast.error('Please upload a PNG, JPG, SVG, or WebP image'); return }
    if (file.size > 2 * 1024 * 1024) { toast.error('Image must be under 2 MB'); return }
    const reader = new FileReader()
    reader.onload = (ev) => setPreview(ev.target?.result as string)
    reader.readAsDataURL(file)
    setUploading(true)
    try {
      await uploadLogo(file)
      toast.success('Logo updated — changes reflect across both apps immediately.')
      setPreview(null)
    } catch {
      toast.error('Upload failed. Check your connection and try again.')
    } finally {
      setUploading(false)
      if (fileRef.current) fileRef.current.value = ''
    }
  }

  const displayUrl = preview ?? logoUrl ?? '/favicon.svg'

  // ── Admin Access ──────────────────────────────────────────────────────────
  const [admins, setAdmins]             = useState<User[]>([])
  const [loadingAdmins, setLoadingAdmins] = useState(true)
  const [showModal, setShowModal]       = useState(false)
  const [form, setForm]                 = useState({ name: '', email: '', password: '' })
  const [showPw, setShowPw]             = useState(false)
  const [adding, setAdding]             = useState(false)
  const [revokingUid, setRevokingUid]   = useState<string | null>(null)

  useEffect(() => { loadAdmins() }, [])

  async function loadAdmins() {
    setLoadingAdmins(true)
    try {
      const snap = await getDocs(query(collection(db, 'users'), where('isAdmin', '==', true)))
      const list = snap.docs
        .map(d => ({ uid: d.id, ...d.data() } as User))
        .sort((a, b) => (a.createdAt?.toMillis?.() ?? 0) - (b.createdAt?.toMillis?.() ?? 0))
      setAdmins(list)
    } finally {
      setLoadingAdmins(false)
    }
  }

  function closeModal() {
    setShowModal(false)
    setForm({ name: '', email: '', password: '' })
    setShowPw(false)
  }

  async function handleAddAdmin(e: React.FormEvent) {
    e.preventDefault()
    setAdding(true)
    try {
      await httpsCallable(functions, 'createAdminUser')(form)
      toast.success(`Admin account created for ${form.email}`)
      closeModal()
      await loadAdmins()
    } catch (err: any) {
      toast.error(err.message || 'Failed to create admin account')
    } finally {
      setAdding(false)
    }
  }

  async function handleRevoke(u: User) {
    if (!confirm(`Remove admin access for ${u.name}?\n\nThey will no longer be able to sign in to the admin panel.`)) return
    setRevokingUid(u.uid)
    try {
      await httpsCallable(functions, 'setAdminRole')({ uid: u.uid, isAdmin: false })
      setAdmins(prev => prev.filter(a => a.uid !== u.uid))
      toast.success(`Admin access revoked for ${u.name}`)
    } catch (err: any) {
      toast.error(err.message || 'Failed to revoke access')
    } finally {
      setRevokingUid(null)
    }
  }

  return (
    <>
      <div className="p-6 max-w-2xl space-y-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
          <p className="text-sm text-gray-500 mt-1">Manage brand assets and app configuration</p>
        </div>

        {/* ── Brand Logo ──────────────────────────────────────────── */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-sm font-semibold text-gray-800 mb-0.5">Brand Logo</h2>
          <p className="text-xs text-gray-400 mb-5 leading-relaxed">
            Used as the app icon on splash, login &amp; home screens in the mobile app, in the admin
            sidebar, and as the web favicon. Upload a square image (PNG, SVG, or WebP) — minimum
            256 × 256 px.
          </p>

          <div className="flex items-start gap-6">
            <div className="flex-shrink-0 text-center">
              <p className="text-[10px] text-gray-400 uppercase tracking-widest mb-2">
                {preview ? 'Preview' : logoUrl ? 'Current' : 'Default'}
              </p>
              <div className={`w-24 h-24 rounded-2xl border-2 flex items-center justify-center overflow-hidden bg-gray-50
                ${preview ? 'border-brand-300' : 'border-gray-100'}`}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={displayUrl} alt="Logo preview" className="w-full h-full object-contain p-1.5"
                  onError={(e) => { (e.target as HTMLImageElement).src = '/favicon.svg' }} />
              </div>
              {logoUrl && !preview && (
                <span className="inline-flex items-center gap-1 mt-1.5 text-[10px] text-green-600 font-medium">
                  <CheckCircle2 size={10} /> Custom
                </span>
              )}
            </div>

            <div className="flex-1 min-w-0">
              <input ref={fileRef} type="file" accept="image/png,image/jpeg,image/svg+xml,image/webp"
                onChange={handleFile} className="hidden" id="logo-upload" disabled={uploading} />
              <label htmlFor="logo-upload"
                className={`flex items-center gap-2.5 px-4 py-3 rounded-xl border-2 border-dashed transition-all
                  ${uploading
                    ? 'border-gray-200 bg-gray-50 cursor-not-allowed opacity-60'
                    : 'border-brand-200 bg-brand-50 hover:bg-brand-100 hover:border-brand-400 cursor-pointer'
                  }`}>
                {uploading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-brand-400 border-t-transparent rounded-full animate-spin flex-shrink-0" />
                    <span className="text-sm text-brand-700 font-medium">Uploading…</span>
                  </>
                ) : (
                  <>
                    <Upload size={16} className="text-brand-600 flex-shrink-0" />
                    <span className="text-sm text-brand-700 font-medium">Choose new logo</span>
                  </>
                )}
              </label>

              <div className="mt-3 flex items-start gap-1.5 text-[11px] text-gray-400 leading-relaxed">
                <AlertCircle size={12} className="mt-0.5 flex-shrink-0" />
                <span>
                  After uploading, the admin panel updates instantly. The mobile app picks up the new
                  logo on next launch (cached for 7 days).
                </span>
              </div>

              <div className="mt-3 flex flex-wrap gap-1.5">
                {['PNG', 'JPG', 'SVG', 'WebP'].map((fmt) => (
                  <span key={fmt} className="px-2 py-0.5 rounded-md bg-gray-100 text-gray-500 text-[10px] font-medium">
                    {fmt}
                  </span>
                ))}
                <span className="px-2 py-0.5 rounded-md bg-gray-100 text-gray-500 text-[10px] font-medium">Max 2 MB</span>
              </div>
            </div>
          </div>
        </div>

        {/* ── Admin Access ─────────────────────────────────────────── */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <div className="flex items-start justify-between mb-5">
            <div>
              <h2 className="text-sm font-semibold text-gray-800">Admin Access</h2>
              <p className="text-xs text-gray-400 mt-0.5 leading-relaxed">
                Control who can sign in to the admin panel.
              </p>
            </div>
            <button
              onClick={() => setShowModal(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-brand-600 text-white text-xs font-semibold hover:bg-brand-700 transition-colors flex-shrink-0"
            >
              <Plus size={13} />
              Add Admin
            </button>
          </div>

          {loadingAdmins ? (
            <div className="flex justify-center py-10">
              <div className="w-6 h-6 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
            </div>
          ) : admins.length === 0 ? (
            <p className="text-center text-gray-400 text-sm py-10">No admin accounts found</p>
          ) : (
            <div className="space-y-2">
              {admins.map(u => (
                <div key={u.uid}
                  className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 border border-gray-100 hover:border-gray-200 transition-colors">

                  {/* Avatar */}
                  <div className="w-9 h-9 rounded-xl bg-brand-600 flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                    {(u.name || u.email || 'A').slice(0, 1).toUpperCase()}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <p className="text-sm font-semibold text-gray-900 truncate">{u.name || '—'}</p>
                      {u.uid === currentUser?.uid && (
                        <span className="text-[9px] bg-brand-50 text-brand-600 font-bold px-1.5 py-0.5 rounded border border-brand-100 uppercase tracking-wide">
                          You
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-gray-400 truncate">{u.email}</p>
                  </div>

                  {/* Meta + actions */}
                  <div className="flex items-center gap-2 flex-shrink-0">
                    {u.createdAt && (
                      <span className="text-[10px] text-gray-300 hidden md:block">{formatDate(u.createdAt)}</span>
                    )}
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-green-50 border border-green-100">
                      <ShieldCheck size={11} className="text-green-600" />
                      <span className="text-[10px] font-semibold text-green-700">Admin</span>
                    </span>
                    <button
                      onClick={() => handleRevoke(u)}
                      disabled={u.uid === currentUser?.uid || revokingUid === u.uid}
                      title={u.uid === currentUser?.uid ? "Can't revoke your own access" : 'Revoke admin access'}
                      className="p-1.5 rounded-lg text-gray-300 hover:text-red-500 hover:bg-red-50 transition-colors disabled:opacity-25 disabled:cursor-not-allowed"
                    >
                      {revokingUid === u.uid ? (
                        <div className="w-3.5 h-3.5 border border-red-400 border-t-transparent rounded-full animate-spin" />
                      ) : (
                        <ShieldOff size={14} />
                      )}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          <p className="text-[11px] text-gray-300 mt-4 leading-relaxed">
            Admin accounts have full access to all sections of this panel. You cannot revoke your own access.
          </p>
        </div>
      </div>

      {/* ── Add Admin Modal ──────────────────────────────────────────────────── */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
            {/* Header */}
            <div className="flex items-start justify-between p-6 pb-4">
              <div>
                <h3 className="text-base font-bold text-gray-900">Add Admin User</h3>
                <p className="text-xs text-gray-400 mt-0.5">
                  They will have full access to this admin panel.
                </p>
              </div>
              <button onClick={closeModal}
                className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 transition-colors -mt-0.5">
                <X size={16} />
              </button>
            </div>

            {/* Divider */}
            <div className="h-px bg-gray-100 mx-6" />

            {/* Form */}
            <form onSubmit={handleAddAdmin} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5">Full Name</label>
                <input
                  type="text"
                  value={form.name}
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                  className="input-field"
                  placeholder="Jane Doe"
                  autoFocus
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5">Email Address</label>
                <input
                  type="email"
                  value={form.email}
                  onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                  className="input-field"
                  placeholder="admin@forestshoes.mu"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5">Password</label>
                <div className="relative">
                  <input
                    type={showPw ? 'text' : 'password'}
                    value={form.password}
                    onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                    className="input-field pr-11"
                    placeholder="Minimum 8 characters"
                    minLength={8}
                    required
                  />
                  <button type="button" onClick={() => setShowPw(s => !s)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors">
                    {showPw ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
                <p className="text-[10px] text-gray-400 mt-1.5">
                  Share this password with the new admin. They can change it after first login.
                </p>
              </div>

              {/* Info banner */}
              <div className="flex items-start gap-2.5 p-3 rounded-xl bg-amber-50 border border-amber-100">
                <ShieldCheck size={14} className="text-amber-500 mt-0.5 flex-shrink-0" />
                <p className="text-[11px] text-amber-700 leading-relaxed">
                  This account will have <strong>full admin access</strong> — including the ability to create and revoke other admins.
                </p>
              </div>

              <div className="flex gap-2 pt-1">
                <button type="button" onClick={closeModal}
                  className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm text-gray-600 font-medium hover:bg-gray-50 transition-colors">
                  Cancel
                </button>
                <button type="submit" disabled={adding}
                  className="flex-1 py-2.5 rounded-xl bg-brand-600 text-white text-sm font-semibold hover:bg-brand-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2">
                  {adding ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                      Creating…
                    </>
                  ) : (
                    <>
                      <ShieldCheck size={15} />
                      Create Admin
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  )
}
