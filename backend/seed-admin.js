#!/usr/bin/env node
/**
 * One-time script to bootstrap the first Forest Shoes admin user.
 *
 * Usage:
 *   node seed-admin.js <email>
 *
 * Requirements:
 *   - Firebase CLI must be logged in (firebase login)
 *   - Run from the backend/ directory
 */

const https = require('https')
const fs = require('fs')
const path = require('path')
const os = require('os')

const PROJECT_ID = 'testproject1-489910'
const args = process.argv.slice(2)
const email = args.find((a) => !a.startsWith('--'))
const shouldCreate = args.includes('--create')

if (!email) {
  console.error('Usage: node seed-admin.js <email> [--create]')
  console.error('  --create   Create the Firebase Auth account if it does not exist yet')
  process.exit(1)
}

// ─── Load Firebase CLI credentials ───────────────────────────────────────────
const configPath = path.join(os.homedir(), '.config/configstore/firebase-tools.json')
let tokens
try {
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
  tokens = config.tokens
  if (!tokens?.refresh_token) throw new Error('No refresh token found')
} catch (err) {
  console.error('Could not read Firebase CLI credentials:', err.message)
  console.error('Make sure you are logged in: firebase login')
  process.exit(1)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function httpsRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = ''
      res.on('data', (chunk) => (data += chunk))
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) })
        } catch {
          resolve({ status: res.statusCode, body: data })
        }
      })
    })
    req.on('error', reject)
    if (body) req.write(typeof body === 'string' ? body : JSON.stringify(body))
    req.end()
  })
}

// ─── Refresh the OAuth access token ──────────────────────────────────────────
async function refreshAccessToken() {
  const payload = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: tokens.refresh_token,
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
  }).toString()

  const res = await httpsRequest(
    {
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': Buffer.byteLength(payload) },
    },
    payload
  )

  if (res.status !== 200) throw new Error(`Token refresh failed: ${JSON.stringify(res.body)}`)
  return res.body.access_token
}

// ─── Firebase Auth REST: look up user by email ───────────────────────────────
async function getUserByEmail(accessToken) {
  const body = JSON.stringify({ email, returnSecureToken: false })
  const res = await httpsRequest(
    {
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/accounts:lookup?access_token=${accessToken}`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    },
    body
  )
  if (res.status !== 200 || !res.body.users?.length) return null
  return res.body.users[0]
}

// ─── Firebase Auth REST: create user ─────────────────────────────────────────
async function createUser(accessToken, password) {
  const body = JSON.stringify({ email, password, returnSecureToken: false })
  const res = await httpsRequest(
    {
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/accounts`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        Authorization: `Bearer ${accessToken}`,
      },
    },
    body
  )
  if (res.status !== 200) throw new Error(`Create user failed: ${JSON.stringify(res.body)}`)
  return res.body
}

// ─── Identity Platform: set custom claims ────────────────────────────────────
async function setCustomClaims(accessToken, uid) {
  const body = JSON.stringify({ localId: uid, customAttributes: JSON.stringify({ admin: true }) })
  const res = await httpsRequest(
    {
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/accounts:update`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        Authorization: `Bearer ${accessToken}`,
      },
    },
    body
  )
  if (res.status !== 200) throw new Error(`setCustomClaims failed: ${JSON.stringify(res.body)}`)
}

// ─── Firestore REST: upsert users/{uid} ──────────────────────────────────────
async function upsertFirestoreUser(accessToken, uid, displayName) {
  const name = displayName || email.split('@')[0]
  const docPath = `projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`
  const body = JSON.stringify({
    fields: {
      email: { stringValue: email },
      name: { stringValue: name },
      isAdmin: { booleanValue: true },
      isActive: { booleanValue: true },
    },
  })

  const res = await httpsRequest(
    {
      hostname: 'firestore.googleapis.com',
      path: `/v1/${docPath}?updateMask.fieldPaths=email&updateMask.fieldPaths=name&updateMask.fieldPaths=isAdmin&updateMask.fieldPaths=isActive`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        Authorization: `Bearer ${accessToken}`,
      },
    },
    body
  )
  if (res.status !== 200) throw new Error(`Firestore update failed: ${JSON.stringify(res.body)}`)
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function run() {
  console.log('Refreshing Firebase CLI credentials …')
  const accessToken = await refreshAccessToken()

  console.log(`Looking up user: ${email} …`)
  let user = await getUserByEmail(accessToken)

  if (!user) {
    if (!shouldCreate) {
      throw new Error(
        `No Firebase Auth user found for "${email}".\n` +
        '  • Sign up in the app first and re-run, OR\n' +
        '  • Re-run with --create to create the account now (you will be prompted for a password)'
      )
    }
    const readline = require('readline')
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout })
    const password = await new Promise((resolve) => rl.question('Enter a password for this admin account: ', (a) => { rl.close(); resolve(a) }))
    if (password.length < 6) throw new Error('Password must be at least 6 characters.')
    console.log('Creating Firebase Auth account …')
    const created = await createUser(accessToken, password)
    user = { localId: created.localId, displayName: '' }
    console.log(`✔  Account created — UID: ${user.localId}`)
  }

  const { localId: uid, displayName } = user
  console.log(`Found user: ${displayName || '(no display name)'} — UID: ${uid}`)

  console.log('Setting custom claim admin=true …')
  await setCustomClaims(accessToken, uid)
  console.log('✔  Custom claim set')

  console.log('Updating Firestore users/' + uid + ' …')
  await upsertFirestoreUser(accessToken, uid, displayName)
  console.log('✔  Firestore document updated')

  console.log('\n✅  Done! Sign out and back in to the admin app so the new token takes effect.')
}

run().catch((err) => {
  console.error('\n❌  Error:', err.message)
  process.exit(1)
})
