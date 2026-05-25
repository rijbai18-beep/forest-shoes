'use client'

import { useEffect, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import {
  collection, addDoc, doc, getDoc, updateDoc, getDocs, serverTimestamp,
} from 'firebase/firestore'
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage'
import { db, storage } from '@/lib/firebase'
import { Category } from '@/types'
import toast from 'react-hot-toast'
import {
  X, Upload, Plus, Trash2, ImageIcon, Layers, Tag, DollarSign,
  Package, Ruler, Palette, Pen, Settings2, Star, Eye, ArrowLeft,
} from 'lucide-react'
import Link from 'next/link'

const SIZES = ['36','37','38','39','40','41','42','43','44','45','46']
const COLORS = ['Black','White','Brown','Grey','Navy','Green','Red','Blue','Tan','Beige']
const GENDERS = ['men','women','kids','unisex']

type SizeStock = Record<string, number>

export default function AddProductPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const editId = searchParams.get('id')
  const isEdit = !!editId

  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(false)
  const [imageFiles, setImageFiles] = useState<File[]>([])
  const [imagePreviewUrls, setImagePreviewUrls] = useState<string[]>([])
  const [existingImages, setExistingImages] = useState<string[]>([])
  const [perSizeStock, setPerSizeStock] = useState(false)
  const [sizeStock, setSizeStock] = useState<SizeStock>({})

  const [form, setForm] = useState({
    name: '', description: '', category: '', gender: '',
    price: '', salePrice: '', stock: '',
    colors: [] as string[], sizes: [] as string[],
    hasEngraving: false, engravingFee: '100', engravingMaxChars: '10',
    tags: '', isActive: true, isFeatured: false,
    customFields: {} as Record<string, string>,
  })

  useEffect(() => {
    loadCategories()
    if (editId) loadProduct(editId)
  }, [editId])

  async function loadCategories() {
    const snap = await getDocs(collection(db, 'categories'))
    setCategories(snap.docs.map(d => ({ id: d.id, ...d.data() } as Category)))
  }

  async function loadProduct(id: string) {
    const snap = await getDoc(doc(db, 'products', id))
    if (!snap.exists()) return
    const d = snap.data()
    setForm({
      name: d.name ?? '', description: d.description ?? '',
      category: d.category ?? '', gender: d.gender ?? '',
      price: d.price?.toString() ?? '', salePrice: d.salePrice?.toString() ?? '',
      stock: d.stock?.toString() ?? '', colors: d.colors ?? [], sizes: d.sizes ?? [],
      hasEngraving: d.hasEngraving ?? false, engravingFee: d.engravingFee?.toString() ?? '100',
      engravingMaxChars: d.engravingMaxChars?.toString() ?? '10',
      tags: d.tags?.join(', ') ?? '', isActive: d.isActive ?? true,
      isFeatured: d.isFeatured ?? false, customFields: d.customFields ?? {},
    })
    setExistingImages(d.images ?? [])
    if (d.sizeStock && Object.keys(d.sizeStock).length > 0) {
      setPerSizeStock(true)
      setSizeStock(d.sizeStock)
    }
  }

  function handleImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? [])
    setImageFiles(prev => [...prev, ...files])
    const urls = files.map(f => URL.createObjectURL(f))
    setImagePreviewUrls(prev => [...prev, ...urls])
  }

  function removeNewImage(i: number) {
    setImageFiles(f => f.filter((_, j) => j !== i))
    setImagePreviewUrls(u => u.filter((_, j) => j !== i))
  }

  async function uploadImages(): Promise<string[]> {
    const urls: string[] = []
    for (const file of imageFiles) {
      const r = ref(storage, `products/${Date.now()}/${file.name}`)
      await uploadBytes(r, file)
      urls.push(await getDownloadURL(r))
    }
    return urls
  }

  function toggleSize(size: string) {
    setForm(f => {
      const next = f.sizes.includes(size) ? f.sizes.filter(s => s !== size) : [...f.sizes, size]
      if (!next.includes(size)) {
        setSizeStock(prev => { const n = { ...prev }; delete n[size]; return n })
      }
      return { ...f, sizes: next }
    })
  }

  function toggleColor(color: string) {
    setForm(f => ({
      ...f,
      colors: f.colors.includes(color) ? f.colors.filter(c => c !== color) : [...f.colors, color],
    }))
  }

  function addCustomField() {
    const key = prompt('Field name:')
    if (key) setForm(f => ({ ...f, customFields: { ...f.customFields, [key]: '' } }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!form.name || !form.category || !form.price) {
      toast.error('Please fill in required fields')
      return
    }
    setLoading(true)
    try {
      const newImageUrls = await uploadImages()
      const allImages = [...existingImages, ...newImageUrls]

      const totalStock = perSizeStock
        ? Object.values(sizeStock).reduce((a, b) => a + (b || 0), 0)
        : parseInt(form.stock) || 0

      const data: Record<string, any> = {
        name: form.name,
        description: form.description,
        category: form.category,
        gender: form.gender || null,
        images: allImages,
        price: parseFloat(form.price),
        salePrice: form.salePrice ? parseFloat(form.salePrice) : null,
        stock: totalStock,
        colors: form.colors,
        sizes: form.sizes,
        hasEngraving: form.hasEngraving,
        engravingFee: parseFloat(form.engravingFee) || 100,
        engravingMaxChars: parseInt(form.engravingMaxChars) || 10,
        tags: form.tags.split(',').map(t => t.trim()).filter(Boolean),
        isActive: form.isActive,
        isFeatured: form.isFeatured,
        customFields: form.customFields,
        updatedAt: serverTimestamp(),
      }

      if (perSizeStock) data.sizeStock = sizeStock

      if (isEdit) {
        await updateDoc(doc(db, 'products', editId!), data)
        toast.success('Product updated!')
      } else {
        await addDoc(collection(db, 'products'), { ...data, rating: 0, reviewCount: 0, createdAt: serverTimestamp() })
        toast.success('Product added!')
      }
      router.push('/products')
    } catch (err) {
      toast.error('Error saving product')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const f = (key: keyof typeof form, val: any) => setForm(prev => ({ ...prev, [key]: val }))

  return (
    <div className="animate-fade-in">
      <div className="px-6 pt-6 pb-2 flex items-center gap-3">
        <Link href="/products" className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-700 transition-colors">
          <ArrowLeft size={18} />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{isEdit ? 'Edit Product' : 'Add Product'}</h1>
          <p className="text-sm text-gray-400 mt-0.5">{isEdit ? 'Update product details' : 'Fill in the details to list a new product'}</p>
        </div>
      </div>

      <div className="p-6 pt-4">
        <form onSubmit={handleSubmit}>
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 max-w-6xl">

            {/* ── Left: main fields ─────────────────── */}
            <div className="xl:col-span-2 space-y-5">

              {/* Basic info */}
              <div className="form-section">
                <p className="form-section-title">
                  <span className="w-6 h-6 rounded-lg bg-blue-50 flex items-center justify-center">
                    <Tag size={13} className="text-blue-600" />
                  </span>
                  Basic Information
                </p>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">Product Name <span className="text-red-400">*</span></label>
                  <input value={form.name} onChange={e => f('name', e.target.value)} className="input-field" placeholder="e.g. Trail Runner Pro" required />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">Description</label>
                  <textarea value={form.description} onChange={e => f('description', e.target.value)} className="input-field resize-none" rows={4} placeholder="Describe the product…" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">Category <span className="text-red-400">*</span></label>
                    <select value={form.category} onChange={e => f('category', e.target.value)} className="input-field" required>
                      <option value="">Select category…</option>
                      {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">Gender</label>
                    <select value={form.gender} onChange={e => f('gender', e.target.value)} className="input-field">
                      <option value="">All genders</option>
                      {GENDERS.map(g => <option key={g} value={g}>{g[0].toUpperCase() + g.slice(1)}</option>)}
                    </select>
                  </div>
                </div>
              </div>

              {/* Pricing & Stock */}
              <div className="form-section">
                <p className="form-section-title">
                  <span className="w-6 h-6 rounded-lg bg-green-50 flex items-center justify-center">
                    <DollarSign size={13} className="text-green-600" />
                  </span>
                  Pricing &amp; Stock
                </p>
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">Price (Rs) <span className="text-red-400">*</span></label>
                    <input type="number" value={form.price} onChange={e => f('price', e.target.value)} className="input-field" min="0" step="0.01" placeholder="0.00" required />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">Sale Price (Rs)</label>
                    <input type="number" value={form.salePrice} onChange={e => f('salePrice', e.target.value)} className="input-field" min="0" step="0.01" placeholder="Optional" />
                  </div>
                  {!perSizeStock && (
                    <div>
                      <label className="block text-xs font-semibold text-gray-600 mb-1.5">Total Stock</label>
                      <input type="number" value={form.stock} onChange={e => f('stock', e.target.value)} className="input-field" min="0" placeholder="0" />
                    </div>
                  )}
                </div>
              </div>

              {/* Sizes */}
              <div className="form-section">
                <div className="flex items-center justify-between">
                  <p className="form-section-title">
                    <span className="w-6 h-6 rounded-lg bg-purple-50 flex items-center justify-center">
                      <Ruler size={13} className="text-purple-600" />
                    </span>
                    Sizes
                  </p>
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <span className="text-xs text-gray-500 font-medium">Per-size stock</span>
                    <button
                      type="button"
                      onClick={() => setPerSizeStock(v => !v)}
                      className={`relative w-10 h-5 rounded-full transition-colors ${perSizeStock ? 'bg-[#6c63ff]' : 'bg-gray-200'}`}
                    >
                      <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${perSizeStock ? 'translate-x-5' : ''}`} />
                    </button>
                  </label>
                </div>

                <p className="text-xs text-gray-400 -mt-1">Leave unselected for products that don't require size (e.g. accessories, bags).</p>

                {/* Size grid */}
                <div className="grid grid-cols-6 sm:grid-cols-8 gap-2">
                  {SIZES.map(size => {
                    const selected = form.sizes.includes(size)
                    return (
                      <button
                        key={size}
                        type="button"
                        onClick={() => toggleSize(size)}
                        className={`flex flex-col items-center justify-center h-12 rounded-xl border-2 text-sm font-semibold transition-all duration-150 ${
                          selected
                            ? 'border-[#6c63ff] bg-[#6c63ff] text-white shadow-sm shadow-green-900/20 scale-105'
                            : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300 hover:text-gray-700'
                        }`}
                      >
                        {size}
                      </button>
                    )
                  })}
                </div>

                {/* Per-size stock inputs */}
                {perSizeStock && form.sizes.length > 0 && (
                  <div className="mt-2 p-4 bg-gray-50 rounded-xl border border-gray-100">
                    <p className="text-xs font-semibold text-gray-500 mb-3">Stock per size</p>
                    <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
                      {form.sizes.sort((a, b) => parseInt(a) - parseInt(b)).map(size => (
                        <div key={size} className="flex flex-col gap-1">
                          <label className="text-xs font-semibold text-gray-600 text-center">EU {size}</label>
                          <input
                            type="number"
                            min="0"
                            value={sizeStock[size] ?? ''}
                            onChange={e => setSizeStock(prev => ({ ...prev, [size]: parseInt(e.target.value) || 0 }))}
                            placeholder="0"
                            className="input-field text-center text-sm font-semibold px-2"
                          />
                        </div>
                      ))}
                    </div>
                    <p className="text-xs text-gray-400 mt-3">
                      Total stock: <span className="font-semibold text-gray-700">
                        {Object.values(sizeStock).reduce((a, b) => a + (b || 0), 0)} units
                      </span>
                    </p>
                  </div>
                )}

                {perSizeStock && form.sizes.length === 0 && (
                  <p className="text-xs text-amber-600 bg-amber-50 rounded-xl px-4 py-3 border border-amber-100">
                    Select sizes above to set stock per size.
                  </p>
                )}
              </div>

              {/* Colors */}
              <div className="form-section">
                <p className="form-section-title">
                  <span className="w-6 h-6 rounded-lg bg-pink-50 flex items-center justify-center">
                    <Palette size={13} className="text-pink-600" />
                  </span>
                  Colors
                </p>
                <div className="flex flex-wrap gap-2">
                  {COLORS.map(color => {
                    const selected = form.colors.includes(color)
                    return (
                      <button
                        key={color}
                        type="button"
                        onClick={() => toggleColor(color)}
                        className={`px-3.5 py-1.5 text-sm rounded-xl border-2 font-medium transition-all duration-150 ${
                          selected
                            ? 'border-[#6c63ff] bg-[#6c63ff] text-white shadow-sm'
                            : 'border-gray-200 bg-white text-gray-600 hover:border-gray-300'
                        }`}
                      >
                        {color}
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Engraving */}
              <div className="form-section">
                <div className="flex items-center justify-between">
                  <p className="form-section-title">
                    <span className="w-6 h-6 rounded-lg bg-orange-50 flex items-center justify-center">
                      <Pen size={13} className="text-orange-500" />
                    </span>
                    Engraving Option
                  </p>
                  <button
                    type="button"
                    onClick={() => f('hasEngraving', !form.hasEngraving)}
                    className={`relative w-10 h-5 rounded-full transition-colors ${form.hasEngraving ? 'bg-[#6c63ff]' : 'bg-gray-200'}`}
                  >
                    <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${form.hasEngraving ? 'translate-x-5' : ''}`} />
                  </button>
                </div>
                {form.hasEngraving && (
                  <div className="grid grid-cols-2 gap-4 pt-1">
                    <div>
                      <label className="block text-xs font-semibold text-gray-600 mb-1.5">Engraving Fee (Rs)</label>
                      <input type="number" value={form.engravingFee} onChange={e => f('engravingFee', e.target.value)} className="input-field" />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-gray-600 mb-1.5">Max Characters</label>
                      <input type="number" value={form.engravingMaxChars} onChange={e => f('engravingMaxChars', e.target.value)} className="input-field" min="1" max="20" />
                    </div>
                  </div>
                )}
              </div>

              {/* Custom Fields */}
              <div className="form-section">
                <div className="flex items-center justify-between">
                  <p className="form-section-title">
                    <span className="w-6 h-6 rounded-lg bg-gray-100 flex items-center justify-center">
                      <Settings2 size={13} className="text-gray-500" />
                    </span>
                    Custom Fields
                  </p>
                  <button type="button" onClick={addCustomField} className="btn-ghost text-xs gap-1.5">
                    <Plus size={13} /> Add Field
                  </button>
                </div>
                {Object.keys(form.customFields).length === 0 && (
                  <p className="text-xs text-gray-400">No custom fields. Click "Add Field" to add specs like material, sole type, etc.</p>
                )}
                {Object.entries(form.customFields).map(([key, value]) => (
                  <div key={key} className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-gray-500 w-28 flex-shrink-0 bg-gray-50 px-3 py-2.5 rounded-lg border border-gray-200">{key}</span>
                    <input
                      value={value}
                      onChange={e => setForm(prev => ({ ...prev, customFields: { ...prev.customFields, [key]: e.target.value } }))}
                      className="input-field flex-1"
                      placeholder={`Value for ${key}`}
                    />
                    <button
                      type="button"
                      onClick={() => setForm(prev => { const cf = { ...prev.customFields }; delete cf[key]; return { ...prev, customFields: cf } })}
                      className="p-2 text-gray-300 hover:text-red-400 hover:bg-red-50 rounded-lg transition-all"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* ── Right sidebar ──────────────────────── */}
            <div className="space-y-5">

              {/* Status */}
              <div className="form-section">
                <p className="form-section-title">
                  <span className="w-6 h-6 rounded-lg bg-emerald-50 flex items-center justify-center">
                    <Eye size={13} className="text-emerald-600" />
                  </span>
                  Visibility
                </p>
                <div className="space-y-3">
                  {[
                    { key: 'isActive', label: 'Active', desc: 'Visible in the app' },
                    { key: 'isFeatured', label: 'Featured', desc: 'Show on homepage' },
                  ].map(item => (
                    <label key={item.key} className="flex items-center justify-between p-3 rounded-xl border border-gray-100 bg-gray-50/50 cursor-pointer hover:bg-gray-50 transition-colors">
                      <div>
                        <p className="text-sm font-medium text-gray-800">{item.label}</p>
                        <p className="text-xs text-gray-400">{item.desc}</p>
                      </div>
                      <button
                        type="button"
                        onClick={() => f(item.key as any, !(form as any)[item.key])}
                        className={`relative w-10 h-5 rounded-full transition-colors flex-shrink-0 ${(form as any)[item.key] ? 'bg-[#6c63ff]' : 'bg-gray-200'}`}
                      >
                        <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform ${(form as any)[item.key] ? 'translate-x-5' : ''}`} />
                      </button>
                    </label>
                  ))}
                </div>
              </div>

              {/* Images */}
              <div className="form-section">
                <p className="form-section-title">
                  <span className="w-6 h-6 rounded-lg bg-sky-50 flex items-center justify-center">
                    <ImageIcon size={13} className="text-sky-600" />
                  </span>
                  Product Images
                </p>

                {/* Existing images */}
                {existingImages.length > 0 && (
                  <div className="grid grid-cols-3 gap-2">
                    {existingImages.map((url, i) => (
                      <div key={i} className="relative group aspect-square">
                        <img src={url} alt="" className="w-full h-full object-cover rounded-xl" />
                        <button
                          type="button"
                          onClick={() => setExistingImages(imgs => imgs.filter((_, j) => j !== i))}
                          className="absolute top-1 right-1 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <X size={10} />
                        </button>
                        {i === 0 && <span className="absolute bottom-1 left-1 text-[9px] font-bold bg-black/60 text-white px-1.5 py-0.5 rounded-md">MAIN</span>}
                      </div>
                    ))}
                  </div>
                )}

                {/* New image previews */}
                {imagePreviewUrls.length > 0 && (
                  <div className="grid grid-cols-3 gap-2">
                    {imagePreviewUrls.map((url, i) => (
                      <div key={i} className="relative group aspect-square">
                        <img src={url} alt="" className="w-full h-full object-cover rounded-xl ring-2 ring-[#6c63ff]/30" />
                        <button
                          type="button"
                          onClick={() => removeNewImage(i)}
                          className="absolute top-1 right-1 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <X size={10} />
                        </button>
                        <span className="absolute bottom-1 left-1 text-[9px] font-bold bg-[#6c63ff]/80 text-white px-1.5 py-0.5 rounded-md">NEW</span>
                      </div>
                    ))}
                  </div>
                )}

                <label className="flex flex-col items-center justify-center w-full h-28 border-2 border-dashed border-gray-200 rounded-xl cursor-pointer hover:border-[#6c63ff] hover:bg-green-50/50 transition-all group">
                  <Upload size={20} className="text-gray-300 group-hover:text-[#6c63ff] mb-1.5 transition-colors" />
                  <span className="text-xs font-medium text-gray-400 group-hover:text-[#6c63ff] transition-colors">Click to upload</span>
                  <span className="text-[10px] text-gray-300 mt-0.5">PNG, JPG up to 10MB</span>
                  <input type="file" multiple accept="image/*" className="hidden" onChange={handleImageChange} />
                </label>
              </div>

              {/* Tags */}
              <div className="form-section">
                <p className="form-section-title">
                  <span className="w-6 h-6 rounded-lg bg-yellow-50 flex items-center justify-center">
                    <Star size={13} className="text-yellow-500" />
                  </span>
                  Tags
                </p>
                <input
                  value={form.tags}
                  onChange={e => f('tags', e.target.value)}
                  className="input-field"
                  placeholder="casual, running, sport"
                />
                <p className="text-[10px] text-gray-400">Comma-separated</p>
              </div>

              {/* Actions */}
              <div className="space-y-3">
                <button type="submit" disabled={loading} className="btn-primary w-full py-3 text-sm disabled:opacity-60">
                  {loading ? (
                    <span className="flex items-center gap-2">
                      <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                      Saving…
                    </span>
                  ) : isEdit ? 'Update Product' : 'Add Product'}
                </button>
                <Link href="/products" className="btn-secondary w-full py-3 text-sm flex items-center justify-center gap-2">
                  <ArrowLeft size={14} /> Cancel
                </Link>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}
