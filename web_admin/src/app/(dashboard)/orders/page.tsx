'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, query, orderBy, doc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Order } from '@/types'
import { formatCurrency, formatDateTime, ORDER_STATUSES, getStatusBadge } from '@/lib/utils'
import Link from 'next/link'
import toast from 'react-hot-toast'
import {
  Card, Title, Text, Flex, Badge, TextInput, Button, Color,
  TabGroup, TabList, Tab, TabPanels, TabPanel,
  Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell,
} from '@tremor/react'
import { MagnifyingGlassIcon, ChevronRightIcon } from '@heroicons/react/24/outline'

const TREMOR_STATUS: Record<string, Color> = {
  new: 'blue', pending_payment: 'yellow', reviewed: 'emerald',
  processing: 'amber', dispatched: 'indigo', delivered: 'green', cancelled: 'red',
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch]   = useState('')
  const [tabIdx, setTabIdx]   = useState(0)

  useEffect(() => { load() }, [])
  async function load() {
    const snap = await getDocs(query(collection(db, 'orders'), orderBy('createdAt', 'desc')))
    setOrders(snap.docs.map(d => ({ id: d.id, ...d.data() } as Order)))
    setLoading(false)
  }

  async function updateStatus(orderId: string, status: string) {
    await updateDoc(doc(db, 'orders', orderId), { status, updatedAt: new Date() })
    toast.success('Status updated')
    setOrders(os => os.map(o => o.id === orderId ? { ...o, status } : o))
  }

  const tabs = [{ label: 'All', value: '' }, ...ORDER_STATUSES.map(s => ({ label: s.label, value: s.value }))]
  const statusFilter = tabs[tabIdx]?.value ?? ''
  const filtered = orders.filter(o =>
    (o.id.includes(search) || o.address?.name?.toLowerCase().includes(search.toLowerCase())) &&
    (!statusFilter || o.status === statusFilter)
  )

  return (
    <main className="p-6 space-y-6">
      <Flex>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Orders</h1>
          <Text className="mt-1">{orders.length} total orders</Text>
        </div>
      </Flex>

      <Card>
        <Flex className="mb-4" justifyContent="start">
          <TextInput icon={MagnifyingGlassIcon} placeholder="Search by ID or customer…" value={search} onValueChange={setSearch} className="max-w-xs" />
        </Flex>

        <TabGroup index={tabIdx} onIndexChange={setTabIdx}>
          <TabList className="mb-4" variant="line" color="green">
            {tabs.map((t, i) => (
              <Tab key={i}>
                {t.label}
                {t.value === '' && <span className="ml-2 text-xs text-gray-400">({orders.length})</span>}
                {t.value !== '' && (
                  <span className="ml-2 text-xs text-gray-400">({orders.filter(o => o.status === t.value).length})</span>
                )}
              </Tab>
            ))}
          </TabList>

          <TabPanels>
            {tabs.map((_, i) => (
              <TabPanel key={i}>
                {loading ? (
                  <div className="flex justify-center py-20"><div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" /></div>
                ) : (
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableHeaderCell>Order ID</TableHeaderCell>
                        <TableHeaderCell>Customer</TableHeaderCell>
                        <TableHeaderCell>Date</TableHeaderCell>
                        <TableHeaderCell>Items</TableHeaderCell>
                        <TableHeaderCell>Total</TableHeaderCell>
                        <TableHeaderCell>Payment</TableHeaderCell>
                        <TableHeaderCell>Status</TableHeaderCell>
                        <TableHeaderCell className="text-right">Action</TableHeaderCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {filtered.length === 0 ? (
                        <TableRow><TableCell colSpan={8} className="text-center py-12 text-gray-400">No orders found</TableCell></TableRow>
                      ) : filtered.map(order => {
                        const badge = getStatusBadge(order.status, ORDER_STATUSES)
                        return (
                          <TableRow key={order.id} className="hover:bg-gray-50 group">
                            <TableCell className="font-mono font-bold text-brand-600 text-xs">#{order.id.slice(0,8).toUpperCase()}</TableCell>
                            <TableCell>
                              <div className="font-semibold text-gray-900">{order.address?.name ?? '—'}</div>
                              <div className="text-xs text-gray-400">{order.address?.phone}</div>
                            </TableCell>
                            <TableCell className="text-gray-500 text-xs">{formatDateTime(order.createdAt)}</TableCell>
                            <TableCell>{order.items?.length ?? 0}</TableCell>
                            <TableCell className="font-bold">{formatCurrency(order.total)}</TableCell>
                            <TableCell className="text-gray-500 text-xs">{order.paymentType}</TableCell>
                            <TableCell><Badge color={TREMOR_STATUS[order.status] ?? 'gray'}>{badge.label}</Badge></TableCell>
                            <TableCell>
                              <div className="flex items-center justify-end gap-2">
                                <select value={order.status} onChange={e => updateStatus(order.id, e.target.value)}
                                  className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white focus:outline-none focus:ring-2 focus:ring-brand-600/20">
                                  {ORDER_STATUSES.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
                                </select>
                                <Link href={"/orders/" + order.id}
                                  className="p-1.5 text-gray-400 hover:text-brand-600 rounded-lg hover:bg-green-50 transition-colors">
                                  <ChevronRightIcon className="w-4 h-4" />
                                </Link>
                              </div>
                            </TableCell>
                          </TableRow>
                        )
                      })}
                    </TableBody>
                  </Table>
                )}
              </TabPanel>
            ))}
          </TabPanels>
        </TabGroup>
      </Card>
    </main>
  )
}
