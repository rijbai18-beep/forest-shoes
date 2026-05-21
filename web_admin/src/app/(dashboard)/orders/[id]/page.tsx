'use client'

import { useEffect, useState } from 'react'
import { doc, getDoc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Order } from '@/types'
import { formatCurrency, formatDateTime, ORDER_STATUSES, getStatusBadge } from '@/lib/utils'
import { useRouter } from 'next/navigation'
import toast from 'react-hot-toast'
import { ArrowLeft, MapPin, CreditCard, Truck } from 'lucide-react'

export default function OrderDetailPage({ params }: { params: { id: string } }) {
  const router = useRouter()
  const [order, setOrder] = useState<Order | null>(null)
  const [loading, setLoading] = useState(true)
  const [updatingStatus, setUpdatingStatus] = useState(false)

  useEffect(() => {
    loadOrder()
  }, [params.id])

  async function loadOrder() {
    const snap = await getDoc(doc(db, 'orders', params.id))
    if (snap.exists()) setOrder({ id: snap.id, ...snap.data() } as Order)
    setLoading(false)
  }

  async function updateStatus(status: string) {
    if (!order) return
    setUpdatingStatus(true)
    await updateDoc(doc(db, 'orders', order.id), { status, updatedAt: new Date() })
    setOrder(o => o ? { ...o, status } : o)
    toast.success('Status updated')
    setUpdatingStatus(false)
  }

  if (loading) return <div className="p-6">Loading...</div>
  if (!order) return <div className="p-6">Order not found</div>

  const badge = getStatusBadge(order.status, ORDER_STATUSES)

  return (
    <div className="p-6">
      <button onClick={() => router.back()} className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-900 mb-4">
        <ArrowLeft size={16} /> Back to Orders
      </button>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Order #{order.id.substring(0, 8).toUpperCase()}</h1>
        <p className="text-sm text-gray-400 mt-1">{formatDateTime(order.createdAt)}</p>
      </div>
      <div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left: Order details */}
          <div className="lg:col-span-2 space-y-5">
            {/* Items */}
            <div className="card p-6">
              <h3 className="font-semibold text-gray-900 mb-4">Order Items</h3>
              <div className="space-y-4">
                {order.items?.map((item, i) => (
                  <div key={i} className="flex items-center gap-4 p-3 bg-gray-50 rounded-xl">
                    <div className="w-16 h-16 rounded-lg bg-gray-200 overflow-hidden flex-shrink-0">
                      {item.imageUrl && <img src={item.imageUrl} alt="" className="w-full h-full object-cover" />}
                    </div>
                    <div className="flex-1">
                      <p className="font-semibold text-sm">{item.name}</p>
                      <p className="text-xs text-gray-500">
                        Size: {item.size} · Color: {item.color} · Qty: {item.quantity}
                      </p>
                      {item.engravingText && (
                        <p className="text-xs text-[#6c63ff] font-medium">Engraving: "{item.engravingText}"</p>
                      )}
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-sm">{formatCurrency(item.price * item.quantity)}</p>
                      {item.hasEngraving && (
                        <p className="text-xs text-gray-400">+{formatCurrency(item.engravingFee)} engraving</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              <div className="mt-4 pt-4 border-t border-gray-100 space-y-2">
                <div className="flex justify-between text-sm text-gray-600">
                  <span>Subtotal</span><span>{formatCurrency(order.subtotal)}</span>
                </div>
                {order.engravingFee > 0 && (
                  <div className="flex justify-between text-sm text-gray-600">
                    <span>Engraving</span><span>{formatCurrency(order.engravingFee)}</span>
                  </div>
                )}
                {order.couponDiscount > 0 && (
                  <div className="flex justify-between text-sm text-green-600">
                    <span>Discount ({order.couponCode})</span><span>-{formatCurrency(order.couponDiscount)}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm text-gray-600">
                  <span>Delivery</span><span>{formatCurrency(order.deliveryFee)}</span>
                </div>
                <div className="flex justify-between font-bold text-base pt-2 border-t border-gray-100">
                  <span>Total</span>
                  <span className="text-[#6c63ff]">{formatCurrency(order.total)}</span>
                </div>
              </div>
            </div>

            {/* Delivery address */}
            <div className="card p-6">
              <div className="flex items-center gap-2 mb-4">
                <MapPin size={18} className="text-[#6c63ff]" />
                <h3 className="font-semibold text-gray-900">Delivery Address</h3>
              </div>
              <div className="text-sm text-gray-600 space-y-1">
                <p className="font-semibold text-gray-900">{order.address?.name}</p>
                <p>{order.address?.phone}</p>
                <p>{order.address?.line1}</p>
                {order.address?.line2 && <p>{order.address.line2}</p>}
                <p>{order.address?.city}, {order.address?.postcode}</p>
                <p>{order.address?.country}</p>
              </div>
            </div>

            {/* Note */}
            {order.note && (
              <div className="card p-6">
                <h3 className="font-semibold text-gray-900 mb-2">Customer Note</h3>
                <p className="text-sm text-gray-600 italic">"{order.note}"</p>
              </div>
            )}
          </div>

          {/* Right: Status & Payment */}
          <div className="space-y-5">
            {/* Status */}
            <div className="card p-5">
              <h3 className="font-semibold text-gray-900 mb-3">Order Status</h3>
              <span className={`badge-${badge.color} mb-4 inline-block`}>{badge.label}</span>
              <div className="mt-3">
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Update Status</label>
                <select
                  value={order.status}
                  onChange={e => updateStatus(e.target.value)}
                  disabled={updatingStatus}
                  className="input-field"
                >
                  {ORDER_STATUSES.map(s => (
                    <option key={s.value} value={s.value}>{s.label}</option>
                  ))}
                </select>
              </div>
            </div>

            {/* Payment info */}
            <div className="card p-5">
              <div className="flex items-center gap-2 mb-3">
                <CreditCard size={16} className="text-[#6c63ff]" />
                <h3 className="font-semibold text-gray-900">Payment</h3>
              </div>
              <div className="text-sm space-y-2">
                <div className="flex justify-between">
                  <span className="text-gray-500">Method</span>
                  <span className="font-medium">{order.paymentType}</span>
                </div>
                {order.couponCode && (
                  <div className="flex justify-between">
                    <span className="text-gray-500">Coupon</span>
                    <span className="font-medium text-green-600">{order.couponCode}</span>
                  </div>
                )}
              </div>
            </div>

            {/* Delivery info */}
            <div className="card p-5">
              <div className="flex items-center gap-2 mb-3">
                <Truck size={16} className="text-[#6c63ff]" />
                <h3 className="font-semibold text-gray-900">Delivery</h3>
              </div>
              <div className="text-sm space-y-2">
                <div className="flex justify-between">
                  <span className="text-gray-500">Method</span>
                  <span className="font-medium">{order.deliveryType}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Fee</span>
                  <span className="font-medium">{formatCurrency(order.deliveryFee)}</span>
                </div>
              </div>
            </div>

            {/* Customer */}
            <div className="card p-5">
              <h3 className="font-semibold text-gray-900 mb-3">Customer</h3>
              <div className="text-sm space-y-1">
                <p className="font-medium">{order.address?.name}</p>
                <p className="text-gray-500">{order.address?.phone}</p>
                <p className="text-gray-500 text-xs">User ID: {order.userId?.substring(0, 12)}...</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
