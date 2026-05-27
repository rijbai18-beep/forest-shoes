import { Timestamp } from 'firebase/firestore'

export interface Product {
  id: string
  name: string
  description: string
  category: string
  gender?: string
  images: string[]
  price: number
  salePrice?: number
  colors: string[]
  sizes: string[]
  stock: number
  hasEngraving: boolean
  engravingFee: number
  engravingMaxChars: number
  tags: string[]
  isActive: boolean
  rating: number
  reviewCount: number
  isFeatured: boolean
  createdAt: Timestamp
  customFields?: Record<string, string>
}

export interface Category {
  id: string
  name: string
  imageUrl?: string
  isActive: boolean
  customFields: CustomField[]
}

export interface CustomField {
  name: string
  type: 'text' | 'number' | 'boolean' | 'select'
  options?: string[]
  required: boolean
}

export interface Order {
  id: string
  orderNumber?: string
  userId: string
  userEmail?: string
  userName?: string
  items: OrderItem[]
  subtotal: number
  deliveryFee: number
  engravingFee: number
  couponDiscount: number
  total: number
  paymentType: string
  paymentTypeId: string
  deliveryType: string
  deliveryTypeId: string
  status: string
  address: Address
  note?: string
  couponCode?: string
  couponId?: string
  isPostage: boolean
  createdAt: Timestamp
  updatedAt: Timestamp
  paymentProof?: Record<string, string>
}

export interface OrderItem {
  productId: string
  name: string
  imageUrl: string
  price: number
  size: string
  color: string
  quantity: number
  hasEngraving: boolean
  engravingText?: string
  engravingFee: number
}

export interface Address {
  name: string
  phone: string
  line1: string
  line2?: string
  city: string
  postcode: string
  country: string
}

export interface User {
  uid: string
  email: string
  name: string
  phone?: string
  photoUrl?: string
  addresses: Address[]
  isActive: boolean
  isAdmin: boolean
  fcmTokens: string[]
  createdAt: Timestamp
}

export interface Coupon {
  id: string
  code: string
  type: 'percentage' | 'amount'
  value: number
  minOrder?: number
  maxDiscount?: number
  maxUses?: number
  usedCount: number
  expiresAt?: Timestamp
  isActive: boolean
}

export interface Banner {
  id: string
  imageUrl: string
  link?: string
  order: number
  isActive: boolean
  createdAt: Timestamp
}

export interface PaymentType {
  id: string
  name: string
  description?: string
  icon?: string
  fee: number
  instructions?: string
  isActive: boolean
}

export interface DeliveryType {
  id: string
  name: string
  description?: string
  fee: number
  estimatedDays?: string
  isActive: boolean
}

export interface SupportTicket {
  id: string
  userId: string
  userName: string
  userEmail?: string
  subject: string
  status: string
  unreadCount: number
  createdAt: Timestamp
  lastReply: Timestamp
}

export interface TicketMessage {
  id: string
  senderId: string
  senderName: string
  message: string
  isAdmin: boolean
  createdAt: Timestamp
}

export interface StockAlert {
  id: string
  productId: string
  productName: string
  stock: number
  threshold: number
  resolved: boolean
  createdAt: Timestamp
}

export interface AppSettings {
  stockAlertThreshold: number
  freeDeliveryThreshold: number
  currency: string
}

export interface ContentDoc {
  content: string
  updatedAt: Timestamp
}

export interface DashboardStats {
  totalOrders: number
  totalRevenue: number
  totalProducts: number
  totalUsers: number
  recentOrders: Order[]
  stockAlerts: StockAlert[]
  ordersByStatus: Record<string, number>
  revenueByMonth: { month: string; revenue: number }[]
}
