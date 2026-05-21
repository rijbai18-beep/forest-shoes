'use client'

import { useState } from 'react'
import { getFunctions, httpsCallable } from 'firebase/functions'
import { functions } from '@/lib/firebase'
import toast from 'react-hot-toast'
import { Bell, Send } from 'lucide-react'
import { Card, Text } from '@tremor/react'

export default function NotificationsPage() {
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [sending, setSending] = useState(false)

  async function sendNotification(e: React.FormEvent) {
    e.preventDefault()
    if (!title || !body) return toast.error('Fill in title and message')
    if (!confirm(`Send notification to ALL users?\n\nTitle: ${title}\nMessage: ${body}`)) return

    setSending(true)
    try {
      const broadcast = httpsCallable(functions, 'broadcastNotification')
      await broadcast({ title, body })
      toast.success('Notification sent to all users!')
      setTitle('')
      setBody('')
    } catch (err: any) {
      toast.error(err.message || 'Error sending notification')
    } finally {
      setSending(false)
    }
  }

  return (
    <main className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Notifications</h1>
        <Text className="mt-1">Send push notifications to all users</Text>
      </div>
      <div className="max-w-2xl space-y-6">
        <Card>
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-purple-50 rounded-xl flex items-center justify-center">
              <Bell size={20} className="text-purple-600" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900">Broadcast Notification</h3>
              <p className="text-sm text-gray-500">This will send to ALL active users via push & in-app notification</p>
            </div>
          </div>

          <form onSubmit={sendNotification} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Notification Title *</label>
              <input
                value={title}
                onChange={e => setTitle(e.target.value)}
                className="input-field"
                placeholder="e.g. New Collection Arrived! 🎉"
                maxLength={100}
              />
              <p className="text-xs text-gray-400 mt-1">{title.length}/100</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Message *</label>
              <textarea
                value={body}
                onChange={e => setBody(e.target.value)}
                className="input-field"
                rows={4}
                placeholder="e.g. Check out our new summer collection with up to 40% off!"
                maxLength={500}
              />
              <p className="text-xs text-gray-400 mt-1">{body.length}/500</p>
            </div>

            {/* Preview */}
            {(title || body) && (
              <div className="p-4 bg-gray-900 rounded-xl text-white">
                <p className="text-xs text-gray-400 mb-2">Preview</p>
                <div className="flex gap-3">
                  <div className="w-10 h-10 bg-[#6c63ff] rounded-xl flex items-center justify-center flex-shrink-0">
                    <span className="text-lg">🌿</span>
                  </div>
                  <div>
                    <p className="font-semibold text-sm">{title || 'Notification title'}</p>
                    <p className="text-xs text-gray-300 mt-0.5">{body || 'Your message here...'}</p>
                    <p className="text-xs text-gray-500 mt-1">now · Forest Shoes</p>
                  </div>
                </div>
              </div>
            )}

            <button
              type="submit"
              disabled={sending}
              className="btn-primary w-full flex items-center justify-center gap-2 py-3"
            >
              {sending ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  Sending...
                </>
              ) : (
                <>
                  <Send size={16} /> Send to All Users
                </>
              )}
            </button>
          </form>
        </Card>

        <Card>
          <h3 className="font-semibold text-gray-900 mb-3">Tips for effective notifications</h3>
          <ul className="space-y-2 text-sm text-gray-600">
            <li className="flex gap-2"><span>💡</span> Keep titles short and action-oriented</li>
            <li className="flex gap-2"><span>📱</span> Messages over 100 chars may be truncated on some devices</li>
            <li className="flex gap-2"><span>⏰</span> Send during business hours (9AM–8PM) for better engagement</li>
            <li className="flex gap-2"><span>🎯</span> Use emojis to make notifications stand out</li>
          </ul>
        </Card>
      </div>
    </main>
  )
}
