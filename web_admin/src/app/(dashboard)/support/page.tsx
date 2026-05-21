'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, query, orderBy, doc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { SupportTicket } from '@/types'
import { formatDateTime } from '@/lib/utils'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { MessageSquare, Clock, CheckCircle, Search } from 'lucide-react'

const STATUS_FILTERS = ['all', 'open', 'in_progress', 'closed'] as const

export default function SupportPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<typeof STATUS_FILTERS[number]>('all')

  useEffect(() => { load() }, [])

  async function load() {
    const snap = await getDocs(query(collection(db, 'supportTickets'), orderBy('createdAt', 'desc')))
    setTickets(snap.docs.map(d => ({ id: d.id, ...d.data() } as SupportTicket)))
    setLoading(false)
  }

  async function closeTicket(id: string) {
    if (!confirm('Close this ticket?')) return
    await updateDoc(doc(db, 'supportTickets', id), { status: 'closed' })
    setTickets(ts => ts.map(t => t.id === id ? { ...t, status: 'closed' } : t))
    toast.success('Ticket closed')
  }

  async function setInProgress(id: string) {
    await updateDoc(doc(db, 'supportTickets', id), { status: 'in_progress' })
    setTickets(ts => ts.map(t => t.id === id ? { ...t, status: 'in_progress' } : t))
    toast.success('Ticket marked in progress')
  }

  const filtered = tickets.filter(t => {
    const matchSearch = !search ||
      t.subject?.toLowerCase().includes(search.toLowerCase()) ||
      t.userId?.toLowerCase().includes(search.toLowerCase())
    const matchStatus = statusFilter === 'all' || t.status === statusFilter
    return matchSearch && matchStatus
  })

  const counts = {
    open: tickets.filter(t => t.status === 'open').length,
    in_progress: tickets.filter(t => t.status === 'in_progress').length,
    closed: tickets.filter(t => t.status === 'closed').length,
  }

  return (
    <main className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Customer Support</h1>
        <p className="text-sm text-gray-400 mt-1">Manage support tickets and customer enquiries</p>
      </div>
      <div>
        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 mb-6">
          <div className="card p-4 flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center"><MessageSquare size={18} className="text-blue-600" /></div>
            <div><p className="text-2xl font-bold text-gray-900">{counts.open}</p><p className="text-xs text-gray-500">Open</p></div>
          </div>
          <div className="card p-4 flex items-center gap-3">
            <div className="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center"><Clock size={18} className="text-amber-600" /></div>
            <div><p className="text-2xl font-bold text-gray-900">{counts.in_progress}</p><p className="text-xs text-gray-500">In Progress</p></div>
          </div>
          <div className="card p-4 flex items-center gap-3">
            <div className="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center"><CheckCircle size={18} className="text-green-600" /></div>
            <div><p className="text-2xl font-bold text-gray-900">{counts.closed}</p><p className="text-xs text-gray-500">Closed</p></div>
          </div>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap gap-3 mb-5">
          <div className="relative flex-1 min-w-48 max-w-md">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search tickets..." className="input-field pl-9" />
          </div>
          <div className="flex gap-2">
            {STATUS_FILTERS.map(s => (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${statusFilter === s ? 'bg-[#6c63ff] text-white' : 'bg-white border border-gray-200 text-gray-600 hover:border-gray-300'}`}
              >
                {s === 'all' ? 'All' : s === 'in_progress' ? 'In Progress' : s.charAt(0).toUpperCase() + s.slice(1)}
              </button>
            ))}
          </div>
        </div>

        <div className="card overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                <th className="table-th">Ticket</th>
                <th className="table-th">User</th>
                <th className="table-th">Status</th>
                <th className="table-th">Created</th>
                <th className="table-th">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {loading ? (
                <tr><td colSpan={5} className="table-td text-center py-12 text-gray-400">Loading...</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={5} className="table-td text-center py-12 text-gray-400">No tickets found</td></tr>
              ) : filtered.map(ticket => (
                <tr key={ticket.id} className="hover:bg-gray-50">
                  <td className="table-td">
                    <div>
                      <p className="font-medium text-sm text-gray-900">{ticket.subject}</p>
                      <p className="text-xs text-gray-400 mt-0.5 font-mono">{ticket.id.slice(0, 8)}...</p>
                    </div>
                  </td>
                  <td className="table-td">
                    <div>
                      <p className="text-sm text-gray-700">{ticket.userName ?? '—'}</p>
                      <p className="text-xs text-gray-400">{ticket.userEmail ?? ticket.userId?.slice(0, 12)}</p>
                    </div>
                  </td>
                  <td className="table-td">
                    <TicketStatusBadge status={ticket.status} />
                  </td>
                  <td className="table-td text-gray-500 text-sm">{formatDateTime(ticket.createdAt)}</td>
                  <td className="table-td">
                    <div className="flex items-center gap-2">
                      <Link href={`/support/${ticket.id}`} className="btn-secondary text-xs py-1.5 px-3">View</Link>
                      {ticket.status === 'open' && (
                        <button onClick={() => setInProgress(ticket.id)} className="text-xs px-3 py-1.5 rounded-lg border border-amber-200 text-amber-700 hover:bg-amber-50 transition-colors">In Progress</button>
                      )}
                      {ticket.status !== 'closed' && (
                        <button onClick={() => closeTicket(ticket.id)} className="text-xs px-3 py-1.5 rounded-lg border border-red-200 text-red-600 hover:bg-red-50 transition-colors">Close</button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  )
}

function TicketStatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    open: 'badge-blue',
    in_progress: 'badge-yellow',
    closed: 'badge-gray',
  }
  const labels: Record<string, string> = {
    open: 'Open',
    in_progress: 'In Progress',
    closed: 'Closed',
  }
  return <span className={map[status] ?? 'badge-gray'}>{labels[status] ?? status}</span>
}
