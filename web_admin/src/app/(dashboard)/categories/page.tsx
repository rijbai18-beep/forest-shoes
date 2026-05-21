'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, addDoc, doc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore'
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage'
import { db, storage } from '@/lib/firebase'
import { Category, CustomField } from '@/types'
import toast from 'react-hot-toast'
import {
  Card, Text, Flex, Badge, Button,
  Grid,
} from '@tremor/react'
import {
  PlusIcon, PencilIcon, TrashIcon, ArrowUpTrayIcon,
  XMarkIcon, TagIcon,
} from '@heroicons/react/24/outline'

const EMPTY = { name: '', imageUrl: '', isActive: true, customFields: [] as CustomField[] }

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState<typeof EMPTY>(EMPTY)
  const [editId, setEditId] = useState<string | null>(null)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    const snap = await getDocs(collection(db, 'categories'))
    setCategories(snap.docs.map(d => ({ id: d.id, ...d.data() } as Category)))
    setLoading(false)
  }

  async function save() {
    if (!form.name) return toast.error('Name required')
    setSaving(true)
    try {
      let imageUrl = form.imageUrl
      if (imageFile) {
        const r = ref(storage, `categories/${Date.now()}/${imageFile.name}`)
        await uploadBytes(r, imageFile)
        imageUrl = await getDownloadURL(r)
      }
      const data = { name: form.name, imageUrl, isActive: form.isActive, customFields: form.customFields }
      if (editId) {
        await updateDoc(doc(db, 'categories', editId), data)
        toast.success('Category updated')
      } else {
        await addDoc(collection(db, 'categories'), { ...data, createdAt: serverTimestamp() })
        toast.success('Category added')
      }
      closeModal()
      load()
    } finally { setSaving(false) }
  }

  function closeModal() {
    setShowModal(false)
    setForm(EMPTY)
    setEditId(null)
    setImageFile(null)
    setImagePreview(null)
  }

  async function remove(id: string) {
    if (!confirm('Delete this category?')) return
    await deleteDoc(doc(db, 'categories', id))
    setCategories(cs => cs.filter(c => c.id !== id))
    toast.success('Deleted')
  }

  function openEdit(cat: Category) {
    setForm({ name: cat.name, imageUrl: cat.imageUrl ?? '', isActive: cat.isActive, customFields: cat.customFields ?? [] })
    setEditId(cat.id)
    setShowModal(true)
  }

  function handleImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setImageFile(file)
    setImagePreview(URL.createObjectURL(file))
  }

  function addCustomField() {
    setForm(f => ({ ...f, customFields: [...f.customFields, { name: '', type: 'text', required: false }] }))
  }

  function removeCustomField(i: number) {
    setForm(f => ({ ...f, customFields: f.customFields.filter((_, j) => j !== i) }))
  }

  function updateCustomField(i: number, key: keyof CustomField, val: any) {
    setForm(f => ({ ...f, customFields: f.customFields.map((cf, j) => j === i ? { ...cf, [key]: val } : cf) }))
  }

  return (
    <main className="p-6 space-y-6">
      <Flex>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Categories</h1>
          <Text className="mt-1">{categories.length} categories · Manage how products are organised</Text>
        </div>
        <Button icon={PlusIcon} color="green" onClick={() => { setForm(EMPTY); setEditId(null); setImageFile(null); setImagePreview(null); setShowModal(true) }}>
          Add Category
        </Button>
      </Flex>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : (
        <Grid numItemsSm={2} numItemsMd={3} numItemsLg={4} className="gap-5">
          {categories.map(cat => (
            <Card key={cat.id} className="p-0 overflow-hidden group">
              {/* Image area */}
              <div className="relative h-36 bg-gradient-to-br from-brand-50 to-brand-100">
                {cat.imageUrl ? (
                  <img src={cat.imageUrl} alt={cat.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <TagIcon className="w-10 h-10 text-brand-300" />
                  </div>
                )}
                {/* Status badge overlay */}
                <div className="absolute top-2 right-2">
                  <Badge color={cat.isActive ? 'green' : 'gray'} size="xs">
                    {cat.isActive ? 'Active' : 'Off'}
                  </Badge>
                </div>
              </div>

              {/* Info + actions */}
              <div className="p-4">
                <Text className="font-bold text-gray-900 truncate">{cat.name}</Text>
                {cat.customFields?.length > 0 && (
                  <Text className="text-xs text-gray-400 mt-0.5">{cat.customFields.length} custom field{cat.customFields.length > 1 ? 's' : ''}</Text>
                )}
                <div className="flex items-center gap-2 mt-3">
                  <button
                    onClick={() => openEdit(cat)}
                    className="flex-1 flex items-center justify-center gap-1.5 text-xs font-medium py-1.5 rounded-lg border border-gray-200 hover:bg-blue-50 hover:border-blue-200 hover:text-blue-600 transition-all"
                  >
                    <PencilIcon className="w-3.5 h-3.5" /> Edit
                  </button>
                  <button
                    onClick={() => remove(cat.id)}
                    className="p-1.5 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-all"
                  >
                    <TrashIcon className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </Card>
          ))}

          {categories.length === 0 && (
            <div className="col-span-full flex flex-col items-center justify-center py-20 text-gray-400 gap-3">
              <TagIcon className="w-12 h-12 text-gray-200" />
              <p className="text-sm">No categories yet. Add your first one.</p>
            </div>
          )}
        </Grid>
      )}

      {/* ── Modal ───────────────────────────────────────────────────── */}
      {showModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-[2px] flex items-center justify-center z-50 p-4 overflow-y-auto">
          <div className="bg-white rounded-2xl w-full max-w-lg shadow-2xl my-4 animate-fade-in">
            {/* Modal header */}
            <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
              <div>
                <h2 className="text-base font-bold text-gray-900">{editId ? 'Edit' : 'Add'} Category</h2>
                <p className="text-xs text-gray-400 mt-0.5">Fill in the details below</p>
              </div>
              <button onClick={closeModal} className="p-2 rounded-xl hover:bg-gray-100 text-gray-400 transition-colors">
                <XMarkIcon className="w-5 h-5" />
              </button>
            </div>

            <div className="px-6 py-5 space-y-5">
              {/* Name */}
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
                  Category Name <span className="text-red-400">*</span>
                </label>
                <input
                  value={form.name}
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                  className="input-field"
                  placeholder="e.g. Sneakers, Boots, Sandals"
                  autoFocus
                />
              </div>

              {/* Image upload */}
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">Image</label>
                {(imagePreview || form.imageUrl) && (
                  <div className="relative mb-3 rounded-xl overflow-hidden h-36 bg-gray-50">
                    <img
                      src={imagePreview || form.imageUrl}
                      alt=""
                      className="w-full h-full object-cover"
                    />
                    <button
                      onClick={() => { setImageFile(null); setImagePreview(null); setForm(f => ({ ...f, imageUrl: '' })) }}
                      className="absolute top-2 right-2 w-6 h-6 bg-black/50 rounded-full flex items-center justify-center hover:bg-red-500 transition-colors"
                    >
                      <XMarkIcon className="w-3.5 h-3.5 text-white" />
                    </button>
                  </div>
                )}
                <label className="flex items-center justify-center w-full h-24 border-2 border-dashed border-gray-200 rounded-xl cursor-pointer hover:border-brand-600 hover:bg-green-50/50 transition-all group">
                  <div className="flex flex-col items-center gap-1.5">
                    <ArrowUpTrayIcon className="w-5 h-5 text-gray-300 group-hover:text-brand-600 transition-colors" />
                    <span className="text-xs font-medium text-gray-400 group-hover:text-brand-600 transition-colors">
                      {imageFile ? imageFile.name : 'Click to upload'}
                    </span>
                  </div>
                  <input type="file" accept="image/*" className="hidden" onChange={handleImageChange} />
                </label>
              </div>

              {/* Active toggle */}
              <label className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-gray-100 cursor-pointer">
                <div>
                  <p className="text-sm font-medium text-gray-800">Active</p>
                  <p className="text-xs text-gray-400">Show this category in the app</p>
                </div>
                <button
                  type="button"
                  onClick={() => setForm(f => ({ ...f, isActive: !f.isActive }))}
                  className={`relative w-10 h-5 rounded-full transition-colors ${form.isActive ? 'bg-brand-600' : 'bg-gray-200'}`}
                >
                  <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${form.isActive ? 'translate-x-5' : ''}`} />
                </button>
              </label>

              {/* Custom fields */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <label className="text-xs font-semibold text-gray-600 uppercase tracking-wide">Custom Fields</label>
                  <button
                    type="button"
                    onClick={addCustomField}
                    className="text-xs btn-ghost px-2 py-1 flex items-center gap-1"
                  >
                    <PlusIcon className="w-3.5 h-3.5" /> Add Field
                  </button>
                </div>
                {form.customFields.length === 0 && (
                  <p className="text-xs text-gray-400">No custom fields. Useful for specs like material, waterproof rating, etc.</p>
                )}
                <div className="space-y-3">
                  {form.customFields.map((cf, i) => (
                    <div key={i} className="p-3 bg-gray-50 rounded-xl space-y-2 border border-gray-100">
                      <div className="flex items-center gap-2">
                        <input
                          value={cf.name}
                          onChange={e => updateCustomField(i, 'name', e.target.value)}
                          className="input-field flex-1 text-sm"
                          placeholder="Field name"
                        />
                        <select
                          value={cf.type}
                          onChange={e => updateCustomField(i, 'type', e.target.value)}
                          className="input-field text-sm w-auto"
                        >
                          <option value="text">Text</option>
                          <option value="number">Number</option>
                          <option value="boolean">Yes/No</option>
                          <option value="select">Select</option>
                        </select>
                        <button onClick={() => removeCustomField(i)} className="text-gray-400 hover:text-red-500 transition-colors">
                          <XMarkIcon className="w-4 h-4" />
                        </button>
                      </div>
                      {cf.type === 'select' && (
                        <input
                          value={cf.options?.join(', ') ?? ''}
                          onChange={e => updateCustomField(i, 'options', e.target.value.split(',').map(s => s.trim()))}
                          className="input-field text-xs"
                          placeholder="Options separated by commas"
                        />
                      )}
                      <label className="flex items-center gap-1.5 text-xs text-gray-500 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={cf.required}
                          onChange={e => updateCustomField(i, 'required', e.target.checked)}
                          className="w-3 h-3 accent-brand-600"
                        />
                        Required
                      </label>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="flex gap-3 px-6 pb-6">
              <Button color="green" loading={saving} className="flex-1" onClick={save}>
                {saving ? 'Saving…' : editId ? 'Update Category' : 'Add Category'}
              </Button>
              <Button variant="secondary" className="flex-1" onClick={closeModal}>Cancel</Button>
            </div>
          </div>
        </div>
      )}
    </main>
  )
}
