import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'
import { format } from 'date-fns'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return `Rs ${amount.toLocaleString('en-MU', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`
}

export function formatDate(date: Date | { toDate: () => Date } | string | number | null | undefined): string {
  if (date == null) return '—'
  const d = typeof date === 'object' && 'toDate' in date ? date.toDate() : new Date(date as string | number | Date)
  return format(d, 'dd MMM yyyy')
}

export function formatDateTime(date: Date | { toDate: () => Date } | string | number | null | undefined): string {
  if (date == null) return '—'
  const d = typeof date === 'object' && 'toDate' in date ? date.toDate() : new Date(date as string | number | Date)
  return format(d, 'dd MMM yyyy, HH:mm')
}

export const ORDER_STATUSES = [
  { value: 'new', label: 'New', color: 'blue' },
  { value: 'pending_payment', label: 'Pending Payment', color: 'yellow' },
  { value: 'reviewed', label: 'Payment Reviewed', color: 'green' },
  { value: 'processing', label: 'Processing', color: 'yellow' },
  { value: 'dispatched', label: 'Dispatched', color: 'blue' },
  { value: 'delivered', label: 'Delivered', color: 'green' },
  { value: 'cancelled', label: 'Cancelled', color: 'red' },
]

export const TICKET_STATUSES = [
  { value: 'open', label: 'Open', color: 'green' },
  { value: 'in_progress', label: 'In Progress', color: 'yellow' },
  { value: 'closed', label: 'Closed', color: 'gray' },
]

export function getStatusBadge(status: string, statuses: typeof ORDER_STATUSES) {
  return statuses.find(s => s.value === status) ?? { value: status, label: status, color: 'gray' }
}

export function uploadProgress(snapshot: { bytesTransferred: number; totalBytes: number }): number {
  return Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100)
}
