'use client'

import { useEffect, useState } from 'react'
import { collection, getDocs, query, orderBy, doc, updateDoc } from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { db, functions } from '@/lib/firebase'
import { useAuth } from '@/contexts/AuthContext'
import { User } from '@/types'
import { formatDate } from '@/lib/utils'
import toast from 'react-hot-toast'
import {
  Card, Text, Flex, Badge, TextInput,
  Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell,
} from '@tremor/react'
import {
  MagnifyingGlassIcon, ShieldCheckIcon, ShieldExclamationIcon,
  UserMinusIcon, UserPlusIcon,
} from '@heroicons/react/24/outline'

export default function UsersPage() {
  const { user: currentUser } = useAuth()
  const [users, setUsers]           = useState<User[]>([])
  const [loading, setLoading]       = useState(true)
  const [search, setSearch]         = useState('')
  const [togglingAdminUid, setTogglingAdminUid] = useState<string | null>(null)

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

  async function toggleAdmin(u: User) {
    const action = u.isAdmin ? 'Remove admin access from' : 'Grant admin access to'
    if (!confirm(`${action} ${u.name}?\n\n${u.isAdmin ? 'They will no longer be able to sign in to the admin panel.' : 'They will have full access to the admin panel.'}`)) return
    setTogglingAdminUid(u.uid)
    try {
      await httpsCallable(functions, 'setAdminRole')({ uid: u.uid, isAdmin: !u.isAdmin })
      setUsers(us => us.map(x => x.uid === u.uid ? { ...x, isAdmin: !x.isAdmin } : x))
      toast.success(u.isAdmin ? `Admin access removed from ${u.name}` : `${u.name} is now an admin`)
    } catch (err: any) {
      toast.error(err.message || 'Failed to update admin role')
    } finally {
      setTogglingAdminUid(null)
    }
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
          <TextInput
            icon={MagnifyingGlassIcon}
            placeholder="Search by name or email…"
            value={search}
            onValueChange={setSearch}
            className="max-w-xs"
          />
        </Flex>

        {loading ? (
          <div className="flex justify-center py-20">
            <div className="w-8 h-8 border-[3px] border-brand-600 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <Table>
            <TableHead>
              <TableRow>
                <TableHeaderCell>User</TableHeaderCell>
                <TableHeaderCell>Phone</TableHeaderCell>
                <TableHeaderCell>Role</TableHeaderCell>
                <TableHeaderCell>Joined</TableHeaderCell>
                <TableHeaderCell>Status</TableHeaderCell>
                <TableHeaderCell className="text-right">Actions</TableHeaderCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-12 text-gray-400">
                    No users found
                  </TableCell>
                </TableRow>
              ) : filtered.map(u => (
                <TableRow key={u.uid} className="hover:bg-gray-50">
                  <TableCell>
                    <Flex justifyContent="start" className="gap-3">
                      <div className="w-9 h-9 rounded-xl bg-brand-600 flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                        {(u.name || u.email || 'U').slice(0, 1).toUpperCase()}
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
                  <TableCell className="text-gray-500 text-sm">
                    {u.createdAt ? formatDate(u.createdAt) : '—'}
                  </TableCell>
                  <TableCell>
                    <Badge color={u.isActive !== false ? 'green' : 'red'}>
                      {u.isActive !== false ? 'Active' : 'Deactivated'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex justify-end gap-1">

                      {/* Admin role toggle */}
                      <button
                        onClick={() => toggleAdmin(u)}
                        disabled={u.uid === currentUser?.uid || togglingAdminUid === u.uid}
                        title={
                          u.uid === currentUser?.uid
                            ? "Can't change your own role"
                            : u.isAdmin
                              ? 'Remove admin access'
                              : 'Grant admin access'
                        }
                        className={[
                          'p-1.5 rounded-lg transition-colors',
                          u.uid === currentUser?.uid
                            ? 'opacity-30 cursor-not-allowed text-gray-400'
                            : u.isAdmin
                              ? 'text-gray-400 hover:text-orange-600 hover:bg-orange-50'
                              : 'text-gray-400 hover:text-brand-600 hover:bg-brand-50',
                        ].join(' ')}
                      >
                        {togglingAdminUid === u.uid ? (
                          <div className="w-4 h-4 border border-gray-400 border-t-transparent rounded-full animate-spin" />
                        ) : u.isAdmin ? (
                          <ShieldExclamationIcon className="w-4 h-4" />
                        ) : (
                          <ShieldCheckIcon className="w-4 h-4" />
                        )}
                      </button>

                      {/* Active / deactivate toggle */}
                      <button
                        onClick={() => toggleActive(u)}
                        title={u.isActive !== false ? 'Deactivate account' : 'Activate account'}
                        className={[
                          'p-1.5 rounded-lg transition-colors',
                          u.isActive !== false
                            ? 'text-gray-400 hover:text-red-600 hover:bg-red-50'
                            : 'text-gray-400 hover:text-green-600 hover:bg-green-50',
                        ].join(' ')}
                      >
                        {u.isActive !== false
                          ? <UserMinusIcon className="w-4 h-4" />
                          : <UserPlusIcon className="w-4 h-4" />}
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
