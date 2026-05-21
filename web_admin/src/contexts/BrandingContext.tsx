'use client'

import { createContext, useContext, useEffect, useState } from 'react'
import { doc, onSnapshot, setDoc, serverTimestamp } from 'firebase/firestore'
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage'
import { db, storage } from '@/lib/firebase'

interface BrandingContextType {
  logoUrl: string | null
  isLoading: boolean
  uploadLogo: (file: File) => Promise<void>
}

const BrandingContext = createContext<BrandingContextType>({
  logoUrl: null,
  isLoading: true,
  uploadLogo: async () => {},
})

export function BrandingProvider({ children }: { children: React.ReactNode }) {
  const [logoUrl, setLogoUrl] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    if (typeof window === 'undefined') return
    const unsub = onSnapshot(doc(db, 'settings', 'branding'), (snap) => {
      setLogoUrl(snap.data()?.logoUrl ?? null)
      setIsLoading(false)
    })
    return unsub
  }, [])

  const uploadLogo = async (file: File) => {
    const storageRef = ref(storage, 'branding/logo')
    await uploadBytes(storageRef, file, { contentType: file.type })
    const url = await getDownloadURL(storageRef)
    await setDoc(doc(db, 'settings', 'branding'), {
      logoUrl: url,
      updatedAt: serverTimestamp(),
    }, { merge: true })
  }

  return (
    <BrandingContext.Provider value={{ logoUrl, isLoading, uploadLogo }}>
      {children}
    </BrandingContext.Provider>
  )
}

export function useBranding() {
  return useContext(BrandingContext)
}
