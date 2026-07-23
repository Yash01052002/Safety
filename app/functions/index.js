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
 * Escalation: if an active event hasn't been acknowledged after a grace period,
 * this scheduled function can notify the next tier. (Phase 4 — stub.)
 */
exports.escalateUnacknowledged = functions.pubsub
  .schedule("every 2 minutes")
  .onRun(async () => {
    // TODO Phase 4: query active, unacknowledged events older than N minutes
    // and notify the next-priority contact / suggest emergency services.
    return null;
  });
