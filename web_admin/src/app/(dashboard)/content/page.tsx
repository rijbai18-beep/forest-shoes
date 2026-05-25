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

// Default template text — shown in the editor when no content has been saved yet.
// Matches what the mobile app displays as a fallback.
const TEMPLATES: Record<ContentKey, string> = {
  terms: `Terms & Conditions

Last updated: January 2025

1. ACCEPTANCE OF TERMS
By accessing or using the Forest Shoes mobile application, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use our services.

2. USE OF THE APP
You must be at least 18 years old to place orders. You agree to provide accurate information during registration and checkout. Forest Shoes reserves the right to cancel orders at its discretion.

3. PRODUCTS & PRICING
All prices are displayed in Mauritian Rupees (Rs) and are inclusive of applicable taxes. We reserve the right to modify prices without prior notice. Product images are for illustrative purposes only.

4. ORDERS & PAYMENT
Orders are confirmed upon receipt of payment. We accept cash on delivery and bank transfers. Forest Shoes is not responsible for delays caused by payment providers.

5. DELIVERY
Delivery timelines are estimates only. We are not liable for delays caused by courier services or unforeseen circumstances.

6. RETURNS & REFUNDS
Items may be returned within 7 days of delivery in original, unused condition. Refunds are processed within 5–7 business days.

7. INTELLECTUAL PROPERTY
All content on this app, including logos and images, is the property of Forest Shoes and may not be reproduced without written permission.

8. LIMITATION OF LIABILITY
Forest Shoes shall not be liable for any indirect or consequential damages arising from the use of our services.

9. CONTACT
For queries, contact us at support@forestshoes.mu`,

  privacy: `Privacy Policy

Last updated: January 2025

1. INFORMATION WE COLLECT
We collect personal information you provide directly, such as your name, email address, phone number, and delivery address. We also collect usage data to improve the app experience.

2. HOW WE USE YOUR INFORMATION
- To process and fulfil your orders
- To send order confirmations and updates
- To provide customer support
- To send promotional notifications (with your consent)

3. SHARING YOUR INFORMATION
We do not sell your personal data. We share information only with service providers necessary to operate our services (e.g., delivery partners), and only to the extent required.

4. DATA RETENTION
We retain your personal data as long as your account is active or as required by law.

5. YOUR RIGHTS
You have the right to access, correct, or delete your personal data at any time by contacting us.

6. SECURITY
We use industry-standard security measures to protect your data. However, no method of transmission over the internet is 100% secure.

7. COOKIES
The app does not use cookies. Firebase services may collect anonymised analytics data.

8. CONTACT
For privacy-related requests, contact: support@forestshoes.mu`,

  dataPrivacy: `Data Privacy Statement

Forest Shoes is committed to protecting your personal data in accordance with applicable data protection laws.

DATA CONTROLLER
Forest Shoes (Mauritius)
Email: support@forestshoes.mu

DATA WE PROCESS
- Name, email, phone number
- Delivery address
- Order history
- Device and usage data (anonymised)

LEGAL BASIS FOR PROCESSING
We process your data on the basis of contract performance (to fulfil your orders) and legitimate interests (to improve our services).

YOUR RIGHTS UNDER GDPR / LOCAL LAW
- Right to access your data
- Right to rectification
- Right to erasure ("right to be forgotten")
- Right to restrict processing
- Right to data portability
- Right to object

To exercise any of these rights, contact us at support@forestshoes.mu. We will respond within 30 days.

DATA TRANSFERS
Your data is stored on Firebase (Google Cloud) servers, which comply with international data protection standards.

CONTACT OUR DATA OFFICER
support@forestshoes.mu`,

  about: `About Forest Shoes

Welcome to Forest Shoes — your destination for premium footwear in Mauritius.

OUR STORY
Founded in Mauritius, Forest Shoes was born from a passion for quality footwear and exceptional customer service. We believe everyone deserves to walk in style and comfort.

OUR PRODUCTS
We curate a wide selection of shoes for men, women, and children — from casual everyday wear to formal occasion footwear. Every product is carefully selected for quality and style.

OUR COMMITMENT
✓ Authentic, quality products
✓ Fast island-wide delivery
✓ Hassle-free returns
✓ Dedicated customer support

CONTACT US
Email: support@forestshoes.mu
Phone: +230 5XXX XXXX
Follow us on social media @forestshoes.mu

Thank you for shopping with us!`,
}

export default function ContentPage() {
  const [activeTab, setActiveTab] = useState<ContentKey>('terms')
  const [contents, setContents] = useState<Record<ContentKey, string>>({
    terms: TEMPLATES.terms,
    privacy: TEMPLATES.privacy,
    dataPrivacy: TEMPLATES.dataPrivacy,
    about: TEMPLATES.about,
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => { loadAll() }, [])

  async function loadAll() {
    const results = await Promise.all(
      CONTENT_TYPES.map(ct => getDoc(doc(db, 'content', ct.key)))
    )
    const loaded = { ...contents } as Record<ContentKey, string>
    CONTENT_TYPES.forEach((ct, i) => {
      const saved = results[i].exists() ? (results[i].data()?.body ?? '').trim() : ''
      // Keep template text if nothing has been saved to Firestore yet
      loaded[ct.key] = saved.length > 0 ? saved : TEMPLATES[ct.key]
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
