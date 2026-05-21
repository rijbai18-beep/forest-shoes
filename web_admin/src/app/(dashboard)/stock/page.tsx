'use client'

import { useEffect, useState } from 'react'
import {
  collection, getDocs, doc, updateDoc, query, orderBy,
  where, getDoc,
} from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Product, StockAlert, AppSettings } from '@/types'
import toast from 'react-hot-toast'
import {
  Card, Text, Flex, Badge, Button, Callout,
  Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell,
} from '@tremor/react'
import {
  ExclamationTriangleIcon, CubeIcon, Cog6ToothIcon,
  CheckCircleIcon,
} from '@heroicons/react/24/outline'

export default function StockPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [alerts, setAlerts] = useState<StockAlert[]>([])
  const [settings, setSettings] = useState<AppSettings>({
    stockAlertThreshold: 5, freeDeliveryThreshold: 300, currency: 'Rs',
  })
  const [loading, setLoading] = useState(true)
  const [editingStock, setEditingStock] = useState<Record<string, number>>({})
  const [savingStock, setSavingStock] = useState<string | null>(null)
  const [savingSettings, setSavingSettings] = useState(false)

  useEffect(() => { loadData() }, [])

  async function loadData() {
    const [productsSnap, alertsSnap, settingsSnap] = await Promise.all([
      getDocs(query(collection(db, 'products'), where('isActive', '==', true), orderBy('stock', 'asc'))),
      getDocs(query(collection(db, 'stockAlerts'), where('resolved', '==', false))),
      getDoc(doc(db, 'settings', 'global')),
    ])
    setProducts(productsSnap.docs.map(d => ({ id: d.id, ...d.data() } as Product)))
    setAlerts(alertsSnap.docs.map(d => ({ id: d.id, ...d.data() } as StockAlert)))
    if (settingsSnap.exists()) setSettings(settingsSnap.data() as AppSettings)
    setLoading(false)
  }

  async function updateStock(productId: string) {
    const newStock = editingStock[productId]
    if (newStock === undefined) return
    setSavingStock(productId)
    try {
      await updateDoc(doc(db, 'products', productId), { stock: newStock })
      setProducts(ps => ps.map(p => p.id === productId ? { ...p, stock: newStock } : p))
      const { [productId]: _, ...rest } = editingStock
      setEditingStock(rest)
      toast.success('Stock updated')
    } finally { setSavingStock(null) }
  }

  async function resolveAlert(alertId: string) {
    await updateDoc(doc(db, 'stockAlerts', alertId), { resolved: true })
    setAlerts(as => as.filter(a => a.id !== alertId))
    toast.success('Alert resolved')
  }

  async function saveSettings() {
    setSavingSettings(true)
    try {
      await updateDoc(doc(db, 'settings', 'global'), {
        stockAlertThreshold: settings.stockAlertThreshold,
        freeDeliveryThreshold: settings.freeDeliveryThreshold,
      })
      toast.success('Settings saved')
    } finally { setSavingSettings(false) }
  }

  const lowStock = products.filter(p => p.stock <= settings.stockAlertThreshold)
  const normalStock = products.filter(p => p.stock > settings.stockAlertThreshold)

  const stockColor = (n: number) => {
    if (n === 0) return 'text-red-600'
    if (n <= settings.stockAlertThreshold) return 'text-amber-600'
    return 'text-emerald-600'
  }

  const badgeColor = (n: number) => {
    if (n === 0) return 'red'
    if (n <= settings.stockAlertThreshold) return 'yellow'
    return 'green'
  }

  return (
    <main className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Stock Management</h1>
        <Text className="mt-1">Monitor and update product inventory levels</Text>
      </div>

      {/* Low-stock callout */}
      {alerts.length > 0 && (
        <Callout title={`${alerts.length} unresolved low-stock alert${alerts.length > 1 ? 's' : ''}`}
          icon={ExclamationTriangleIcon} color="amber">
          <div className="space-y-2 mt-2">
            {alerts.map(alert => (
              <div key={alert.id} className="flex items-center justify-between">
                <span className="text-sm">
                  <strong>{alert.productName}</strong> — {alert.stock} units left (threshold: {alert.threshold})
                </span>
                <button
                  onClick={() => resolveAlert(alert.id)}
                  className="text-xs font-semibold text-amber-700 border border-amber-300 hover:bg-amber-100 px-2.5 py-1 rounded-lg transition-colors"
                >
                  Resolve
                </button>
              </div>
            ))}
          </div>
        </Callout>
      )}

      {/* Settings card */}
      <Card>
        <Flex justifyContent="start" className="gap-2 mb-4">
          <Cog6ToothIcon className="w-5 h-5 text-brand-600" />
          <h3 className="font-semibold text-gray-900">Alert Settings</h3>
        </Flex>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
              Low Stock Threshold (units)
            </label>
            <input
              type="number"
              value={settings.stockAlertThreshold}
              onChange={e => setSettings(s => ({ ...s, stockAlertThreshold: Number(e.target.value) }))}
              className="input-field"
              min="1"
            />
            <p className="text-xs text-gray-400 mt-1">Alert when stock drops to or below this</p>
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
              Free Delivery Threshold (Rs)
            </label>
            <input
              type="number"
              value={settings.freeDeliveryThreshold}
              onChange={e => setSettings(s => ({ ...s, freeDeliveryThreshold: Number(e.target.value) }))}
              className="input-field"
              min="0"
            />
            <p className="text-xs text-gray-400 mt-1">Orders above this get free delivery</p>
          </div>
        </div>
        <div className="mt-4">
          <Button color="green" loading={savingSettings} icon={CheckCircleIcon} onClick={saveSettings}>
            {savingSettings ? 'Saving…' : 'Save Settings'}
          </Button>
        </div>
      </Card>

      {loading ? (
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : (
        <>
          {/* Critical stock */}
          {lowStock.length > 0 && (
            <Card>
              <Flex justifyContent="start" className="gap-2 mb-4">
                <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
                <h3 className="font-semibold text-gray-900">Critical Stock ({lowStock.length})</h3>
              </Flex>
              <StockTable
                products={lowStock}
                editingStock={editingStock}
                setEditingStock={setEditingStock}
                savingStock={savingStock}
                updateStock={updateStock}
                stockColor={stockColor}
                badgeColor={badgeColor}
              />
            </Card>
          )}

          {/* All active products */}
          <Card>
            <Flex justifyContent="start" className="gap-2 mb-4">
              <CubeIcon className="w-5 h-5 text-brand-600" />
              <h3 className="font-semibold text-gray-900">All Active Products ({normalStock.length})</h3>
            </Flex>
            <StockTable
              products={normalStock}
              editingStock={editingStock}
              setEditingStock={setEditingStock}
              savingStock={savingStock}
              updateStock={updateStock}
              stockColor={stockColor}
              badgeColor={badgeColor}
            />
          </Card>
        </>
      )}
    </main>
  )
}

type StockTableProps = {
  products: Product[]
  editingStock: Record<string, number>
  setEditingStock: React.Dispatch<React.SetStateAction<Record<string, number>>>
  savingStock: string | null
  updateStock: (id: string) => Promise<void>
  stockColor: (n: number) => string
  badgeColor: (n: number) => 'red' | 'yellow' | 'green'
}

function StockTable({ products, editingStock, setEditingStock, savingStock, updateStock, stockColor, badgeColor }: StockTableProps) {
  if (products.length === 0) {
    return <p className="text-sm text-gray-400 text-center py-6">No products in this range</p>
  }
  return (
    <Table>
      <TableHead>
        <TableRow>
          <TableHeaderCell>Product</TableHeaderCell>
          <TableHeaderCell>Category</TableHeaderCell>
          <TableHeaderCell>Current Stock</TableHeaderCell>
          <TableHeaderCell>Update</TableHeaderCell>
          <TableHeaderCell></TableHeaderCell>
        </TableRow>
      </TableHead>
      <TableBody>
        {products.map(p => (
          <TableRow key={p.id} className="hover:bg-gray-50">
            <TableCell>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-gray-50 overflow-hidden flex-shrink-0 ring-1 ring-gray-100">
                  {p.images[0]
                    ? <img src={p.images[0]} alt="" className="w-full h-full object-cover" />
                    : <div className="w-full h-full flex items-center justify-center text-gray-300 text-xs">👟</div>}
                </div>
                <Text className="font-semibold text-gray-900 truncate max-w-[180px]">{p.name}</Text>
              </div>
            </TableCell>
            <TableCell className="text-gray-500 text-sm">{p.category}</TableCell>
            <TableCell>
              <div className="flex items-center gap-2">
                <span className={`font-bold text-lg ${stockColor(p.stock)}`}>{p.stock}</span>
                <Badge color={badgeColor(p.stock)} size="xs">
                  {p.stock === 0 ? 'Out' : p.stock <= 5 ? 'Low' : 'OK'}
                </Badge>
              </div>
            </TableCell>
            <TableCell>
              <input
                type="number"
                value={editingStock[p.id] ?? ''}
                onChange={e => setEditingStock(s => ({ ...s, [p.id]: Number(e.target.value) }))}
                className="input-field w-24 text-sm"
                min="0"
                placeholder={String(p.stock)}
              />
            </TableCell>
            <TableCell>
              {editingStock[p.id] !== undefined && (
                <Button
                  size="xs"
                  color="green"
                  loading={savingStock === p.id}
                  onClick={() => updateStock(p.id)}
                >
                  Save
                </Button>
              )}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}
