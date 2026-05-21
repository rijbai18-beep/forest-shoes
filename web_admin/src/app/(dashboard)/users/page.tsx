'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, query, orderBy, doc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { User } from '@/types'
import { formatDate } from '@/lib/utils'
import toast from 'react-hot-toast'
import {
  Card, Text, Flex, Badge, TextInput, Color,
  Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell,
} from '@tremor/react'
import { MagnifyingGlassIcon, ShieldCheckIcon, UserMinusIcon, UserPlusIcon } from '@heroicons/react/24/outline'

export default function UsersPage() {
  const [users, setUsers]     = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch]   = useState('')

  useEffect(() => { load() }, [])
  async function load() {
    const snap = await getDocs(query(collection(db, 'users'), orderBy('createdAt', 'desc')))
    setUsers(snap.docs.map(d => ({ uid: d.id, ...d.data() } as User)))
    setLoading(false)
  }

  async function toggleActive(u: User) {
    if (!confirm((u.isActive ? 'Deactivate' : 'Activate') + ' account for ' + u.name + '?')) return
    await updateDoc(doc(db, 'users', u.uid), { isActive: !u.isActive })
    setUsers(us => us.map(x => x.uid === u.uid ? { ...x, isActive: !x.isActive } : x))
    toast.success(u.isActive ? 'User deactivated' : 'User activated')
  }

  const filtered = users.filter(u =>
    u.name?.toLowerCase().includes(search.toLowerCase()) ||
    u.email?.toLowerCase().includes(search.toLowerCase())
  )
  const active = users.filter(u => u.isActive !== false).length

  return (
    <main className="p-6 space-y-6">
      <Flex>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <Text className="mt-1">{users.length} registered · {active} active</Text>
        </div>
      </Flex>

      <Card>
        <Flex className="mb-4" justifyContent="start">
          <TextInput icon={MagnifyingGlassIcon} placeholder="Search by name or email…" value={search} onValueChange={setSearch} className="max-w-xs" />
        </Flex>

        {loading ? (
          <div className="flex justify-center py-20"><div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" /></div>
        ) : (
          <Table>
            <TableHead>
              <TableRow>
                <TableHeaderCell>User</TableHeaderCell>
                <TableHeaderCell>Phone</TableHeaderCell>
                <TableHeaderCell>Role</TableHeaderCell>
                <TableHeaderCell>Joined</TableHeaderCell>
                <TableHeaderCell>Status</TableHeaderCell>
                <TableHeaderCell className="text-right">Action</TableHeaderCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.length === 0 ? (
                <TableRow><TableCell colSpan={6} className="text-center py-12 text-gray-400">No users found</TableCell></TableRow>
              ) : filtered.map(u => (
                <TableRow key={u.uid} className="hover:bg-gray-50">
                  <TableCell>
                    <Flex justifyContent="start" className="gap-3">
                      <div className="w-9 h-9 rounded-xl bg-brand-600 flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                        {(u.name || u.email || 'U').slice(0,1).toUpperCase()}
                      </div>
                      <div>
                        <div className="font-semibold text-gray-900 text-sm">{u.name}</div>
                        <div className="text-xs text-gray-400">{u.email}</div>
                      </div>
                    </Flex>
                  </TableCell>
                  <TableCell className="text-gray-500 text-sm">{u.phone ?? '—'}</TableCell>
                  <TableCell>
                    {u.isAdmin
                      ? <Badge icon={ShieldCheckIcon} color="green">Admin</Badge>
                      : <Badge color="gray">Customer</Badge>}
                  </TableCell>
                  <TableCell className="text-gray-500 text-sm">{u.createdAt ? formatDate(u.createdAt) : '—'}</TableCell>
                  <TableCell>
                    <Badge color={u.isActive !== false ? 'green' : 'red'}>
                      {u.isActive !== false ? 'Active' : 'Deactivated'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex justify-end">
                      <button onClick={() => toggleActive(u)}
                        className={"p-1.5 rounded-lg transition-colors " + (u.isActive !== false ? 'text-gray-400 hover:text-red-600 hover:bg-red-50' : 'text-gray-400 hover:text-green-600 hover:bg-green-50')}>
                        {u.isActive !== false ? <UserMinusIcon className="w-4 h-4" /> : <UserPlusIcon className="w-4 h-4" />}
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
