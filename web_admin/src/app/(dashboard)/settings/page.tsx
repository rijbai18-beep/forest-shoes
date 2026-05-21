'use client'

import { useRef, useState } from 'react'
import { useBranding } from '@/contexts/BrandingContext'
import { Upload, AlertCircle, CheckCircle2 } from 'lucide-react'
import toast from 'react-hot-toast'

export default function SettingsPage() {
  const { logoUrl, uploadLogo } = useBranding()
  const [uploading, setUploading] = useState(false)
  const [preview, setPreview] = useState<string | null>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const allowed = ['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp']
    if (!allowed.includes(file.type)) {
      toast.error('Please upload a PNG, JPG, SVG, or WebP image')
      return
    }
    if (file.size > 2 * 1024 * 1024) {
      toast.error('Image must be under 2 MB')
      return
    }

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

  return (
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
          {/* Preview tile */}
          <div className="flex-shrink-0 text-center">
            <p className="text-[10px] text-gray-400 uppercase tracking-widest mb-2">
              {preview ? 'Preview' : logoUrl ? 'Current' : 'Default'}
            </p>
            <div className={`w-24 h-24 rounded-2xl border-2 flex items-center justify-center overflow-hidden bg-gray-50
              ${preview ? 'border-brand-300' : 'border-gray-100'}`}
            >
              <img
                src={displayUrl}
                alt="Logo preview"
                className="w-full h-full object-contain p-1.5"
                onError={(e) => { (e.target as HTMLImageElement).src = '/favicon.svg' }}
              />
            </div>
            {logoUrl && !preview && (
              <span className="inline-flex items-center gap-1 mt-1.5 text-[10px] text-green-600 font-medium">
                <CheckCircle2 size={10} /> Custom
              </span>
            )}
          </div>

          {/* Upload */}
          <div className="flex-1 min-w-0">
            <input
              ref={fileRef}
              type="file"
              accept="image/png,image/jpeg,image/svg+xml,image/webp"
              onChange={handleFile}
              className="hidden"
              id="logo-upload"
              disabled={uploading}
            />
            <label
              htmlFor="logo-upload"
              className={`flex items-center gap-2.5 px-4 py-3 rounded-xl border-2 border-dashed transition-all
                ${uploading
                  ? 'border-gray-200 bg-gray-50 cursor-not-allowed opacity-60'
                  : 'border-brand-200 bg-brand-50 hover:bg-brand-100 hover:border-brand-400 cursor-pointer'
                }`}
            >
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
                <span key={fmt}
                  className="px-2 py-0.5 rounded-md bg-gray-100 text-gray-500 text-[10px] font-medium">
                  {fmt}
                </span>
              ))}
              <span className="px-2 py-0.5 rounded-md bg-gray-100 text-gray-500 text-[10px] font-medium">
                Max 2 MB
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
