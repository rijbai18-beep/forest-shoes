const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const PDFDocument = require("pdfkit");
const https = require("https");
const http = require("http");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Email transporter (built from Firestore settings each call) ──────────────
function getTransporter(settings) {
  return nodemailer.createTransport({
    service: "gmail",
    auth: { user: settings.emailUser, pass: settings.emailPass },
  });
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

function fetchBuffer(url) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith("https") ? https : http;
    mod.get(url, (res) => {
      if (res.statusCode !== 200) { reject(new Error(`HTTP ${res.statusCode}`)); return; }
      const chunks = [];
      res.on("data", (c) => chunks.push(c));
      res.on("end", () => resolve(Buffer.concat(chunks)));
      res.on("error", reject);
    }).on("error", reject);
  });
}

function buildReceiptHtml(order, user, settings) {
  const logoUrl = settings.logoUrl || null;
  const orderDate = order.createdAt
    ? new Date(order.createdAt._seconds * 1000).toLocaleDateString("en-MU", { day: "2-digit", month: "long", year: "numeric" })
    : "—";

  const itemRows = (order.items || []).map((item) => `
    <tr>
      <td style="padding:10px 12px;border-bottom:1px solid #f0f0f0">
        ${item.name}
        ${item.size ? `<span style="color:#999;font-size:11px"> · Size ${item.size}</span>` : ""}
        ${item.color ? `<span style="color:#999;font-size:11px"> · ${item.color}</span>` : ""}
        ${item.engravingText ? `<div style="font-size:11px;color:#888;margin-top:2px">Engraving: "${item.engravingText}"</div>` : ""}
      </td>
      <td style="padding:10px 12px;border-bottom:1px solid #f0f0f0;text-align:center;white-space:nowrap">${item.quantity}</td>
      <td style="padding:10px 12px;border-bottom:1px solid #f0f0f0;text-align:right;white-space:nowrap">${formatMRU((item.price || 0) * (item.quantity || 1))}</td>
    </tr>`).join("");

  const bankRows = settings.bankName ? `
    <table style="width:100%;font-size:13px;border-collapse:collapse">
      ${settings.bankName ? `<tr><td style="padding:4px 0;color:#666;width:140px">Bank</td><td style="padding:4px 0;font-weight:600">${settings.bankName}</td></tr>` : ""}
      ${settings.bankAccountName ? `<tr><td style="padding:4px 0;color:#666">Account Name</td><td style="padding:4px 0;font-weight:600">${settings.bankAccountName}</td></tr>` : ""}
      ${settings.bankAccountNumber ? `<tr><td style="padding:4px 0;color:#666">Account No.</td><td style="padding:4px 0;font-weight:600">${settings.bankAccountNumber}</td></tr>` : ""}
      ${settings.bankBranchCode ? `<tr><td style="padding:4px 0;color:#666">Branch Code</td><td style="padding:4px 0;font-weight:600">${settings.bankBranchCode}</td></tr>` : ""}
      ${settings.bankSwift ? `<tr><td style="padding:4px 0;color:#666">SWIFT / BIC</td><td style="padding:4px 0;font-weight:600">${settings.bankSwift}</td></tr>` : ""}
    </table>` : "<p style=\"color:#666;font-size:13px\">Please contact us for payment details.</p>";

  return `<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Order Receipt #${order.id}</title></head>
<body style="margin:0;padding:0;background:#f4f4f4;font-family:Arial,Helvetica,sans-serif">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f4;padding:30px 0">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08)">

  <!-- Header -->
  <tr><td style="background:#2E7D32;padding:28px 32px;text-align:center">
    ${logoUrl ? `<img src="${logoUrl}" alt="Forest Shoes" width="56" height="56" style="border-radius:12px;margin-bottom:12px;display:block;margin-left:auto;margin-right:auto">` : ""}
    <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:-0.3px">Forest Shoes</h1>
    <p style="margin:4px 0 0;color:rgba(255,255,255,0.75);font-size:13px">Order Confirmation</p>
  </td></tr>

  <!-- Order info -->
  <tr><td style="padding:24px 32px 0">
    <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8faf8;border-radius:8px;padding:16px">
      <tr>
        <td style="font-size:13px;color:#555"><strong style="color:#111">Order ID:</strong> #${order.id}</td>
        <td style="font-size:13px;color:#555;text-align:right"><strong style="color:#111">Date:</strong> ${orderDate}</td>
      </tr>
      <tr>
        <td style="font-size:13px;color:#555;padding-top:6px"><strong style="color:#111">Customer:</strong> ${user.name || user.email}</td>
        <td style="font-size:13px;color:#555;padding-top:6px;text-align:right"><strong style="color:#111">Status:</strong> ${order.status || "Confirmed"}</td>
      </tr>
    </table>
  </td></tr>

  <!-- Items table -->
  <tr><td style="padding:20px 32px 0">
    <h2 style="margin:0 0 12px;font-size:14px;font-weight:700;color:#111;text-transform:uppercase;letter-spacing:0.05em">Order Summary</h2>
    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse">
      <thead>
        <tr style="background:#2E7D32">
          <th style="padding:10px 12px;text-align:left;color:#fff;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.05em">Product</th>
          <th style="padding:10px 12px;text-align:center;color:#fff;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.05em">Qty</th>
          <th style="padding:10px 12px;text-align:right;color:#fff;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.05em">Total</th>
        </tr>
      </thead>
      <tbody>${itemRows}</tbody>
    </table>
    <!-- Totals -->
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:0;border-top:2px solid #2E7D32">
      <tr><td style="padding:8px 12px;font-size:13px;color:#555">Subtotal</td><td style="padding:8px 12px;text-align:right;font-size:13px">${formatMRU(order.subtotal || 0)}</td></tr>
      ${(order.couponDiscount || 0) > 0 ? `<tr><td style="padding:4px 12px;font-size:13px;color:#e53e3e">Discount</td><td style="padding:4px 12px;text-align:right;font-size:13px;color:#e53e3e">−${formatMRU(order.couponDiscount)}</td></tr>` : ""}
      ${(order.engravingFee || 0) > 0 ? `<tr><td style="padding:4px 12px;font-size:13px;color:#555">Engraving</td><td style="padding:4px 12px;text-align:right;font-size:13px">${formatMRU(order.engravingFee)}</td></tr>` : ""}
      <tr><td style="padding:4px 12px;font-size:13px;color:#555">Delivery</td><td style="padding:4px 12px;text-align:right;font-size:13px">${formatMRU(order.deliveryFee || 0)}</td></tr>
      <tr style="background:#f8faf8"><td style="padding:10px 12px;font-size:15px;font-weight:700;color:#2E7D32">Total</td><td style="padding:10px 12px;text-align:right;font-size:15px;font-weight:700;color:#2E7D32">${formatMRU(order.total || 0)}</td></tr>
    </table>
  </td></tr>

  <!-- Payment reference instruction -->
  <tr><td style="padding:20px 32px 0">
    <div style="background:#fffbeb;border:1.5px solid #f59e0b;border-radius:8px;padding:14px 16px">
      <p style="margin:0 0 4px;font-size:13px;font-weight:700;color:#92400e">⚠️ Payment Reference Required</p>
      <p style="margin:0;font-size:13px;color:#92400e;line-height:1.5">
        ${settings.bankPaymentNote || `Please use your Order ID <strong>#${order.id}</strong> as the reference / description when making your bank transfer.`}
        ${settings.bankPaymentNote ? "" : ""}
        <br><strong>Order ID: #${order.id}</strong>
      </p>
    </div>
  </td></tr>

  <!-- Bank transfer details -->
  <tr><td style="padding:20px 32px 0">
    <h2 style="margin:0 0 12px;font-size:14px;font-weight:700;color:#111;text-transform:uppercase;letter-spacing:0.05em">Bank Transfer Details</h2>
    <div style="background:#f8faf8;border-radius:8px;padding:16px">
      ${bankRows}
    </div>
  </td></tr>

  <!-- Delivery address -->
  <tr><td style="padding:20px 32px 0">
    <h2 style="margin:0 0 10px;font-size:14px;font-weight:700;color:#111;text-transform:uppercase;letter-spacing:0.05em">Delivery Address</h2>
    <p style="margin:0;font-size:13px;color:#555;line-height:1.7">
      ${order.address ? `${order.address.line1 || ""}${order.address.line2 ? "<br>" + order.address.line2 : ""}<br>${order.address.city || ""}${order.address.postcode ? ", " + order.address.postcode : ""}` : "—"}
    </p>
  </td></tr>

  <!-- Footer -->
  <tr><td style="padding:28px 32px;text-align:center;color:#aaa;font-size:12px;border-top:1px solid #f0f0f0;margin-top:24px">
    <p style="margin:0 0 4px">Thank you for shopping with <strong>Forest Shoes</strong>!</p>
    <p style="margin:0">Questions? Email <a href="mailto:support@forestshoes.mu" style="color:#2E7D32">support@forestshoes.mu</a></p>
  </td></tr>

</table>
</td></tr>
</table>
</body>
</html>`;
}

function buildReceiptPdf(order, user, settings, logoBuffer) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 50, size: "A4" });
    const chunks = [];
    doc.on("data", (c) => chunks.push(c));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    const GREEN = "#2E7D32";
    const AMBER = "#F59E0B";
    const GRAY  = "#555555";
    const LIGHT = "#F8FAF8";
    const pageW = doc.page.width - 100; // usable width at margin=50

    // ── Logo + header ────────────────────────────────────────────────────────
    if (logoBuffer) {
      try { doc.image(logoBuffer, 50, 40, { width: 48, height: 48 }); } catch (_) {}
    }
    doc.font("Helvetica-Bold").fontSize(20).fillColor(GREEN).text("Forest Shoes", logoBuffer ? 110 : 50, 50);
    doc.font("Helvetica").fontSize(10).fillColor(GRAY).text("Order Receipt", logoBuffer ? 110 : 50, 74);

    doc.moveTo(50, 108).lineTo(doc.page.width - 50, 108).strokeColor("#E5E7EB").stroke();
    doc.y = 120;

    // ── Order info block ─────────────────────────────────────────────────────
    const orderDate = order.createdAt
      ? new Date(order.createdAt._seconds * 1000).toLocaleDateString("en-MU", { day: "2-digit", month: "long", year: "numeric" })
      : "—";

    doc.rect(50, doc.y, pageW, 70).fill(LIGHT);
    const infoY = doc.y + 12;
    doc.font("Helvetica").fontSize(10).fillColor(GRAY);
    doc.text(`Order ID:`, 62, infoY); doc.font("Helvetica-Bold").fillColor("#111").text(`#${order.id}`, 130, infoY);
    doc.font("Helvetica").fillColor(GRAY).text(`Date:`, 62, infoY + 18); doc.font("Helvetica-Bold").fillColor("#111").text(orderDate, 130, infoY + 18);
    doc.font("Helvetica").fillColor(GRAY).text(`Customer:`, 62, infoY + 36); doc.font("Helvetica-Bold").fillColor("#111").text(user.name || user.email || "—", 130, infoY + 36);
    doc.font("Helvetica").fillColor(GRAY).text(`Status:`, 350, infoY); doc.font("Helvetica-Bold").fillColor(GREEN).text(order.status || "Confirmed", 400, infoY);
    doc.y += 82;

    // ── Items table header ───────────────────────────────────────────────────
    doc.moveDown(0.6);
    doc.font("Helvetica-Bold").fontSize(11).fillColor(GREEN).text("ORDER SUMMARY", 50, doc.y);
    doc.moveDown(0.4);
    const tableTop = doc.y;
    doc.rect(50, tableTop, pageW, 22).fill(GREEN);
    doc.font("Helvetica-Bold").fontSize(9).fillColor("#FFFFFF");
    doc.text("Product", 62, tableTop + 7);
    doc.text("Qty", 370, tableTop + 7, { width: 40, align: "center" });
    doc.text("Total", 430, tableTop + 7, { width: 60, align: "right" });
    doc.y = tableTop + 22;

    // ── Items rows ───────────────────────────────────────────────────────────
    (order.items || []).forEach((item, i) => {
      const rowH = item.engravingText ? 36 : 22;
      if (i % 2 === 1) doc.rect(50, doc.y, pageW, rowH).fill("#F9FAFB");
      const rowY = doc.y;
      doc.font("Helvetica").fontSize(9).fillColor("#111").text(
        `${item.name}${item.size ? ` · Size ${item.size}` : ""}${item.color ? ` · ${item.color}` : ""}`,
        62, rowY + 7, { width: 300 }
      );
      if (item.engravingText) {
        doc.font("Helvetica").fontSize(8).fillColor(GRAY).text(`Engraving: "${item.engravingText}"`, 62, rowY + 19, { width: 300 });
      }
      doc.font("Helvetica").fontSize(9).fillColor(GRAY)
        .text(String(item.quantity || 1), 370, rowY + 7, { width: 40, align: "center" });
      doc.font("Helvetica-Bold").fillColor("#111")
        .text(formatMRU((item.price || 0) * (item.quantity || 1)), 430, rowY + 7, { width: 60, align: "right" });
      doc.y = rowY + rowH;
    });

    // ── Totals ───────────────────────────────────────────────────────────────
    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor(GREEN).lineWidth(1.5).stroke();
    doc.lineWidth(1);
    const totY = doc.y + 6;
    const totals = [
      ["Subtotal", formatMRU(order.subtotal || 0)],
      ...(order.couponDiscount > 0 ? [["Discount", `−${formatMRU(order.couponDiscount)}`]] : []),
      ...(order.engravingFee > 0 ? [["Engraving", formatMRU(order.engravingFee)]] : []),
      ["Delivery", formatMRU(order.deliveryFee || 0)],
    ];
    let ty = totY;
    totals.forEach(([label, value]) => {
      doc.font("Helvetica").fontSize(9).fillColor(GRAY).text(label, 350, ty);
      doc.font("Helvetica").fillColor("#111").text(value, 430, ty, { width: 60, align: "right" });
      ty += 16;
    });
    // Total row
    doc.rect(350, ty, pageW - 300, 22).fill(GREEN);
    doc.font("Helvetica-Bold").fontSize(10).fillColor("#FFFFFF").text("Total", 360, ty + 6);
    doc.text(formatMRU(order.total || 0), 430, ty + 6, { width: 60, align: "right" });
    doc.y = ty + 32;

    // ── Payment reference box ─────────────────────────────────────────────────
    const refNote = settings.bankPaymentNote || `Please use your Order ID #${order.id} as the payment reference.`;
    const boxH = 54;
    doc.rect(50, doc.y, pageW, boxH).fill("#FFFBEB").stroke("#F59E0B");
    doc.font("Helvetica-Bold").fontSize(10).fillColor("#92400E")
      .text("Payment Reference Required", 62, doc.y + 10);
    doc.font("Helvetica").fontSize(9).fillColor("#92400E")
      .text(`${refNote}  Order ID: #${order.id}`, 62, doc.y + 24, { width: pageW - 24 });
    doc.y += boxH + 16;

    // ── Bank details ─────────────────────────────────────────────────────────
    doc.font("Helvetica-Bold").fontSize(11).fillColor(GREEN).text("BANK TRANSFER DETAILS", 50, doc.y);
    doc.moveDown(0.4);
    doc.rect(50, doc.y, pageW, 8 + (Object.entries({
      "Bank": settings.bankName, "Account Name": settings.bankAccountName,
      "Account Number": settings.bankAccountNumber, "Branch Code": settings.bankBranchCode,
      "SWIFT / BIC": settings.bankSwift,
    }).filter(([, v]) => v).length) * 18).fill(LIGHT);

    const bankItems = [
      ["Bank", settings.bankName],
      ["Account Name", settings.bankAccountName],
      ["Account Number", settings.bankAccountNumber],
      ["Branch Code", settings.bankBranchCode],
      ["SWIFT / BIC", settings.bankSwift],
    ].filter(([, v]) => v);

    let by = doc.y + 8;
    bankItems.forEach(([label, value]) => {
      doc.font("Helvetica").fontSize(9).fillColor(GRAY).text(label, 62, by, { width: 120 });
      doc.font("Helvetica-Bold").fillColor("#111").text(value, 190, by, { width: 300 });
      by += 18;
    });
    doc.y = by + 12;

    // ── Footer ────────────────────────────────────────────────────────────────
    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor("#E5E7EB").stroke();
    doc.moveDown(0.5);
    doc.font("Helvetica").fontSize(9).fillColor("#AAAAAA")
      .text("Thank you for shopping with Forest Shoes! · support@forestshoes.mu", { align: "center" });

    doc.end();
  });
}

// ─── Order created: send receipt email + push notification ────────────────────
exports.onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = { id: context.params.orderId, ...snap.data() };
    const userSnap = await db.collection("users").doc(order.userId).get();
    if (!userSnap.exists) return;
    const user = userSnap.data();
    const settings = await getSettings();

    if (!settings.emailUser || !settings.emailPass) {
      functions.logger.warn("Email not configured — set emailUser and emailPass in settings/global.");
    } else {
      try {
        let logoBuffer = null;
        if (settings.logoUrl) {
          try { logoBuffer = await fetchBuffer(settings.logoUrl); } catch (_) {}
        }

        const [htmlBody, pdfBuffer] = await Promise.all([
          Promise.resolve(buildReceiptHtml(order, user, settings)),
          buildReceiptPdf(order, user, settings, logoBuffer),
        ]);

        await getTransporter(settings).sendMail({
          from: `"Forest Shoes" <${settings.emailUser}>`,
          to: user.email,
          subject: `Your Forest Shoes Order #${order.id} is Confirmed`,
          html: htmlBody,
          attachments: [{
            filename: `receipt-${order.id}.pdf`,
            content: pdfBuffer,
            contentType: "application/pdf",
          }],
        });
        functions.logger.info(`Receipt email sent to ${user.email} for order ${order.id}`);
      } catch (err) {
        functions.logger.error("Email send failed:", err.message, err.stack);
      }
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

// ─── Create a new admin user account ─────────────────────────────────────────
exports.createAdminUser = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError("permission-denied", "Only admins can create admin accounts.");
  }
  const { email, password, name } = data;
  if (!email || !password || !name) {
    throw new functions.https.HttpsError("invalid-argument", "name, email, and password are required.");
  }
  if (password.length < 8) {
    throw new functions.https.HttpsError("invalid-argument", "Password must be at least 8 characters.");
  }

  const userRecord = await admin.auth().createUser({ email, password, displayName: name });
  await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
  await db.collection("users").doc(userRecord.uid).set({
    email,
    name,
    phone: null,
    photoUrl: null,
    addresses: [],
    isActive: true,
    isAdmin: true,
    fcmTokens: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { uid: userRecord.uid, success: true };
});

// ─── Scheduled FCM token cleanup (daily) ─────────────────────────────────────
exports.cleanupFcmTokens = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    functions.logger.info("FCM token cleanup run.");
  });
