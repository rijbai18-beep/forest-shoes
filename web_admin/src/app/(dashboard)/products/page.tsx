'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, query, orderBy, doc, updateDoc, deleteDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Product } from '@/types'
import { formatCurrency } from '@/lib/utils'
import Link from 'next/link'
import toast from 'react-hot-toast'
import {
  Card, Title, Text, Flex, Badge, TextInput, Button,
  Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell, Color,
} from '@tremor/react'
import { MagnifyingGlassIcon, PlusIcon, PencilIcon, TrashIcon, EyeIcon, EyeSlashIcon, StarIcon } from '@heroicons/react/24/outline'
import { StarIcon as StarSolid } from '@heroicons/react/24/solid'

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading]   = useState(true)
  const [search, setSearch]     = useState('')
  const [catFilter, setCatFilter] = useState('')

  useEffect(() => { load() }, [])
  async function load() {
    const snap = await getDocs(query(collection(db, 'products'), orderBy('createdAt', 'desc')))
    setProducts(snap.docs.map(d => ({ id: d.id, ...d.data() } as Product)))
    setLoading(false)
  }

  async function toggleActive(p: Product) {
    await updateDoc(doc(db, 'products', p.id), { isActive: !p.isActive })
    toast.success(p.isActive ? 'Product hidden' : 'Product activated')
    setProducts(ps => ps.map(x => x.id === p.id ? { ...x, isActive: !x.isActive } : x))
  }
  async function toggleFeatured(p: Product) {
    await updateDoc(doc(db, 'products', p.id), { isFeatured: !p.isFeatured })
    setProducts(ps => ps.map(x => x.id === p.id ? { ...x, isFeatured: !x.isFeatured } : x))
  }
  async function del(id: string) {
    if (!confirm('Delete this product?')) return
    await deleteDoc(doc(db, 'products', id))
    toast.success('Deleted')
    setProducts(ps => ps.filter(p => p.id !== id))
  }

  const cats     = Array.from(new Set(products.map(p => p.category))).filter(Boolean)
  const filtered = products.filter(p =>
    (p.name.toLowerCase().includes(search.toLowerCase())) &&
    (!catFilter || p.category === catFilter)
  )
  const active = products.filter(p => p.isActive).length
  const low    = products.filter(p => p.stock <= 5).length

  const stockColor = (n: number): Color => n <= 5 ? 'red' : n <= 20 ? 'amber' : 'green'

  return (
    <main className="p-6 space-y-6">
      <Flex>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Products</h1>
          <Text className="mt-1">{products.length} total · {active} active{low > 0 ? ` · ${low} low stock` : ''}</Text>
        </div>
        <Link href="/products/add">
          <Button icon={PlusIcon} color="green">Add Product</Button>
        </Link>
      </Flex>

      <Card>
        <Flex className="gap-3 mb-4 flex-col sm:flex-row" justifyContent="start">
          <TextInput icon={MagnifyingGlassIcon} placeholder="Search products…" value={search} onValueChange={setSearch} className="max-w-xs" />
          <select value={catFilter} onChange={e => setCatFilter(e.target.value)}
            className="border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-600/20 bg-white">
            <option value="">All categories</option>
            {cats.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </Flex>

        {loading ? (
          <div className="flex justify-center py-20"><div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" /></div>
        ) : (
          <Table>
            <TableHead>
              <TableRow>
                <TableHeaderCell>Product</TableHeaderCell>
                <TableHeaderCell>Category</TableHeaderCell>
                <TableHeaderCell>Price</TableHeaderCell>
                <TableHeaderCell>Stock</TableHeaderCell>
                <TableHeaderCell>Status</TableHeaderCell>
                <TableHeaderCell className="text-right">Actions</TableHeaderCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.length === 0 ? (
                <TableRow><TableCell colSpan={6} className="text-center py-12 text-gray-400">No products found</TableCell></TableRow>
              ) : filtered.map(p => (
                <TableRow key={p.id} className="hover:bg-gray-50 group">
                  <TableCell>
                    <Flex justifyContent="start" className="gap-3">
                      <div className="w-12 h-12 rounded-xl bg-gray-100 overflow-hidden flex-shrink-0 ring-1 ring-gray-100">
                        {p.images?.[0]
                          ? <img src={p.images[0]} alt="" className="w-full h-full object-cover" />
                          : <div className="w-full h-full flex items-center justify-center text-gray-300 text-xl">👟</div>}
                      </div>
                      <div className="min-w-0">
                        <Text className="font-bold text-gray-900 truncate max-w-[180px]">{p.name}</Text>
                        <div className="flex gap-1 mt-1">
                          {p.hasEngraving && <Badge size="xs" color="blue">Engravable</Badge>}
                          {p.isFeatured   && <Badge size="xs" color="yellow">Featured</Badge>}
                          {p.gender       && <Badge size="xs" color="gray">{p.gender}</Badge>}
                        </div>
                      </div>
                    </Flex>
                  </TableCell>
                  <TableCell className="text-gray-500">{p.category}</TableCell>
                  <TableCell>
                    {p.salePrice
                      ? <div><span className="font-bold text-red-600 text-sm">{formatCurrency(p.salePrice)}</span><span className="text-xs text-gray-400 line-through ml-1.5">{formatCurrency(p.price)}</span></div>
                      : <span className="font-bold text-sm">{formatCurrency(p.price)}</span>}
                  </TableCell>
                  <TableCell><Badge color={stockColor(p.stock)}>{p.stock} units</Badge></TableCell>
                  <TableCell><Badge color={p.isActive ? 'green' : 'gray'}>{p.isActive ? 'Active' : 'Hidden'}</Badge></TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end gap-1">
                      <button onClick={() => toggleFeatured(p)} title="Toggle featured"
                        className={"p-1.5 rounded-lg transition-colors " + (p.isFeatured ? 'text-amber-500 bg-amber-50' : 'hover:bg-gray-100 text-gray-400')}>
                        {p.isFeatured ? <StarSolid className="w-4 h-4" /> : <StarIcon className="w-4 h-4" />}
                      </button>
                      <button onClick={() => toggleActive(p)} title="Toggle visibility"
                        className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-700 transition-colors">
                        {p.isActive ? <EyeSlashIcon className="w-4 h-4" /> : <EyeIcon className="w-4 h-4" />}
                      </button>
                      <Link href={"/products/add?id=" + p.id}
                        className="p-1.5 rounded-lg hover:bg-blue-50 text-gray-400 hover:text-blue-600 transition-colors">
                        <PencilIcon className="w-4 h-4" />
                      </Link>
                      <button onClick={() => del(p.id)}
                        className="p-1.5 rounded-lg hover:bg-red-50 text-gray-400 hover:text-red-600 transition-colors">
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
    </main>
  )
}
