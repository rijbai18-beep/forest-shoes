# Forest Shoes

A full-stack e-commerce platform for a shoe business — Flutter mobile app (Android & iOS) + Next.js admin dashboard, backed by Firebase.

## Project Structure

```
ForestShoes/
├── backend/          # Firebase config, Firestore rules, Cloud Functions
├── mobile/           # Flutter app (Android & iOS)
└── web_admin/        # Next.js admin dashboard
```

---

## Prerequisites

- **Firebase CLI** — `npm install -g firebase-tools`
- **Flutter SDK** ≥ 3.19 — https://docs.flutter.dev/get-started/install
- **Node.js** ≥ 20 (for Cloud Functions)
- A **Firebase project** (Blaze plan required for Cloud Functions + FCM)

---

## 1 — Firebase Setup

### Create Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com) → **Add project** → `forest-shoes-app`
2. Enable **Firestore**, **Authentication** (Email/Password), **Storage**, **Functions**, and **Cloud Messaging**

### Configure project

```bash
cd backend
firebase login
firebase use --add   # select your project and alias as "default"
```

### Deploy Firestore rules, indexes, Storage rules

```bash
cd backend
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### Deploy Cloud Functions

```bash
cd backend/functions
npm install
cd ..
firebase deploy --only functions
```

### Set Cloud Function environment config

The `onOrderCreated` function sends email receipts. Set up a Gmail or SMTP account:

```bash
firebase functions:config:set \
  mail.user="your-email@gmail.com" \
  mail.pass="your-app-password" \
  mail.from="Forest Shoes <your-email@gmail.com>"
```

### Create the first admin user

1. Register a user in the mobile app or Firebase Console
2. Call the `setAdminRole` Cloud Function with that user's UID (use Firebase Admin SDK or the Firebase Console → Functions → Shell):

```js
// In Firebase Functions shell
setAdminRole({ uid: "USER_UID_HERE" })
```

Or use the Firebase Admin SDK in a one-off Node script:

```js
const admin = require('firebase-admin')
admin.initializeApp()
await admin.auth().setCustomUserClaims('USER_UID', { admin: true })
await admin.firestore().doc('users/USER_UID').update({ isAdmin: true })
```

---

## 2 — Flutter Mobile App

### Add Firebase config files

Download from Firebase Console → Project settings → Your apps:

- `google-services.json` → `mobile/android/app/`
- `GoogleService-Info.plist` → `mobile/ios/Runner/`

### Install dependencies and run

```bash
cd mobile
flutter pub get
flutter run
```

### Build for release

```bash
# Android
flutter build apk --release

# iOS (requires Xcode + Apple Developer account)
flutter build ipa --release
```

### Firebase Messaging (Android)

In `mobile/android/app/build.gradle`, ensure `minSdkVersion` ≥ 21.

---

## 3 — Next.js Admin Dashboard

### Environment variables

Create `web_admin/.env.local`:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
```

Copy these values from Firebase Console → Project settings → Web app config.

### Install and run

```bash
cd web_admin
npm install
npm run dev       # http://localhost:3000
```

### Build for production

```bash
npm run build
npm start
```

Or deploy to Vercel:

```bash
npm install -g vercel
vercel --prod
```

---

## Firestore Collections

| Collection | Description |
|---|---|
| `products` | Product catalogue |
| `categories` | Product categories with custom field schemas |
| `orders` | Customer orders |
| `users` | User profiles |
| `banners` | Home screen carousel images |
| `coupons` | Discount codes |
| `paymentTypes` | Payment methods (e.g. bank transfer) |
| `deliveryTypes` | Shipping options |
| `stockAlerts` | Low-stock alerts triggered by Cloud Functions |
| `notifications` | Per-user in-app notifications |
| `supportTickets` | Customer support threads |
| `supportTickets/{id}/messages` | Chat messages within a ticket |
| `content` | CMS docs: terms, privacy, dataPrivacy, about |
| `settings/global` | App settings (thresholds, currency) |

---

## Business Rules

| Rule | Value |
|---|---|
| Free delivery threshold | Rs 300 |
| Default delivery fee | Rs 100 |
| Engraving fee | Rs 100 per item |
| Max engraving characters | 10 |
| Low-stock alert threshold | Configurable (default 5 units) |
| Banner image formats | PNG, JPEG only |
| Max banner file size | 5 MB |

---

## Features

### Mobile App
- Browse products with filters (category, gender, color, size, price, on-sale)
- Product detail with size/color picker, engraving option with live preview
- Persistent cart with coupon codes, order notes
- Checkout with saved address, delivery type, payment type selection
- Order history with PDF receipt download
- Real-time push + in-app notifications
- Wishlist
- Customer support chat (ticket system)
- Terms, Privacy Policy, About content from CMS

### Admin Dashboard
- Dashboard with sales stats and charts
- Product CRUD with images, custom fields, engraving settings
- Category management with configurable custom fields per category
- Order management with status workflow
- Stock monitoring with inline quantity updates
- Coupon management (percentage & fixed)
- Banner management with ordering
- Payment & delivery type configuration
- Broadcast push notifications to all users
- User management (activate/deactivate)
- Support ticket management with real-time chat
- CMS for Terms, Privacy, Data Privacy, About pages
