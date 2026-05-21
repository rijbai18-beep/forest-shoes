import { initializeApp, getApps, getApp, FirebaseApp } from 'firebase/app'
import { getFirestore, Firestore } from 'firebase/firestore'
import { getAuth, Auth } from 'firebase/auth'
import { getStorage, FirebaseStorage } from 'firebase/storage'
import { getFunctions, Functions } from 'firebase/functions'

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
}

function getFirebaseApp(): FirebaseApp {
  if (getApps().length) return getApp()
  return initializeApp(firebaseConfig)
}

const app = typeof window !== 'undefined' ? getFirebaseApp() : ({} as FirebaseApp)

export const db = typeof window !== 'undefined' ? getFirestore(app) : ({} as Firestore)
export const auth = typeof window !== 'undefined' ? getAuth(app) : ({} as Auth)
export const storage = typeof window !== 'undefined' ? getStorage(app) : ({} as FirebaseStorage)
export const functions = typeof window !== 'undefined' ? getFunctions(app) : ({} as Functions)
export default app
