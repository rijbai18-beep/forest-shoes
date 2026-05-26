'use client'

import { useEffect, useState, useCallback } from 'react'
import {
  collection, query, orderBy, limit, getDocs,
  startAfter, QueryDocumentSnapshot, where, Timestamp,
} from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { formatDateTime } from '@/lib/utils'
import {
  ShieldCheckIcon, ExclamationTriangleIcon, MagnifyingGlassIcon,
  ChevronDownIcon, ChevronUpIcon, ArrowPathIcon, FunnelIcon,
} from '@heroicons/react/24/outline'

const PAGE_SIZE = 50

type LogType = 'action' | 'error'
type Platform = 'mobile' | 'web_admin'

interface AuditLog {
  id: string
  type: LogType
  platform: Platform
  userId: string | null
  userEmail: string | null
  action: string
  details: Record<string, unknown> | null
  errorMessage: string | null
  stackTrace: string | null
  timestamp: Timestamp | null
}

function badge(type: LogType) {
  return type === 'error'
    ? 'inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-red-50 text-red-700 ring-1 ring-red-200/60'
    : 'inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 ring-1 ring-blue-200/60'
}

function platformBadge(platform: Platform) {
  return platform === 'mobile'
    ? 'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-brand-50 text-brand-700 ring-1 ring-brand-200/60'
    : 'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-gray-100 text-gray-600 ring-1 ring-gray-200/60'
}

function formatDate(ts: Timestamp | null) {
  if (!ts) return '—'
  return formatDateTime(ts.toDate())
}

export default function AuditLogsPage() {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(true)
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null)
  const [expanded, setExpanded] = useState<Set<string>>(new Set())

  // Filters
  const [typeFilter, setTypeFilter] = useState<'' | LogType>('')
  const [platformFilter, setPlatformFilter] = useState<'' | Platform>('')
  const [search, setSearch] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')

  const buildQuery = useCallback((afterDoc?: QueryDocumentSnapshot | null) => {
    let q = query(
      collection(db, 'audit_logs'),
      orderBy('timestamp', 'desc'),
      limit(PAGE_SIZE),
    )
    if (typeFilter) q = query(q, where('type', '==', typeFilter))
    if (platformFilter) q = query(q, where('platform', '==', platformFilter))
    if (dateFrom) {
      q = query(q, where('timestamp', '>=', Timestamp.fromDate(new Date(dateFrom))))
    }
    if (dateTo) {
      const to = new Date(dateTo)
      to.setHours(23, 59, 59, 999)
      q = query(q, where('timestamp', '<=', Timestamp.fromDate(to)))
    }
    if (afterDoc) q = query(q, startAfter(afterDoc))
    return q
  }, [typeFilter, platformFilter, dateFrom, dateTo])

  const load = useCallback(async () => {
    setLoading(true)
    setLastDoc(null)
    setHasMore(true)
    try {
      const snap = await getDocs(buildQuery())
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as AuditLog))
      setLogs(data)
      setLastDoc(snap.docs[snap.docs.length - 1] ?? null)
      setHasMore(snap.docs.length === PAGE_SIZE)
    } finally {
      setLoading(false)
    }
  }, [buildQuery])

  useEffect(() => { load() }, [load])

  async function loadMore() {
    if (!lastDoc || loadingMore) return
    setLoadingMore(true)
    try {
      const snap = await getDocs(buildQuery(lastDoc))
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as AuditLog))
      setLogs(prev => [...prev, ...data])
      setLastDoc(snap.docs[snap.docs.length - 1] ?? null)
      setHasMore(snap.docs.length === PAGE_SIZE)
    } finally {
      setLoadingMore(false)
    }
  }

  function toggleExpanded(id: string) {
    setExpanded(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  const filtered = search
    ? logs.filter(l =>
        l.action.toLowerCase().includes(search.toLowerCase()) ||
        (l.userEmail ?? '').toLowerCase().includes(search.toLowerCase()) ||
        (l.errorMessage ?? '').toLowerCase().includes(search.toLowerCase()),
      )
    : logs

  const errorCount = logs.filter(l => l.type === 'error').length
  const mobileCount = logs.filter(l => l.platform === 'mobile').length
  const webCount = logs.filter(l => l.platform === 'web_admin').length

  return (
    <main className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Audit Logs</h1>
          <p className="text-sm text-gray-400 mt-0.5">
            {logs.length} entries loaded · {errorCount} errors
          </p>
        </div>
        <button onClick={load} className="btn-outline gap-2" disabled={loading}>
          <ArrowPathIcon className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Total Loaded', value: logs.length, color: 'text-gray-800' },
          { label: 'Errors', value: errorCount, color: 'text-red-600' },
          { label: 'Mobile', value: mobileCount, color: 'text-brand-600' },
          { label: 'Web Admin', value: webCount, color: 'text-gray-600' },
        ].map(s => (
          <div key={s.label} className="card px-5 py-4">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">{s.label}</p>
            <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="card p-4">
        <div className="flex items-center gap-2 mb-3">
          <FunnelIcon className="w-4 h-4 text-gray-400" />
          <span className="text-sm font-semibold text-gray-600">Filters</span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          {/* Search */}
          <div className="md:col-span-2 relative">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search action, email, error…"
              className="input-field pl-9"
            />
          </div>
          {/* Type */}
          <select
            value={typeFilter}
            onChange={e => setTypeFilter(e.target.value as '' | LogType)}
            className="input-field"
          >
            <option value="">All types</option>
            <option value="action">Actions</option>
            <option value="error">Errors</option>
          </select>
          {/* Platform */}
          <select
            value={platformFilter}
            onChange={e => setPlatformFilter(e.target.value as '' | Platform)}
            className="input-field"
          >
            <option value="">All platforms</option>
            <option value="mobile">Mobile</option>
            <option value="web_admin">Web Admin</option>
          </select>
          {/* Date from */}
          <input
            type="date"
            value={dateFrom}
            onChange={e => setDateFrom(e.target.value)}
            className="input-field"
          />
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-20">
            <div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 gap-3 text-gray-400">
            <ShieldCheckIcon className="w-10 h-10 text-gray-200" />
            <span className="text-sm">No logs found</span>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="table-th w-40">Timestamp</th>
                  <th className="table-th w-20">Type</th>
                  <th className="table-th w-24">Platform</th>
                  <th className="table-th">Action</th>
                  <th className="table-th">User</th>
                  <th className="table-th w-8"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map(log => {
                  const isExpanded = expanded.has(log.id)
                  const hasExtra = !!(log.details || log.errorMessage || log.stackTrace)
                  return (
                    <>
                      <tr
                        key={log.id}
                        className={`hover:bg-gray-50 transition-colors ${log.type === 'error' ? 'bg-red-50/30' : ''}`}
                      >
                        <td className="table-td font-mono text-xs text-gray-400 whitespace-nowrap">
                          {formatDate(log.timestamp)}
                        </td>
                        <td className="table-td">
                          <span className={badge(log.type)}>
                            {log.type === 'error'
                              ? <ExclamationTriangleIcon className="w-3 h-3" />
                              : <ShieldCheckIcon className="w-3 h-3" />}
                            {log.type}
                          </span>
                        </td>
                        <td className="table-td">
                          <span className={platformBadge(log.platform)}>
                            {log.platform === 'mobile' ? '📱' : '🖥'} {log.platform === 'mobile' ? 'Mobile' : 'Admin'}
                          </span>
                        </td>
                        <td className="table-td">
                          <span className="font-mono text-xs font-semibold text-gray-700">{log.action}</span>
                          {log.errorMessage && (
                            <p className="text-xs text-red-500 mt-0.5 truncate max-w-xs">{log.errorMessage}</p>
                          )}
                        </td>
                        <td className="table-td text-gray-500 text-xs">
                          {log.userEmail ?? <span className="text-gray-300">—</span>}
                        </td>
                        <td className="table-td">
                          {hasExtra && (
                            <button
                              onClick={() => toggleExpanded(log.id)}
                              className="p-1 rounded hover:bg-gray-100 text-gray-400 transition-colors"
                            >
                              {isExpanded
                                ? <ChevronUpIcon className="w-4 h-4" />
                                : <ChevronDownIcon className="w-4 h-4" />}
                            </button>
                          )}
                        </td>
                      </tr>
                      {isExpanded && hasExtra && (
                        <tr key={`${log.id}-detail`} className="bg-gray-50">
                          <td colSpan={6} className="px-6 py-4">
                            <div className="space-y-3 text-xs">
                              {log.details && (
                                <div>
                                  <p className="font-semibold text-gray-500 mb-1 uppercase tracking-wide">Details</p>
                                  <pre className="bg-white rounded-lg border border-gray-200 p-3 text-gray-700 overflow-x-auto">
                                    {JSON.stringify(log.details, null, 2)}
                                  </pre>
                                </div>
                              )}
                              {log.errorMessage && (
                                <div>
                                  <p className="font-semibold text-red-500 mb-1 uppercase tracking-wide">Error</p>
                                  <p className="bg-red-50 rounded-lg border border-red-100 p-3 text-red-700 font-mono">
                                    {log.errorMessage}
                                  </p>
                                </div>
                              )}
                              {log.stackTrace && (
                                <div>
                                  <p className="font-semibold text-gray-500 mb-1 uppercase tracking-wide">Stack Trace</p>
                                  <pre className="bg-gray-900 text-green-400 rounded-lg p-3 overflow-x-auto text-[11px] leading-relaxed max-h-64">
                                    {log.stackTrace}
                                  </pre>
                                </div>
                              )}
                            </div>
                          </td>
                        </tr>
                      )}
                    </>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Load more */}
        {!loading && hasMore && (
          <div className="flex justify-center py-4 border-t border-gray-100">
            <button
              onClick={loadMore}
              disabled={loadingMore}
              className="btn-outline gap-2"
            >
              {loadingMore
                ? <span className="w-4 h-4 border-2 border-gray-300 border-t-brand-600 rounded-full animate-spin" />
                : null}
              Load more
            </button>
          </div>
        )}
      </div>
    </main>
  )
}
