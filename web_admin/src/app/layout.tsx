import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import '@/styles/globals.css'
import { AuthProvider } from '@/contexts/AuthContext'
import { Toaster } from 'react-hot-toast'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Forest Shoes Admin',
  description: 'Admin panel for Forest Shoes e-commerce',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <AuthProvider>
          {children}
          <Toaster
            position="top-right"
            toastOptions={{
              style: { borderRadius: '10px', background: '#1A1A1A', color: '#fff' },
              success: { iconTheme: { primary: '#6c63ff', secondary: '#fff' } },
            }}
          />
        </AuthProvider>
      </body>
    </html>
  )
}
