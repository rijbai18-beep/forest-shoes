'use client'

import { useEffect, useState } from 'react'
import { collection, query, orderBy, limit, getDocs, where, getCountFromServer } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { formatCurrency, formatDate, ORDER_STATUSES, getStatusBadge } from '@/lib/utils'
import { Order, StockAlert } from '@/types'
import {
  Card, Grid, Col, Metric, Text, Title, Flex, Badge,
  Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell,
  DonutChart, AreaChart, Icon, Callout, Color,
} from '@tremor/react'
import {
  ShoppingBagIcon, UsersIcon, CubeIcon, BanknotesIcon,
  ExclamationTriangleIcon, ArrowRightIcon,
} from '@heroicons/react/24/outline'
import Link from 'next/link'

const TREMOR_STATUS: Record<string, Color> = {
  new: 'blue', pending_payment: 'yellow', reviewed: 'emerald',
  processing: 'amber', dispatched: 'indigo', delivered: 'green', cancelled: 'red',
}

function months(n: number) {
  const out = []
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(); d.setMonth(d.getMonth() - i)
    out.push(d.toLocaleString('default', { month: 'short' }))
  }
  return out
}

export default function DashboardPage() {
  const [stats, setStats]               = useState({ revenue: 0, orders: 0, users: 0, products: 0 })
  const [recent, setRecent]             = useState<Order[]>([])
  const [alerts, setAlerts]             = useState<StockAlert[]>([])
  const [donutData, setDonutData]       = useState<{ name: string; value: number }[]>([])
  const [areaData, setAreaData]         = useState<{ month: string; Revenue: number }[]>([])
  const [loading, setLoading]           = useState(true)

  useEffect(() => { load() }, [])

  async function load() {
    try {
      const [ordersSnap, usersC, prodsC, alertsSnap, recentSnap] = await Promise.all([
        getDocs(collection(db, 'orders')),
        getCountFromServer(collection(db, 'users')),
        getCountFromServer(query(collection(db, 'products'), where('isActive', '==', true))),
        getDocs(query(collection(db, 'stockAlerts'), where('resolved', '==', false))),
        getDocs(query(collection(db, 'orders'), orderBy('createdAt', 'desc'), limit(8))),
      ])

      const orders = ordersSnap.docs.map(d => ({ id: d.id, ...d.data() } as Order))

      // Revenue by month (last 6)
      const mLabels = months(6)
      const byMonth: Record<string, number> = {}
      mLabels.forEach(m => (byMonth[m] = 0))
      orders.forEach(o => {
        const ts = o.createdAt && 'toDate' in o.createdAt ? o.createdAt.toDate() : new Date(o.createdAt as any)
        const m = ts.toLocaleString('default', { month: 'short' })
        if (m in byMonth) byMonth[m] = (byMonth[m] || 0) + (o.total || 0)
      })

      // Status donut
      const statusCounts: Record<string, number> = {}
      orders.forEach(o => { statusCounts[o.status] = (statusCounts[o.status] || 0) + 1 })

      setStats({ revenue: orders.reduce((s, o) => s + (o.total || 0), 0), orders: orders.length, users: usersC.data().count, products: prodsC.data().count })
      setRecent(recentSnap.docs.map(d => ({ id: d.id, ...d.data() } as Order)))
      setAlerts(alertsSnap.docs.map(d => ({ id: d.id, ...d.data() } as StockAlert)))
      setDonutData(ORDER_STATUSES.map(s => ({ name: s.label, value: statusCounts[s.value] || 0 })).filter(x => x.value > 0))
      setAreaData(mLabels.map(m => ({ month: m, Revenue: byMonth[m] })))
    } finally { setLoading(false) }
  }

  if (loading) return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="flex flex-col items-center gap-3">
        <div className="w-10 h-10 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
        <Text>Loading dashboard…</Text>
      </div>
    </div>
  )

  return (
    <main className="p-6 space-y-6">
      {/* Page title */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <Text className="mt-1">Welcome back to the Forest Shoes admin panel.</Text>
      </div>

      {/* Stock alert */}
      {alerts.length > 0 && (
        <Callout title={`${alerts.length} low-stock product${alerts.length > 1 ? 's' : ''}`} icon={ExclamationTriangleIcon} color="amber">
          {alerts.slice(0, 4).map(a => a.productName).join(', ')}{alerts.length > 4 ? ` and ${alerts.length - 4} more.` : '.'}
          {' '}<Link href="/stock" className="underline font-semibold">Manage stock →</Link>
        </Callout>
      )}

      {/* KPI cards */}
      <Grid numItemsSm={2} numItemsLg={4} className="gap-6">
        {[
          { label: 'Total Revenue',    value: formatCurrency(stats.revenue),  icon: BanknotesIcon,    color: 'green'  as Color, href: undefined },
          { label: 'Total Orders',     value: stats.orders.toString(),         icon: ShoppingBagIcon,  color: 'blue'   as Color, href: '/orders'   },
          { label: 'Registered Users', value: stats.users.toString(),          icon: UsersIcon,        color: 'violet' as Color, href: '/users'    },
          { label: 'Active Products',  value: stats.products.toString(),       icon: CubeIcon,         color: 'amber'  as Color, href: '/products' },
        ].map(kpi => (
          <Card key={kpi.label} decoration="top" decorationColor={kpi.color}>
            <Flex justifyContent="start" className="gap-4">
              <Icon icon={kpi.icon} color={kpi.color} variant="light" size="lg" />
              <div>
                <Text>{kpi.label}</Text>
                <Metric>{kpi.value}</Metric>
              </div>
            </Flex>
            {kpi.href && (
              <Flex justifyContent="end" className="mt-3">
                <Link href={kpi.href} className="text-xs text-tremor-brand flex items-center gap-1 hover:underline font-medium">
                  View all <ArrowRightIcon className="w-3 h-3" />
                </Link>
              </Flex>
            )}
          </Card>
        ))}
      </Grid>

      {/* Charts */}
      <Grid numItemsLg={3} className="gap-6">
        <Col numColSpanLg={2}>
          <Card>
            <Title>Revenue Over Time</Title>
            <Text className="mt-1">Last 6 months</Text>
            <AreaChart
              className="mt-4 h-56"
              data={areaData}
              index="month"
              categories={['Revenue']}
              colors={['green']}
              valueFormatter={formatCurrency}
              yAxisWidth={80}
              showAnimation
            />
          </Card>
        </Col>
        <Card>
          <Title>Orders by Status</Title>
          <Text className="mt-1">{stats.orders} orders total</Text>
          {donutData.length > 0 ? (
            <DonutChart
              className="mt-4 h-44"
              data={donutData}
              category="value"
              index="name"
              colors={['blue','yellow','emerald','amber','indigo','green','red']}
              valueFormatter={v => `${v} orders`}
              showAnimation
            />
          ) : (
            <div className="flex items-center justify-center h-44 text-gray-400 text-sm">No orders yet</div>
          )}
        </Card>
      </Grid>

      {/* Recent orders */}
      <Card>
        <Flex>
          <div>
            <Title>Recent Orders</Title>
            <Text className="mt-1">Latest {recent.length} transactions</Text>
          </div>
          <Link href="/orders" className="text-sm text-tremor-brand font-medium hover:underline flex items-center gap-1">
            View all <ArrowRightIcon className="w-3.5 h-3.5" />
          </Link>
        </Flex>
        <Table className="mt-4">
          <TableHead>
            <TableRow>
              <TableHeaderCell>Order ID</TableHeaderCell>
              <TableHeaderCell>Customer</TableHeaderCell>
              <TableHeaderCell>Date</TableHeaderCell>
              <TableHeaderCell>Items</TableHeaderCell>
              <TableHeaderCell>Total</TableHeaderCell>
              <TableHeaderCell>Status</TableHeaderCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {recent.length === 0 ? (
              <TableRow><TableCell colSpan={6} className="text-center py-10 text-gray-400">No orders yet</TableCell></TableRow>
            ) : recent.map(o => {
              const s = getStatusBadge(o.status, ORDER_STATUSES)
              return (
                <TableRow key={o.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => window.location.href = `/orders?id=${o.id}`}>
                  <TableCell className="font-mono font-bold text-brand-600">#{o.id.slice(0,8).toUpperCase()}</TableCell>
                  <TableCell className="font-medium">{o.address?.name ?? '—'}</TableCell>
                  <TableCell className="text-gray-500">{formatDate(o.createdAt)}</TableCell>
                  <TableCell>{o.items?.length ?? 0}</TableCell>
                  <TableCell className="font-bold">{formatCurrency(o.total)}</TableCell>
                  <TableCell><Badge color={TREMOR_STATUS[o.status] ?? 'gray'}>{s.label}</Badge></TableCell>
                </TableRow>
              )
            })}
          </TableBody>
        </Table>
      </Card>
    </main>
  )
}
