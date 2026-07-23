/**
 * Cloud Functions for Suraksha — alert fan-out.
 *
 * When a new document lands in `sosEvents`, notify every recipient:
 *   • guardians with the app  → FCM push (rich, tappable, opens live map)
 *   • everyone else           → Twilio SMS with a web live-track link
 *
 * Deploy:  firebase deploy --only functions
 * Config:  firebase functions:config:set twilio.sid=... twilio.token=... \
 *            twilio.from="+1..." app.trackbase="https://track.suraksha.app"
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const cfg = functions.config();
const TRACK_BASE = (cfg.app && cfg.app.trackbase) || "https://track.suraksha.app";

// Lazily construct Twilio only if configured, so local emulation still runs.
function twilioClient() {
  if (!cfg.twilio || !cfg.twilio.sid) return null;
  // eslint-disable-next-line global-require
  return require("twilio")(cfg.twilio.sid, cfg.twilio.token);
}

exports.onSosCreated = functions.firestore
  .document("sosEvents/{eventId}")
  .onCreate(async (snap, context) => {
    const eventId = context.params.eventId;
    const event = snap.data();
    const recipients = event.recipients || [];

    const userDoc = await db.collection("users").doc(event.userId).get();
    const userName = userDoc.exists ? userDoc.data().name : "Someone";

    // Seed the public, link-scoped track document the guardian web page reads.
    // Only non-sensitive fields — never the recipient list or user id.
    await db.collection("publicTracks").doc(eventId).set({
      kind: "sos",
      userName,
      status: "active",
      lat: event.lat != null ? event.lat : null,
      lng: event.lng != null ? event.lng : null,
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const trackUrl = `${TRACK_BASE}/e/${eventId}`;
    const mapUrl =
      event.lat != null && event.lng != null
        ? `https://maps.google.com/?q=${event.lat},${event.lng}`
        : trackUrl;

    const smsBody =
      `🚨 ${userName} needs help and shared an SOS.\n` +
      `Live location: ${trackUrl}\n` +
      `Current: ${mapUrl}`;

    const twilio = twilioClient();
    const tasks = [];

    for (const r of recipients) {
      if (r.hasApp) {
        tasks.push(pushToGuardian(r.phone, userName, eventId, trackUrl));
      } else if (twilio && cfg.twilio.from) {
        tasks.push(
          twilio.messages
            .create({ to: r.phone, from: cfg.twilio.from, body: smsBody })
            .catch((e) => console.error(`SMS to ${r.phone} failed`, e))
        );
      }
    }

    await Promise.allSettled(tasks);
    console.log(`SOS ${eventId}: notified ${recipients.length} recipient(s)`);
  });

/** Look up a guardian's device token by phone and send an FCM push. */
async function pushToGuardian(phone, fromName, eventId, trackUrl) {
  const q = await db.collection("users").where("phone", "==", phone).limit(1).get();
  if (q.empty) return;
  const token = q.docs[0].data().fcmToken;
  if (!token) return;

  return admin.messaging().send({
    token,
    notification: {
      title: `🚨 ${fromName} needs help`,
      body: "Tap to see their live location.",
    },
    data: { type: "sos", eventId, trackUrl },
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default", "interruption-level": "critical" } } },
  });
}

/**
 * Escalation ladder: every minute, find active SOS events that are past their
 * per-event grace period with no acknowledgment, and notify the next-priority
 * contact who hasn't been escalated to yet. Marks progress on the event so each
 * tier is only paged once.
 */
exports.escalateUnacknowledged = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = Date.now();
    const active = await db
      .collection("sosEvents")
      .where("status", "==", "active")
      .get();

    for (const doc of active.docs) {
      const e = doc.data();
      const started = Date.parse(e.startedAt || "") || now;
      const graceMs = ((e.escalationMinutes || 3) * 60 + 60) * 1000;
      if (now - started < graceMs) continue;

      // Already acknowledged? Then no escalation needed.
      const acks = await doc.ref.collection("acks").limit(1).get();
      if (!acks.empty) continue;

      const recipients = (e.recipients || [])
        .slice()
        .sort((a, b) => (a.priority || 0) - (b.priority || 0));
      const tier = e.escalatedTier || 1; // tier 0 was paged on create
      const next = recipients[tier];
      if (!next) continue; // exhausted the ladder

      const userDoc = await db.collection("users").doc(e.userId).get();
      const userName = userDoc.exists ? userDoc.data().name : "Someone";
      const trackUrl = `${TRACK_BASE}/e/${doc.id}`;
      const body =
        `⚠️ Still no response to ${userName}'s SOS. Please help or call ` +
        `emergency services. Live location: ${trackUrl}`;

      const twilio = twilioClient();
      if (next.hasApp) {
        await pushToGuardian(next.phone, userName, doc.id, trackUrl);
      } else if (twilio && cfg.twilio && cfg.twilio.from) {
        await twilio.messages
          .create({ to: next.phone, from: cfg.twilio.from, body })
          .catch((err) => console.error("escalation SMS failed", err));
      }

      await doc.ref.set({ escalatedTier: tier + 1 }, { merge: true });
      console.log(`Escalated ${doc.id} to tier ${tier + 1} (${next.phone})`);
    }
    return null;
  });

/**
 * When a guardian acknowledges, notify the person in distress so they know help
 * is coming. Their own push token is on their user doc.
 */
exports.onAckCreated = functions.firestore
  .document("sosEvents/{eventId}/acks/{ackId}")
  .onCreate(async (snap, context) => {
    const ack = snap.data();
    const eventDoc = await db
      .collection("sosEvents")
      .doc(context.params.eventId)
      .get();
    if (!eventDoc.exists) return;

    const userDoc = await db.collection("users").doc(eventDoc.data().userId).get();
    const token = userDoc.exists ? userDoc.data().fcmToken : null;
    if (!token) return;

    return admin.messaging().send({
      token,
      notification: {
        title: "Help is coming",
        body: `${ack.guardianName}: ${ack.response}`,
      },
      android: { priority: "high" },
    });
  });
