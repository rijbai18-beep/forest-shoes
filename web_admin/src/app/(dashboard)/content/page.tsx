'use client'

import { useEffect, useState } from 'react'
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import toast from 'react-hot-toast'
import { FileText, Save } from 'lucide-react'

const CONTENT_TYPES = [
  { key: 'terms', label: 'Terms & Conditions', icon: '📋' },
  { key: 'privacy', label: 'Privacy Policy', icon: '🔒' },
  { key: 'dataPrivacy', label: 'Data Privacy', icon: '🛡️' },
  { key: 'about', label: 'About Us', icon: '🌿' },
] as const

type ContentKey = typeof CONTENT_TYPES[number]['key']

export default function ContentPage() {
  const [activeTab, setActiveTab] = useState<ContentKey>('terms')
  const [contents, setContents] = useState<Record<ContentKey, string>>({
    terms: '', privacy: '', dataPrivacy: '', about: ''
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => { loadAll() }, [])

  async function loadAll() {
    const results = await Promise.all(
      CONTENT_TYPES.map(ct => getDoc(doc(db, 'content', ct.key)))
    )
    const loaded = {} as Record<ContentKey, string>
    CONTENT_TYPES.forEach((ct, i) => {
      loaded[ct.key] = results[i].exists() ? (results[i].data()?.body ?? '') : ''
    })
    setContents(loaded)
    setLoading(false)
  }

  async function save() {
    setSaving(true)
    try {
      await setDoc(doc(db, 'content', activeTab), {
        body: contents[activeTab],
        type: activeTab,
        updatedAt: serverTimestamp(),
      })
      toast.success(`${CONTENT_TYPES.find(ct => ct.key === activeTab)?.label} saved`)
    } catch {
      toast.error('Failed to save')
    } finally {
      setSaving(false)
    }
  }

  const active = CONTENT_TYPES.find(ct => ct.key === activeTab)!

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Content Management</h1>
        <p className="text-sm text-gray-400 mt-1">Manage app content — Terms, Privacy Policy, and About sections</p>
      </div>
      <div>
        <div className="flex gap-5 h-[calc(100vh-12rem)]">
          {/* Sidebar tabs */}
          <div className="w-56 flex-shrink-0">
            <div className="card p-2 space-y-1">
              {CONTENT_TYPES.map(ct => (
                <button
                  key={ct.key}
                  onClick={() => setActiveTab(ct.key)}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left text-sm transition-colors ${
                    activeTab === ct.key
                      ? 'bg-[#6c63ff] text-white font-medium'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-base">{ct.icon}</span>
                  <span className="leading-tight">{ct.label}</span>
                </button>
              ))}
            </div>
            <div className="mt-4 p-3 bg-blue-50 rounded-xl text-xs text-blue-700 space-y-1">
              <p className="font-medium">Formatting tips</p>
              <p>Use plain text or Markdown. The mobile app renders this content as-is.</p>
              <p className="mt-1">Use blank lines between sections for readability.</p>
            </div>
          </div>

          {/* Editor */}
          <div className="flex-1 flex flex-col card overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-xl">{active.icon}</span>
                <h3 className="font-semibold text-gray-900">{active.label}</h3>
              </div>
              <button onClick={save} disabled={saving || loading} className="btn-primary flex items-center gap-2">
                <Save size={15} /> {saving ? 'Saving...' : 'Save'}
              </button>
            </div>

            {loading ? (
              <div className="flex-1 flex items-center justify-center text-gray-400">Loading content...</div>
            ) : (
              <textarea
                value={contents[activeTab]}
                onChange={e => setContents(c => ({ ...c, [activeTab]: e.target.value }))}
                className="flex-1 w-full p-4 text-sm text-gray-700 font-mono leading-relaxed resize-none focus:outline-none"
                placeholder={`Enter ${active.label} content here...\n\nYou can use plain text or markdown formatting.`}
                spellCheck
              />
            )}

            {/* Footer: char count */}
            <div className="px-4 py-2 border-t border-gray-100 text-xs text-gray-400 flex justify-between">
              <span>{contents[activeTab].length.toLocaleString()} characters</span>
              <span>{contents[activeTab].split('\n').length} lines</span>
            </div>
          </div>

          {/* Preview */}
          <div className="w-72 flex-shrink-0 flex flex-col card overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex items-center gap-2">
              <FileText size={16} className="text-gray-400" />
              <h3 className="text-sm font-semibold text-gray-700">Mobile Preview</h3>
            </div>
            <div className="flex-1 overflow-y-auto p-4">
              <div className="bg-gray-900 rounded-[2rem] p-4 min-h-64 text-white">
                <div className="bg-gray-800 rounded-2xl p-3">
                  <p className="text-xs text-gray-400 mb-1 text-center">{active.label}</p>
                  <div className="text-xs text-gray-200 leading-relaxed whitespace-pre-wrap max-h-96 overflow-hidden">
                    {contents[activeTab] || <span className="text-gray-500 italic">No content yet</span>}
                  </div>
                  {contents[activeTab].length > 500 && (
                    <p className="text-xs text-gray-500 mt-2 text-center">…scrollable in app</p>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
