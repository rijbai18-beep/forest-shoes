const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Email transporter (lazy — only built when first needed) ──────────────────
let _transporter = null;
function getTransporter() {
  if (_transporter) return _transporter;
  const cfg = functions.config().email ?? {};
  _transporter = nodemailer.createTransport({
    service: "gmail",
    auth: { user: cfg.user, pass: cfg.pass },
  });
  return _transporter;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
async function getSettings() {
  const snap = await db.collection("settings").doc("global").get();
  return snap.exists ? snap.data() : {};
}

async function sendPushToUser(userId, title, body, data = {}) {
  const userSnap = await db.collection("users").doc(userId).get();
  if (!userSnap.exists) return;
  const tokens = userSnap.data().fcmTokens || [];
  if (!tokens.length) return;
  await messaging.sendEachForMulticast({ notification: { title, body }, data, tokens });
}

async function sendPushToAll(title, body, data = {}) {
  const usersSnap = await db.collection("users").where("isActive", "==", true).get();
  const allTokens = [];
  usersSnap.forEach((doc) => allTokens.push(...(doc.data().fcmTokens || [])));
  if (!allTokens.length) return;
  for (let i = 0; i < allTokens.length; i += 500) {
    await messaging.sendEachForMulticast({
      notification: { title, body }, data,
      tokens: allTokens.slice(i, i + 500),
    });
  }
}

function formatMRU(amount) {
  return `Rs ${Number(amount).toFixed(2)}`;
}

function buildReceiptHtml(order, user) {
  const itemRows = order.items.map((item) => `
    <tr>
      <td style="padding:8px;border-bottom:1px solid #eee">${item.name}${item.engravingText ? ` <em>(Engraving: "${item.engravingText}")</em>` : ""}</td>
      <td style="padding:8px;border-bottom:1px solid #eee;text-align:center">${item.quantity}</td>
      <td style="padding:8px;border-bottom:1px solid #eee;text-align:right">${formatMRU(item.price)}</td>
    </tr>`).join("");

  return `<!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"><title>Order Receipt #${order.id}</title></head>
  <body style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;color:#333">
    <div style="text-align:center;margin-bottom:30px">
      <h1 style="color:#2E7D32;margin:0">Forest Shoes</h1>
      <p style="color:#666;margin:5px 0">Order Receipt</p>
    </div>
    <div style="background:#f9f9f9;padding:15px;border-radius:8px;margin-bottom:20px">
      <p><strong>Order ID:</strong> #${order.id}</p>
      <p><strong>Date:</strong> ${new Date(order.createdAt._seconds * 1000).toLocaleDateString("en-MU")}</p>
      <p><strong>Status:</strong> ${order.status}</p>
      <p><strong>Customer:</strong> ${user.name}</p>
      <p><strong>Email:</strong> ${user.email}</p>
    </div>
    <table style="width:100%;border-collapse:collapse;margin-bottom:20px">
      <thead>
        <tr style="background:#2E7D32;color:#fff">
          <th style="padding:10px;text-align:left">Product</th>
          <th style="padding:10px;text-align:center">Qty</th>
          <th style="padding:10px;text-align:right">Price</th>
        </tr>
      </thead>
      <tbody>${itemRows}</tbody>
    </table>
    <div style="text-align:right;border-top:2px solid #2E7D32;padding-top:15px">
      <p>Subtotal: <strong>${formatMRU(order.subtotal)}</strong></p>
      ${order.couponDiscount > 0 ? `<p style="color:#e53e3e">Discount: <strong>-${formatMRU(order.couponDiscount)}</strong></p>` : ""}
      ${order.engravingFee > 0 ? `<p>Engraving: <strong>${formatMRU(order.engravingFee)}</strong></p>` : ""}
      <p>Delivery: <strong>${formatMRU(order.deliveryFee)}</strong></p>
      <h3 style="color:#2E7D32">Total: ${formatMRU(order.total)}</h3>
    </div>
    <div style="margin-top:20px;padding:15px;background:#f0f9f0;border-radius:8px">
      <p><strong>Payment Method:</strong> ${order.paymentType}</p>
      <p><strong>Delivery Address:</strong><br>${order.address.line1}<br>${order.address.city}, ${order.address.postcode}</p>
    </div>
    <p style="text-align:center;color:#999;font-size:12px;margin-top:30px">
      Thank you for shopping with Forest Shoes!<br>
      For support, contact us at support@forestshoes.mu
    </p>
  </body>
  </html>`;
}

// ─── Order created: send receipt email + push notification ────────────────────
exports.onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = { id: context.params.orderId, ...snap.data() };
    const userSnap = await db.collection("users").doc(order.userId).get();
    if (!userSnap.exists) return;
    const user = userSnap.data();

    try {
      const cfg = functions.config().email ?? {};
      await getTransporter().sendMail({
        from: `"Forest Shoes" <${cfg.user}>`,
        to: user.email,
        subject: `Your Forest Shoes Order #${order.id} Confirmed`,
        html: buildReceiptHtml(order, user),
      });
    } catch (err) {
      functions.logger.warn("Email send failed (email config may not be set):", err.message);
    }

    await db.collection("notifications").add({
      userId: order.userId,
      title: "Order Confirmed! 🎉",
      body: `Your order #${order.id} has been placed successfully.`,
      type: "order",
      data: { orderId: order.id },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await sendPushToUser(
      order.userId,
      "Order Confirmed! 🎉",
      `Your order #${order.id} has been placed. We'll notify you when it's dispatched.`,
      { type: "order", orderId: order.id }
    );
  });

// ─── Order status changed: notify customer ────────────────────────────────────
exports.onOrderStatusChanged = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === after.status) return;

    const orderId = context.params.orderId;
    const statusMessages = {
      reviewed: "Your payment has been reviewed.",
      processing: "Your order is being prepared.",
      dispatched: "Your order is on its way! 🚚",
      delivered: "Your order has been delivered. Enjoy your shoes! 👟",
      cancelled: "Your order has been cancelled.",
    };
    const message = statusMessages[after.status] || `Order status updated to: ${after.status}`;

    await db.collection("notifications").add({
      userId: after.userId,
      title: `Order Update #${orderId}`,
      body: message,
      type: "order_update",
      data: { orderId },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await sendPushToUser(after.userId, `Order Update #${orderId}`, message, {
      type: "order_update", orderId,
    });
  });

// ─── Broadcast notification to all users ─────────────────────────────────────
exports.broadcastNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError("permission-denied", "Only admins can broadcast.");
  }
  const { title, body, imageUrl } = data;
  if (!title || !body) {
    throw new functions.https.HttpsError("invalid-argument", "title and body are required.");
  }

  const usersSnap = await db.collection("users").where("isActive", "==", true).get();
  const batch = db.batch();
  usersSnap.forEach((doc) => {
    batch.set(db.collection("notifications").doc(), {
      userId: doc.id, title, body,
      imageUrl: imageUrl || null,
      type: "broadcast",
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
  await sendPushToAll(title, body, { type: "broadcast" });
  return { success: true };
});

// ─── Stock alert on product write ─────────────────────────────────────────────
exports.onProductStockChange = functions.firestore
  .document("products/{productId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return;
    const product = change.after.data();
    const settings = await getSettings();
    const threshold = settings.stockAlertThreshold || 5;

    if (product.stock <= threshold && product.isActive) {
      const existing = await db
        .collection("stockAlerts")
        .where("productId", "==", context.params.productId)
        .where("resolved", "==", false)
        .get();

      if (existing.empty) {
        await db.collection("stockAlerts").add({
          productId: context.params.productId,
          productName: product.name,
          stock: product.stock,
          threshold,
          resolved: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const adminsSnap = await db.collection("users").where("isAdmin", "==", true).get();
        for (const adminDoc of adminsSnap.docs) {
          await sendPushToUser(
            adminDoc.id,
            "⚠️ Low Stock Alert",
            `"${product.name}" has only ${product.stock} units left.`,
            { type: "stock_alert", productId: context.params.productId }
          );
        }
      }
    }
  });

// ─── Validate coupon ──────────────────────────────────────────────────────────
exports.validateCoupon = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
  }
  const { code, subtotal } = data;
  const now = admin.firestore.Timestamp.now();

  const couponSnap = await db
    .collection("coupons")
    .where("code", "==", code.toUpperCase())
    .where("isActive", "==", true)
    .get();

  if (couponSnap.empty) {
    throw new functions.https.HttpsError("not-found", "Invalid coupon code.");
  }

  const coupon = couponSnap.docs[0].data();
  const couponId = couponSnap.docs[0].id;

  if (coupon.expiresAt && coupon.expiresAt.toMillis() < now.toMillis()) {
    throw new functions.https.HttpsError("failed-precondition", "Coupon has expired.");
  }
  if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
    throw new functions.https.HttpsError("failed-precondition", "Coupon usage limit reached.");
  }
  if (coupon.minOrder && subtotal < coupon.minOrder) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Minimum order of ${formatMRU(coupon.minOrder)} required.`
    );
  }

  let discount = 0;
  if (coupon.type === "percentage") {
    discount = (subtotal * coupon.value) / 100;
    if (coupon.maxDiscount) discount = Math.min(discount, coupon.maxDiscount);
  } else {
    discount = coupon.value;
  }

  return { couponId, discount, type: coupon.type, value: coupon.value };
});

// ─── Increment coupon usedCount on order creation ─────────────────────────────
exports.onCouponUsed = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap) => {
    const order = snap.data();
    if (!order.couponId) return;
    await db.collection("coupons").doc(order.couponId).update({
      usedCount: admin.firestore.FieldValue.increment(1),
    });
  });

// ─── Set admin custom claim ───────────────────────────────────────────────────
exports.setAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError("permission-denied", "Only admins can set roles.");
  }
  const { uid, isAdmin } = data;
  await admin.auth().setCustomUserClaims(uid, { admin: isAdmin });
  await db.collection("users").doc(uid).update({ isAdmin });
  return { success: true };
});

// ─── Scheduled FCM token cleanup (daily) ─────────────────────────────────────
exports.cleanupFcmTokens = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    functions.logger.info("FCM token cleanup run.");
  });
