'use client'

import { useEffect, useState } from 'react'
import {
  collection, getDocs, addDoc, doc, updateDoc, deleteDoc,
  serverTimestamp,
} from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Coupon } from '@/types'
import { formatCurrency } from '@/lib/utils'
import toast from 'react-hot-toast'
import {
  Card, Text, Flex, Badge, Button, TextInput,
  Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell,
} from '@tremor/react'
import {
  PlusIcon, PencilIcon, TrashIcon, XMarkIcon, TicketIcon,
  MagnifyingGlassIcon,
} from '@heroicons/react/24/outline'

const EMPTY: Omit<Coupon, 'id' | 'usedCount'> = {
  code: '', type: 'percentage', value: 10,
  minOrder: undefined, maxDiscount: undefined, maxUses: undefined,
  expiresAt: undefined, isActive: true,
}

export default function CouponsPage() {
  const [coupons, setCoupons] = useState<Coupon[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState<typeof EMPTY>(EMPTY)
  const [editId, setEditId] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => { loadCoupons() }, [])

  async function loadCoupons() {
    const snap = await getDocs(collection(db, 'coupons'))
    setCoupons(snap.docs.map(d => ({ id: d.id, ...d.data() } as Coupon)))
    setLoading(false)
  }

  async function save() {
    if (!form.code || !form.value) return toast.error('Fill in required fields')
    setSaving(true)
    const data = {
      code: form.code.toUpperCase(),
      type: form.type,
      value: Number(form.value),
      minOrder: form.minOrder ? Number(form.minOrder) : null,
      maxDiscount: form.maxDiscount ? Number(form.maxDiscount) : null,
      maxUses: form.maxUses ? Number(form.maxUses) : null,
      isActive: form.isActive,
    }
    try {
      if (editId) {
        await updateDoc(doc(db, 'coupons', editId), data)
        toast.success('Coupon updated')
      } else {
        await addDoc(collection(db, 'coupons'), { ...data, usedCount: 0, createdAt: serverTimestamp() })
        toast.success('Coupon created')
      }
      closeModal()
      loadCoupons()
    } finally { setSaving(false) }
  }

  async function toggleActive(coupon: Coupon) {
    await updateDoc(doc(db, 'coupons', coupon.id), { isActive: !coupon.isActive })
    setCoupons(cs => cs.map(c => c.id === coupon.id ? { ...c, isActive: !c.isActive } : c))
  }

  async function deleteCoupon(id: string) {
    if (!confirm('Delete this coupon?')) return
    await deleteDoc(doc(db, 'coupons', id))
    setCoupons(cs => cs.filter(c => c.id !== id))
    toast.success('Deleted')
  }

  function openEdit(coupon: Coupon) {
    setForm({
      code: coupon.code, type: coupon.type, value: coupon.value,
      minOrder: coupon.minOrder, maxDiscount: coupon.maxDiscount,
      maxUses: coupon.maxUses, expiresAt: coupon.expiresAt, isActive: coupon.isActive,
    })
    setEditId(coupon.id)
    setShowModal(true)
  }

  function closeModal() {
    setShowModal(false)
    setForm(EMPTY)
    setEditId(null)
  }

  const f = (key: keyof typeof form, val: any) => setForm(prev => ({ ...prev, [key]: val }))

  const filtered = coupons.filter(c =>
    c.code.toLowerCase().includes(search.toLowerCase())
  )
  const active = coupons.filter(c => c.isActive).length

  return (
    <main className="p-6 space-y-6">
      <Flex>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Coupons</h1>
          <Text className="mt-1">{coupons.length} codes · {active} active</Text>
        </div>
        <Button icon={PlusIcon} color="green" onClick={() => { setForm(EMPTY); setEditId(null); setShowModal(true) }}>
          Create Coupon
        </Button>
      </Flex>

      {/* Stats row */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Total Coupons', value: coupons.length, color: 'text-gray-800' },
          { label: 'Active', value: active, color: 'text-emerald-600' },
          { label: 'Inactive', value: coupons.length - active, color: 'text-gray-400' },
        ].map(s => (
          <Card key={s.label} className="py-4">
            <Text className="text-xs font-semibold text-gray-400 uppercase tracking-wide">{s.label}</Text>
            <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
          </Card>
        ))}
      </div>

      <Card>
        <div className="mb-4">
          <TextInput
            icon={MagnifyingGlassIcon}
            placeholder="Search by code…"
            value={search}
            onValueChange={setSearch}
            className="max-w-xs"
          />
        </div>

        {loading ? (
          <div className="flex justify-center py-16">
            <div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <Table>
            <TableHead>
              <TableRow>
                <TableHeaderCell>Code</TableHeaderCell>
                <TableHeaderCell>Type</TableHeaderCell>
                <TableHeaderCell>Discount</TableHeaderCell>
                <TableHeaderCell>Min Order</TableHeaderCell>
                <TableHeaderCell>Used / Max</TableHeaderCell>
                <TableHeaderCell>Status</TableHeaderCell>
                <TableHeaderCell className="text-right">Actions</TableHeaderCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-12">
                    <div className="flex flex-col items-center gap-2 text-gray-400">
                      <TicketIcon className="w-8 h-8 text-gray-200" />
                      <span className="text-sm">{search ? 'No matching coupons' : 'No coupons yet'}</span>
                    </div>
                  </TableCell>
                </TableRow>
              ) : filtered.map(coupon => (
                <TableRow key={coupon.id} className="hover:bg-gray-50 group">
                  <TableCell>
                    <span className="font-mono font-bold text-brand-600 bg-brand-50 px-2.5 py-1 rounded-lg text-sm">
                      {coupon.code}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Badge color={coupon.type === 'percentage' ? 'blue' : 'emerald'} size="xs">
                      {coupon.type === 'percentage' ? '% Off' : 'Fixed'}
                    </Badge>
                  </TableCell>
                  <TableCell className="font-semibold">
                    {coupon.type === 'percentage' ? `${coupon.value}%` : formatCurrency(coupon.value)}
                    {coupon.maxDiscount && (
                      <span className="text-xs text-gray-400 ml-1.5">max {formatCurrency(coupon.maxDiscount)}</span>
                    )}
                  </TableCell>
                  <TableCell className="text-gray-500">
                    {coupon.minOrder ? formatCurrency(coupon.minOrder) : '—'}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1">
                      <span className="font-semibold text-gray-700">{coupon.usedCount}</span>
                      <span className="text-gray-300">/</span>
                      <span className="text-gray-500">{coupon.maxUses ?? '∞'}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <button
                      onClick={() => toggleActive(coupon)}
                      className="focus:outline-none"
                    >
                      <Badge color={coupon.isActive ? 'green' : 'gray'}>
                        {coupon.isActive ? 'Active' : 'Inactive'}
                      </Badge>
                    </button>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end gap-1">
                      <button
                        onClick={() => openEdit(coupon)}
                        className="p-1.5 rounded-lg hover:bg-blue-50 text-gray-400 hover:text-blue-600 transition-colors"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => deleteCoupon(coupon.id)}
                        className="p-1.5 rounded-lg hover:bg-red-50 text-gray-400 hover:text-red-600 transition-colors"
                      >
                        <TrashIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* ── Modal ───────────────────────────────────────────────────── */}
      {showModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-[2px] flex items-center justify-center z-50 p-4 overflow-y-auto">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-2xl my-4 animate-fade-in">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
              <div>
                <h2 className="text-base font-bold text-gray-900">{editId ? 'Edit' : 'Create'} Coupon</h2>
                <p className="text-xs text-gray-400 mt-0.5">Configure the discount code</p>
              </div>
              <button onClick={closeModal} className="p-2 rounded-xl hover:bg-gray-100 text-gray-400 transition-colors">
                <XMarkIcon className="w-5 h-5" />
              </button>
            </div>

            <div className="px-6 py-5 space-y-4">
              {/* Code */}
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
                  Code <span className="text-red-400">*</span>
                </label>
                <input
                  value={form.code}
                  onChange={e => f('code', e.target.value.toUpperCase())}
                  className="input-field font-mono tracking-widest text-brand-600 font-bold"
                  placeholder="SAVE20"
                  autoFocus
                />
              </div>

              {/* Type + Value */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Type *</label>
                  <select value={form.type} onChange={e => f('type', e.target.value as 'percentage' | 'amount')} className="input-field">
                    <option value="percentage">Percentage %</option>
                    <option value="amount">Fixed Amount (Rs)</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
                    Value {form.type === 'percentage' ? '(%)' : '(Rs)'} *
                  </label>
                  <input
                    type="number"
                    value={form.value}
                    onChange={e => f('value', Number(e.target.value))}
                    className="input-field"
                    min="0"
                    max={form.type === 'percentage' ? 100 : undefined}
                  />
                </div>
              </div>

              {/* Min order + Max uses */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Min Order (Rs)</label>
                  <input
                    type="number"
                    value={form.minOrder ?? ''}
                    onChange={e => f('minOrder', e.target.value ? Number(e.target.value) : undefined)}
                    className="input-field"
                    placeholder="Optional"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Max Uses</label>
                  <input
                    type="number"
                    value={form.maxUses ?? ''}
                    onChange={e => f('maxUses', e.target.value ? Number(e.target.value) : undefined)}
                    className="input-field"
                    placeholder="Unlimited"
                  />
                </div>
              </div>

              {/* Max discount (percentage only) */}
              {form.type === 'percentage' && (
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Max Discount (Rs)</label>
                  <input
                    type="number"
                    value={form.maxDiscount ?? ''}
                    onChange={e => f('maxDiscount', e.target.value ? Number(e.target.value) : undefined)}
                    className="input-field"
                    placeholder="No cap"
                  />
                </div>
              )}

              {/* Preview */}
              {form.code && (
                <div className="p-3 bg-brand-50 rounded-xl border border-brand-100">
                  <p className="text-xs text-brand-700 font-semibold mb-1">Preview</p>
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-bold text-brand-600 text-sm bg-white px-2 py-1 rounded-lg border border-brand-200">
                      {form.code}
                    </span>
                    <span className="text-xs text-brand-600">
                      → {form.type === 'percentage' ? `${form.value}% off` : formatCurrency(Number(form.value))}
                      {form.minOrder ? ` on orders above ${formatCurrency(form.minOrder)}` : ''}
                    </span>
                  </div>
                </div>
              )}

              {/* Active toggle */}
              <label className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-gray-100 cursor-pointer">
                <div>
                  <p className="text-sm font-medium text-gray-800">Active</p>
                  <p className="text-xs text-gray-400">Allow customers to use this coupon</p>
                </div>
                <button
                  type="button"
                  onClick={() => f('isActive', !form.isActive)}
                  className={`relative w-10 h-5 rounded-full transition-colors ${form.isActive ? 'bg-brand-600' : 'bg-gray-200'}`}
                >
                  <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${form.isActive ? 'translate-x-5' : ''}`} />
                </button>
              </label>
            </div>

            <div className="flex gap-3 px-6 pb-6">
              <Button color="green" loading={saving} className="flex-1" onClick={save}>
                {saving ? 'Saving…' : editId ? 'Update Coupon' : 'Create Coupon'}
              </Button>
              <Button variant="secondary" className="flex-1" onClick={closeModal}>Cancel</Button>
            </div>
          </div>
        </div>
      )}
    </main>
  )
}
