'use client'

import { useEffect, useState } from 'react'
import {
  collection, getDocs, addDoc, doc, updateDoc, deleteDoc,
  serverTimestamp, orderBy, query,
} from 'firebase/firestore'
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage'
import { db, storage } from '@/lib/firebase'
import { Banner } from '@/types'
import toast from 'react-hot-toast'
import { Card, Text, Flex, Badge, Button } from '@tremor/react'
import {
  PlusIcon, TrashIcon, EyeIcon, EyeSlashIcon,
  ArrowUpIcon, ArrowDownIcon, ArrowUpTrayIcon, XMarkIcon,
  PhotoIcon,
} from '@heroicons/react/24/outline'

export default function BannersPage() {
  const [banners, setBanners] = useState<Banner[]>([])
  const [loading, setLoading] = useState(true)
  const [uploading, setUploading] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [newLink, setNewLink] = useState('')
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string>('')

  useEffect(() => { loadBanners() }, [])

  async function loadBanners() {
    const snap = await getDocs(query(collection(db, 'banners'), orderBy('order', 'asc')))
    setBanners(snap.docs.map(d => ({ id: d.id, ...d.data() } as Banner)))
    setLoading(false)
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    if (!file.type.match('image/(png|jpeg|jpg|webp)')) {
      toast.error('Only PNG, JPEG, or WebP allowed')
      return
    }
    setSelectedFile(file)
    setPreview(URL.createObjectURL(file))
  }

  async function uploadBanner() {
    if (!selectedFile) return toast.error('Select an image first')
    setUploading(true)
    try {
      const r = ref(storage, `banners/${Date.now()}/${selectedFile.name}`)
      await uploadBytes(r, selectedFile)
      const url = await getDownloadURL(r)
      await addDoc(collection(db, 'banners'), {
        imageUrl: url, link: newLink || null, order: banners.length,
        isActive: true, createdAt: serverTimestamp(),
      })
      toast.success('Banner uploaded!')
      closeModal()
      loadBanners()
    } finally { setUploading(false) }
  }

  function closeModal() {
    setShowModal(false)
    setSelectedFile(null)
    setPreview('')
    setNewLink('')
  }

  async function toggleActive(banner: Banner) {
    await updateDoc(doc(db, 'banners', banner.id), { isActive: !banner.isActive })
    setBanners(bs => bs.map(b => b.id === banner.id ? { ...b, isActive: !b.isActive } : b))
  }

  async function deleteBanner(banner: Banner) {
    if (!confirm('Delete this banner?')) return
    try { await deleteObject(ref(storage, banner.imageUrl)) } catch {}
    await deleteDoc(doc(db, 'banners', banner.id))
    setBanners(bs => bs.filter(b => b.id !== banner.id))
    toast.success('Banner deleted')
  }

  async function move(i: number, dir: 'up' | 'down') {
    const j = dir === 'up' ? i - 1 : i + 1
    const newBanners = [...banners]
    ;[newBanners[i], newBanners[j]] = [newBanners[j], newBanners[i]]
    setBanners(newBanners)
    await Promise.all([
      updateDoc(doc(db, 'banners', newBanners[i].id), { order: i }),
      updateDoc(doc(db, 'banners', newBanners[j].id), { order: j }),
    ])
  }

  return (
    <main className="p-6 space-y-6">
      <Flex>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Banners</h1>
          <Text className="mt-1">{banners.length} banners · {banners.filter(b => b.isActive).length} active</Text>
        </div>
        <Button icon={PlusIcon} color="green" onClick={() => setShowModal(true)}>Add Banner</Button>
      </Flex>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : banners.length === 0 ? (
        <Card className="flex flex-col items-center justify-center py-20 gap-3 text-gray-400">
          <PhotoIcon className="w-12 h-12 text-gray-200" />
          <Text>No banners yet. Upload your first banner.</Text>
          <Button icon={PlusIcon} variant="secondary" color="green" onClick={() => setShowModal(true)}>Upload Now</Button>
        </Card>
      ) : (
        <div className="space-y-3">
          {banners.map((banner, i) => (
            <Card key={banner.id} className="p-4">
              <div className="flex items-center gap-4">
                {/* Thumbnail */}
                <div className="w-44 h-22 rounded-xl overflow-hidden flex-shrink-0 ring-1 ring-gray-100">
                  <img src={banner.imageUrl} alt="" className="w-full h-full object-cover" style={{ height: '88px' }} />
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">#{i + 1}</span>
                    <Badge color={banner.isActive ? 'green' : 'gray'} size="xs">
                      {banner.isActive ? 'Active' : 'Hidden'}
                    </Badge>
                  </div>
                  {banner.link ? (
                    <p className="text-sm text-brand-700 font-medium truncate">{banner.link}</p>
                  ) : (
                    <p className="text-sm text-gray-400">No link</p>
                  )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 flex-shrink-0">
                  <button onClick={() => move(i, 'up')} disabled={i === 0}
                    className="p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 disabled:opacity-25 transition-colors">
                    <ArrowUpIcon className="w-4 h-4" />
                  </button>
                  <button onClick={() => move(i, 'down')} disabled={i === banners.length - 1}
                    className="p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 disabled:opacity-25 transition-colors">
                    <ArrowDownIcon className="w-4 h-4" />
                  </button>
                  <button onClick={() => toggleActive(banner)}
                    className="p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 transition-colors">
                    {banner.isActive ? <EyeSlashIcon className="w-4 h-4" /> : <EyeIcon className="w-4 h-4" />}
                  </button>
                  <button onClick={() => deleteBanner(banner)}
                    className="p-1.5 rounded-lg text-gray-400 hover:bg-red-50 hover:text-red-500 transition-colors">
                    <TrashIcon className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* ── Upload Modal ─────────────────────────────────────────────── */}
      {showModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-[2px] flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-2xl animate-fade-in">
            <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
              <div>
                <h2 className="text-base font-bold text-gray-900">Add Banner</h2>
                <p className="text-xs text-gray-400 mt-0.5">Upload a new homepage banner</p>
              </div>
              <button onClick={closeModal} className="p-2 rounded-xl hover:bg-gray-100 text-gray-400">
                <XMarkIcon className="w-5 h-5" />
              </button>
            </div>

            <div className="px-6 py-5 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
                  Image <span className="text-red-400">*</span>
                </label>
                {preview ? (
                  <div className="relative rounded-xl overflow-hidden">
                    <img src={preview} alt="" className="w-full h-44 object-cover" />
                    <button
                      onClick={() => { setSelectedFile(null); setPreview('') }}
                      className="absolute top-2 right-2 w-7 h-7 bg-black/50 rounded-full flex items-center justify-center hover:bg-red-500 transition-colors"
                    >
                      <XMarkIcon className="w-4 h-4 text-white" />
                    </button>
                    <div className="absolute bottom-2 left-2 bg-black/50 text-white text-xs px-2 py-1 rounded-lg font-medium">
                      {selectedFile?.name}
                    </div>
                  </div>
                ) : (
                  <label className="flex flex-col items-center justify-center w-full h-44 border-2 border-dashed border-gray-200 rounded-xl cursor-pointer hover:border-brand-600 hover:bg-green-50/50 transition-all group">
                    <ArrowUpTrayIcon className="w-8 h-8 text-gray-300 group-hover:text-brand-600 mb-2 transition-colors" />
                    <span className="text-sm font-medium text-gray-400 group-hover:text-brand-600 transition-colors">Click to upload</span>
                    <span className="text-xs text-gray-300 mt-1">PNG, JPEG, WebP · Recommended 1200×400</span>
                    <input type="file" accept="image/png,image/jpeg,image/jpg,image/webp" className="hidden" onChange={handleFileSelect} />
                  </label>
                )}
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase tracking-wide">
                  Deep Link (optional)
                </label>
                <input
                  value={newLink}
                  onChange={e => setNewLink(e.target.value)}
                  className="input-field"
                  placeholder="/shop?category=sneakers"
                />
                <p className="text-xs text-gray-400 mt-1">Where the banner taps to in the app</p>
              </div>
            </div>

            <div className="flex gap-3 px-6 pb-6">
              <Button color="green" loading={uploading} disabled={!selectedFile} className="flex-1" onClick={uploadBanner}>
                {uploading ? 'Uploading…' : 'Upload Banner'}
              </Button>
              <Button variant="secondary" className="flex-1" onClick={closeModal}>Cancel</Button>
            </div>
          </div>
        </div>
      )}
    </main>
  )
}
