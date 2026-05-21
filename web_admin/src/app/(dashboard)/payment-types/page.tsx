'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, addDoc, doc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { PaymentType } from '@/types'
import { formatCurrency } from '@/lib/utils'
import toast from 'react-hot-toast'
import { Plus, Pencil, Trash2, CreditCard } from 'lucide-react'

const EMPTY: Omit<PaymentType, 'id'> = { name: '', description: '', icon: '', fee: 0, instructions: '', isActive: true }

export default function PaymentTypesPage() {
  const [types, setTypes] = useState<PaymentType[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState<typeof EMPTY>(EMPTY)
  const [editId, setEditId] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => { load() }, [])
  async function load() {
    const snap = await getDocs(collection(db, 'paymentTypes'))
    setTypes(snap.docs.map(d => ({ id: d.id, ...d.data() } as PaymentType)))
    setLoading(false)
  }

  async function save() {
    if (!form.name) return toast.error('Name is required')
    setSaving(true)
    const data = { name: form.name, description: form.description, icon: form.icon, fee: Number(form.fee), instructions: form.instructions, isActive: form.isActive }
    try {
      if (editId) {
        await updateDoc(doc(db, 'paymentTypes', editId), data)
        toast.success('Updated')
      } else {
        await addDoc(collection(db, 'paymentTypes'), { ...data, createdAt: serverTimestamp() })
        toast.success('Created')
      }
      setShowModal(false); setForm(EMPTY); setEditId(null); load()
    } finally { setSaving(false) }
  }

  async function remove(id: string) {
    if (!confirm('Delete this payment type?')) return
    await deleteDoc(doc(db, 'paymentTypes', id))
    setTypes(ts => ts.filter(t => t.id !== id))
    toast.success('Deleted')
  }

  async function toggleActive(t: PaymentType) {
    await updateDoc(doc(db, 'paymentTypes', t.id), { isActive: !t.isActive })
    setTypes(ts => ts.map(x => x.id === t.id ? { ...x, isActive: !x.isActive } : x))
  }

  function openEdit(t: PaymentType) {
    setForm({ name: t.name, description: t.description ?? '', icon: t.icon ?? '', fee: t.fee, instructions: t.instructions ?? '', isActive: t.isActive })
    setEditId(t.id); setShowModal(true)
  }

  return (
    <main className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Payment Types</h1>
        <p className="text-sm text-gray-400 mt-1">Manage payment methods and fees</p>
      </div>
      <div>
        <div className="flex justify-end mb-6">
          <button onClick={() => { setForm(EMPTY); setEditId(null); setShowModal(true) }} className="btn-primary flex items-center gap-2">
            <Plus size={16} /> Add Payment Type
          </button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {loading ? <p className="text-gray-400">Loading...</p> : types.map(t => (
            <div key={t.id} className="card p-5">
              <div className="flex items-start justify-between mb-3">
                <div className="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center text-blue-600">
                  <CreditCard size={20} />
                </div>
                <div className="flex items-center gap-1">
                  <button onClick={() => toggleActive(t)} className={t.isActive ? 'badge-green cursor-pointer' : 'badge-gray cursor-pointer'}>{t.isActive ? 'Active' : 'Off'}</button>
                  <button onClick={() => openEdit(t)} className="p-1.5 rounded-lg text-gray-400 hover:bg-blue-50 hover:text-blue-600"><Pencil size={14} /></button>
                  <button onClick={() => remove(t.id)} className="p-1.5 rounded-lg text-gray-400 hover:bg-red-50 hover:text-red-500"><Trash2 size={14} /></button>
                </div>
              </div>
              <h3 className="font-semibold text-gray-900">{t.name}</h3>
              {t.description && <p className="text-sm text-gray-500 mt-1">{t.description}</p>}
              {t.fee > 0 && <p className="text-sm font-medium text-[#6c63ff] mt-2">Fee: {formatCurrency(t.fee)}</p>}
              {t.instructions && (
                <div className="mt-3 p-3 bg-gray-50 rounded-lg">
                  <p className="text-xs text-gray-500">{t.instructions}</p>
                </div>
              )}
            </div>
          ))}
          {!loading && types.length === 0 && <p className="text-gray-400 col-span-3">No payment types yet</p>}
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6">
            <h2 className="text-lg font-bold mb-5">{editId ? 'Edit' : 'Add'} Payment Type</h2>
            <div className="space-y-4">
              <div><label className="block text-sm font-medium mb-1">Name *</label><input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} className="input-field" placeholder="e.g. Cash on Delivery" /></div>
              <div><label className="block text-sm font-medium mb-1">Description</label><input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="input-field" /></div>
              <div><label className="block text-sm font-medium mb-1">Fee (Rs)</label><input type="number" value={form.fee} onChange={e => setForm(f => ({ ...f, fee: Number(e.target.value) }))} className="input-field" min="0" /></div>
              <div><label className="block text-sm font-medium mb-1">Instructions (shown to customers)</label><textarea value={form.instructions} onChange={e => setForm(f => ({ ...f, instructions: e.target.value }))} className="input-field" rows={3} placeholder="e.g. Transfer to MCB account 1234567890..." /></div>
              <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.isActive} onChange={e => setForm(f => ({ ...f, isActive: e.target.checked }))} className="w-4 h-4 accent-[#6c63ff]" /> Active</label>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={save} disabled={saving} className="btn-primary flex-1">{saving ? 'Saving...' : 'Save'}</button>
              <button onClick={() => setShowModal(false)} className="btn-secondary flex-1">Cancel</button>
            </div>
          </div>
        </div>
      )}
    </main>
  )
}
