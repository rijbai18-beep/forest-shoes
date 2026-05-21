'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, addDoc, doc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { DeliveryType } from '@/types'
import { formatCurrency } from '@/lib/utils'
import toast from 'react-hot-toast'
import { Plus, Pencil, Trash2, Truck } from 'lucide-react'

const EMPTY: Omit<DeliveryType, 'id'> = { name: '', description: '', fee: 0, estimatedDays: '', isActive: true }

export default function DeliveryTypesPage() {
  const [types, setTypes] = useState<DeliveryType[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState<typeof EMPTY>(EMPTY)
  const [editId, setEditId] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => { load() }, [])
  async function load() {
    const snap = await getDocs(collection(db, 'deliveryTypes'))
    setTypes(snap.docs.map(d => ({ id: d.id, ...d.data() } as DeliveryType)))
    setLoading(false)
  }

  async function save() {
    if (!form.name) return toast.error('Name is required')
    setSaving(true)
    const data = { name: form.name, description: form.description, fee: Number(form.fee), estimatedDays: form.estimatedDays, isActive: form.isActive }
    try {
      if (editId) {
        await updateDoc(doc(db, 'deliveryTypes', editId), data)
        toast.success('Updated')
      } else {
        await addDoc(collection(db, 'deliveryTypes'), { ...data, createdAt: serverTimestamp() })
        toast.success('Created')
      }
      setShowModal(false); setForm(EMPTY); setEditId(null); load()
    } finally { setSaving(false) }
  }

  async function remove(id: string) {
    if (!confirm('Delete this delivery type?')) return
    await deleteDoc(doc(db, 'deliveryTypes', id))
    setTypes(ts => ts.filter(t => t.id !== id))
    toast.success('Deleted')
  }

  async function toggleActive(t: DeliveryType) {
    await updateDoc(doc(db, 'deliveryTypes', t.id), { isActive: !t.isActive })
    setTypes(ts => ts.map(x => x.id === t.id ? { ...x, isActive: !x.isActive } : x))
  }

  function openEdit(t: DeliveryType) {
    setForm({ name: t.name, description: t.description ?? '', fee: t.fee, estimatedDays: t.estimatedDays ?? '', isActive: t.isActive })
    setEditId(t.id); setShowModal(true)
  }

  return (
    <main className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Delivery Types</h1>
        <p className="text-sm text-gray-400 mt-1">Manage shipping options and fees</p>
      </div>
      <div>
        <div className="flex justify-end mb-6">
          <button onClick={() => { setForm(EMPTY); setEditId(null); setShowModal(true) }} className="btn-primary flex items-center gap-2">
            <Plus size={16} /> Add Delivery Type
          </button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {loading ? <p className="text-gray-400">Loading...</p> : types.map(t => (
            <div key={t.id} className="card p-5">
              <div className="flex items-start justify-between mb-3">
                <div className="w-10 h-10 bg-orange-50 rounded-xl flex items-center justify-center text-orange-500">
                  <Truck size={20} />
                </div>
                <div className="flex items-center gap-1">
                  <button onClick={() => toggleActive(t)} className={t.isActive ? 'badge-green cursor-pointer' : 'badge-gray cursor-pointer'}>{t.isActive ? 'Active' : 'Off'}</button>
                  <button onClick={() => openEdit(t)} className="p-1.5 rounded-lg text-gray-400 hover:bg-blue-50 hover:text-blue-600"><Pencil size={14} /></button>
                  <button onClick={() => remove(t.id)} className="p-1.5 rounded-lg text-gray-400 hover:bg-red-50 hover:text-red-500"><Trash2 size={14} /></button>
                </div>
              </div>
              <h3 className="font-semibold text-gray-900">{t.name}</h3>
              {t.description && <p className="text-sm text-gray-500 mt-1">{t.description}</p>}
              <div className="flex items-center justify-between mt-2">
                <p className="text-sm font-medium text-[#6c63ff]">{t.fee === 0 ? 'Free' : formatCurrency(t.fee)}</p>
                {t.estimatedDays && <p className="text-xs text-gray-400">{t.estimatedDays}</p>}
              </div>
            </div>
          ))}
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6">
            <h2 className="text-lg font-bold mb-5">{editId ? 'Edit' : 'Add'} Delivery Type</h2>
            <div className="space-y-4">
              <div><label className="block text-sm font-medium mb-1">Name *</label><input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} className="input-field" placeholder="e.g. Standard Delivery" /></div>
              <div><label className="block text-sm font-medium mb-1">Description</label><input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="input-field" /></div>
              <div className="grid grid-cols-2 gap-3">
                <div><label className="block text-sm font-medium mb-1">Fee (Rs)</label><input type="number" value={form.fee} onChange={e => setForm(f => ({ ...f, fee: Number(e.target.value) }))} className="input-field" min="0" /></div>
                <div><label className="block text-sm font-medium mb-1">Estimated Days</label><input value={form.estimatedDays} onChange={e => setForm(f => ({ ...f, estimatedDays: e.target.value }))} className="input-field" placeholder="e.g. 2-3 days" /></div>
              </div>
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
