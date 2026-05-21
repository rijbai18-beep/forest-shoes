'use client'

import { useEffect, useRef, useState } from 'react'
import { doc, getDoc, collection, query, orderBy, onSnapshot, addDoc, updateDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { useAuth } from '@/contexts/AuthContext'
import { SupportTicket, TicketMessage } from '@/types'
import { formatDateTime } from '@/lib/utils'
import toast from 'react-hot-toast'
import { Send, ArrowLeft, CheckCircle } from 'lucide-react'
import Link from 'next/link'

export default function TicketDetail({ id }: { id: string }) {
  const { user } = useAuth()
  const [ticket, setTicket] = useState<SupportTicket | null>(null)
  const [messages, setMessages] = useState<TicketMessage[]>([])
  const [reply, setReply] = useState('')
  const [sending, setSending] = useState(false)
  const [closing, setClosing] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    loadTicket()
    const unsub = onSnapshot(
      query(collection(db, 'supportTickets', id, 'messages'), orderBy('createdAt', 'asc')),
      snap => setMessages(snap.docs.map(d => ({ id: d.id, ...d.data() } as TicketMessage)))
    )
    return unsub
  }, [id])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  async function loadTicket() {
    const snap = await getDoc(doc(db, 'supportTickets', id))
    if (snap.exists()) setTicket({ id: snap.id, ...snap.data() } as SupportTicket)
  }

  async function sendReply(e: React.FormEvent) {
    e.preventDefault()
    if (!reply.trim()) return
    setSending(true)
    try {
      await addDoc(collection(db, 'supportTickets', id, 'messages'), {
        message: reply.trim(),
        senderId: user?.uid,
        senderName: 'Support Team',
        isAdmin: true,
        createdAt: serverTimestamp(),
      })
      if (ticket?.status === 'open') {
        await updateDoc(doc(db, 'supportTickets', id), { status: 'in_progress' })
        setTicket(t => t ? { ...t, status: 'in_progress' } : t)
      }
      setReply('')
    } catch {
      toast.error('Failed to send message')
    } finally {
      setSending(false)
    }
  }

  async function closeTicket() {
    if (!confirm('Close this ticket? The customer will be unable to send further messages.')) return
    setClosing(true)
    try {
      await updateDoc(doc(db, 'supportTickets', id), { status: 'closed' })
      setTicket(t => t ? { ...t, status: 'closed' } : t)
      toast.success('Ticket closed')
    } finally {
      setClosing(false)
    }
  }

  if (!ticket) return (
    <div className="p-6 text-gray-400">Loading ticket...</div>
  )

  return (
    <div className="flex flex-col h-screen">
      <div className="px-6 pt-6 pb-2 border-b border-gray-100">
        <h1 className="text-xl font-bold text-gray-900 truncate">{ticket.subject}</h1>
        <p className="text-xs text-gray-400 mt-0.5">Ticket {id.slice(0, 8)} · {ticket.userName ?? ticket.userId}</p>
      </div>
      <div className="px-6 pb-2 pt-3 flex items-center gap-3">
        <Link href="/support" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
          <ArrowLeft size={15} /> Back to tickets
        </Link>
        <span className="text-gray-300">|</span>
        <TicketStatusBadge status={ticket.status} />
        {ticket.status !== 'closed' && (
          <button
            onClick={closeTicket}
            disabled={closing}
            className="ml-auto flex items-center gap-1.5 text-sm px-4 py-1.5 rounded-xl border border-red-200 text-red-600 hover:bg-red-50 transition-colors"
          >
            <CheckCircle size={14} /> {closing ? 'Closing...' : 'Close Ticket'}
          </button>
        )}
      </div>

      <div className="flex flex-1 overflow-hidden px-6 pb-6 gap-5">
        <div className="flex-1 flex flex-col card overflow-hidden">
          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {messages.length === 0 && (
              <p className="text-center text-gray-400 text-sm py-8">No messages yet</p>
            )}
            {messages.map(msg => (
              <div key={msg.id} className={`flex ${msg.isAdmin ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[70%] rounded-2xl px-4 py-2.5 ${msg.isAdmin ? 'bg-[#6c63ff] text-white rounded-br-sm' : 'bg-gray-100 text-gray-900 rounded-bl-sm'}`}>
                  <p className={`text-xs font-medium mb-0.5 ${msg.isAdmin ? 'text-green-200' : 'text-gray-500'}`}>
                    {msg.isAdmin ? 'Support Team' : (msg.senderName ?? 'Customer')}
                  </p>
                  <p className="text-sm leading-relaxed">{msg.message}</p>
                  <p className={`text-xs mt-1 ${msg.isAdmin ? 'text-green-300' : 'text-gray-400'}`}>
                    {formatDateTime(msg.createdAt)}
                  </p>
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          {ticket.status !== 'closed' ? (
            <form onSubmit={sendReply} className="p-4 border-t border-gray-100 flex gap-3">
              <input
                value={reply}
                onChange={e => setReply(e.target.value)}
                placeholder="Type your reply..."
                className="input-field flex-1"
                disabled={sending}
              />
              <button type="submit" disabled={sending || !reply.trim()} className="btn-primary flex items-center gap-2 px-4">
                {sending ? <div className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" /> : <Send size={16} />}
                Send
              </button>
            </form>
          ) : (
            <div className="p-4 border-t border-gray-100 text-center text-sm text-gray-400">
              This ticket is closed. Reopen by changing its status.
            </div>
          )}
        </div>

        <div className="w-72 space-y-4">
          <div className="card p-4">
            <h3 className="text-sm font-semibold text-gray-900 mb-3">Ticket Info</h3>
            <dl className="space-y-2 text-sm">
              <div className="flex justify-between">
                <dt className="text-gray-500">Status</dt>
                <dd><TicketStatusBadge status={ticket.status} /></dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-gray-500">Created</dt>
                <dd className="text-gray-700 text-xs">{formatDateTime(ticket.createdAt)}</dd>
              </div>
            </dl>
          </div>

          <div className="card p-4">
            <h3 className="text-sm font-semibold text-gray-900 mb-3">Customer</h3>
            <dl className="space-y-2 text-sm">
              <div>
                <dt className="text-gray-500 text-xs">Name</dt>
                <dd className="text-gray-900 font-medium">{ticket.userName ?? '—'}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs">Email</dt>
                <dd className="text-gray-700">{ticket.userEmail ?? '—'}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs">User ID</dt>
                <dd className="text-gray-400 text-xs font-mono">{ticket.userId}</dd>
              </div>
            </dl>
          </div>

          <div className="card p-4">
            <h3 className="text-sm font-semibold text-gray-900 mb-2">Subject</h3>
            <p className="text-sm text-gray-700">{ticket.subject}</p>
          </div>
        </div>
      </div>
    </div>
  )
}

function TicketStatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = { open: 'badge-blue', in_progress: 'badge-yellow', closed: 'badge-gray' }
  const labels: Record<string, string> = { open: 'Open', in_progress: 'In Progress', closed: 'Closed' }
  return <span className={map[status] ?? 'badge-gray'}>{labels[status] ?? status}</span>
}
