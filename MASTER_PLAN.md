# Women's Safety App — Master Implementation Plan

**Product codename:** Suraksha (working title)
**Platforms:** Android & iOS (single cross-platform codebase)
**Core features:** Live location sharing • Shake-to-alert SOS • Trusted contacts • Emergency escalation

---

## 1. Product Overview

A personal safety app that lets a user instantly alert trusted contacts and share their live location in an emergency. Two primary trigger paths:

1. **Shake-to-Alert** — physically shaking the phone (works with screen locked, hands shaking, no need to open the app) fires an SOS.
2. **Live Location Share** — one-tap or automatic real-time location broadcast to selected guardians for a chosen duration.

### Design principles
- **Speed over polish in a crisis** — SOS must fire in under 2 seconds from a locked phone.
- **Works when it matters** — degrade gracefully on poor network (SMS fallback), low battery, and background/killed states.
- **Privacy by default** — location shared only during active sessions, encrypted in transit and at rest, user owns their data.
- **Discreet** — silent/stealth SOS mode, no loud confirmation that could escalate danger.

---

## 2. Recommended Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| Mobile framework | **Flutter** (Dart) | Single codebase, near-native sensor/location performance, strong background-execution plugins. (React Native is an acceptable alternative.) |
| Backend | **Node.js + TypeScript** (NestJS) or **Firebase** | Firebase accelerates Phase 1 (Auth, Firestore, FCM, Functions); a custom backend gives control at scale. Start Firebase, keep an abstraction layer. |
| Realtime location | Firebase Realtime DB / Firestore listeners, or WebSocket (Socket.IO) | Low-latency live location fan-out to guardians. |
| Push notifications | **FCM** (Android + iOS via APNs bridge) | Single API for both platforms. |
| SMS / voice fallback | **Twilio** (or MSG91 / local gateway for India) | Alerts when guardians don't have the app or have no data. |
| Maps | **Google Maps SDK** (Android/iOS) + **MapKit** optional on iOS | Live map, geocoding, place names in alerts. |
| Auth | Firebase Auth / OTP phone auth | Phone-number identity fits emergency contacts model. |
| Local storage | SQLite (Drift) / Hive | Offline queue for alerts, cached contacts. |
| Analytics & crash | Firebase Crashlytics + Analytics | Reliability is safety-critical here. |

---

## 3. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     MOBILE APP (Flutter)                       │
│                                                                │
│  Sensors        UI Layer         Background Services           │
│  ┌────────┐   ┌──────────┐   ┌──────────────────────────┐     │
│  │Accel-  │   │SOS button│   │Foreground service (Android)│    │
│  │erometer│──▶│Live map  │   │BGTaskScheduler (iOS)      │    │
│  │(shake) │   │Contacts  │   │Location stream + geofence │    │
│  └────────┘   └──────────┘   └──────────────────────────┘     │
│        │            │                    │                     │
│        └────────────┴────────────────────┘                    │
│                     │  (encrypted API / realtime socket)       │
└─────────────────────┼──────────────────────────────────────────┘
                      ▼
┌──────────────────────────────────────────────────────────────┐
│                        BACKEND                                 │
│  Auth  •  User/Contacts store  •  Alert orchestration          │
│  Realtime location relay  •  FCM push  •  Twilio SMS/voice     │
│  Audit log  •  Admin/abuse controls                            │
└──────────────────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   Guardian app   SMS/Call     Web live-track link
   (push + map)   fallback     (no-app guardians)
```

---

## 4. Phased Roadmap

Each phase is shippable. Estimates assume a small team (2 mobile, 1 backend, 1 designer, 1 QA). Adjust to your capacity.

### Phase 0 — Foundation & Setup *(1–2 weeks)*
**Goal:** Everything needed before feature work.
- [ ] Finalize requirements, user personas, and success metrics.
- [ ] Set up repo, branching strategy, CI/CD (GitHub Actions → TestFlight / Play Internal track).
- [ ] Flutter project scaffold with Android + iOS targets; module/folder structure.
- [ ] Choose & provision backend (Firebase project or NestJS + Postgres).
- [ ] Design system: colors, typography, the emergency-red SOS component, accessibility baseline.
- [ ] Legal groundwork: privacy policy, data-handling doc, consent copy (critical for location + emergency data).
- [ ] Provisioning: Apple Developer account, Play Console, signing keys, APNs/FCM certs.

**Exit criteria:** CI builds a signed app to both stores' test tracks; empty app launches on real devices.

---

### Phase 1 — Core MVP: Auth, Contacts, Manual SOS *(3–4 weeks)*
**Goal:** A user can register, add trusted contacts, and send a manual SOS with their current location.
- [ ] Phone-number OTP auth + profile (name, emergency medical note optional).
- [ ] Trusted contacts: add from phonebook, invite via SMS link, set priority order.
- [ ] Permissions onboarding flow (location, notifications, contacts) with clear rationale screens.
- [ ] One-tap SOS button → captures GPS fix → sends alert to all contacts via push + SMS.
- [ ] Alert payload: name, timestamp, map link (web track URL), "I need help" message, battery %.
- [ ] Guardian receives push (if app installed) and/or SMS with a live map link.
- [ ] Basic web live-track page for guardians without the app.
- [ ] Offline alert queue (retry when connectivity returns).

**Exit criteria:** End-to-end SOS delivered to a contact on both Android and iOS with location link.

---

### Phase 2 — Live Location Sharing *(3–4 weeks)*
**Goal:** Continuous, real-time location broadcast for a chosen window.
- [ ] Start/stop live share with duration picker (15 min, 1 hr, until I stop).
- [ ] Background location tracking:
  - Android: **Foreground Service** with persistent notification.
  - iOS: background location mode + `Always` permission handling + significant-change fallback.
- [ ] Realtime relay to guardians (map updates every N seconds, adaptive to speed/battery).
- [ ] Guardian live map view: moving marker, ETA, last-updated, battery of tracked user.
- [ ] "Reached safely" check-in / auto-stop on arriving at a saved place.
- [ ] Battery-aware update throttling and network-loss handling.

**Exit criteria:** A guardian watches the user's marker move in real time across app-background and screen-lock on both platforms.

---

### Phase 3 — Shake-to-Alert *(2–3 weeks)*
**Goal:** Trigger SOS by shaking the phone, even when locked.
- [ ] Accelerometer-based shake detection with tunable sensitivity (calibration screen).
- [ ] Debounce + confirmation window (e.g., 3-second cancel countdown to prevent false alarms) with a "silent/stealth" option that skips the countdown.
- [ ] Background detection:
  - Android: sensor listening inside the Foreground Service.
  - iOS: document limitations honestly — reliable only while app is foreground/recently backgrounded; pair with lock-screen widget / Action Button (iOS 18+) / hardware-button alternatives.
- [ ] Fake-shutdown / power-button-press trigger as an alternative (Android).
- [ ] False-positive tuning and user testing.
- [ ] Auto-trigger cascade: shake → SOS (Phase 1) + auto-start live share (Phase 2).

**Exit criteria:** Shaking a locked Android phone fires SOS reliably; iOS fires within its documented constraints; false-positive rate acceptably low in field testing.

---

### Phase 4 — Escalation, Media & Resilience *(3–4 weeks)*
**Goal:** Make alerts richer and more actionable in real danger.
- [ ] Auto audio recording (and optional short video/photo) on SOS, uploaded to secure storage; link shared with guardians.
- [ ] Escalation ladder: if no guardian acknowledges in X minutes, notify next tier / suggest calling local emergency number.
- [ ] Loud siren / flashlight strobe mode (opt-in; opposite of stealth mode).
- [ ] Guardian acknowledgment ("I'm on my way" / "Calling police") visible to the user and other guardians.
- [ ] Integration with local emergency services where APIs exist (e.g., India 112 / regional helplines) — research per launch region.
- [ ] Safe-route suggestions and unsafe-area heatmaps (optional, data-permitting).

**Exit criteria:** Unacknowledged SOS escalates automatically; media evidence attached and retrievable.

---

### Phase 5 — Hardening, Compliance & Launch *(3–4 weeks)*
**Goal:** Production-ready, store-approved, trustworthy.
- [ ] Security: end-to-end encryption for location/media, secure key handling, pen-test.
- [ ] Privacy compliance: GDPR / India DPDP Act / CCPA as applicable; data-retention & deletion controls.
- [ ] Abuse prevention: rate limiting, block/report, prevent stalking misuse (location sharing is mutual/consented).
- [ ] Battery, reliability, and stress testing across device matrix (low-end Android, older iPhones).
- [ ] Accessibility audit (screen readers, large text, one-handed use, panic-friendly UI).
- [ ] App Store & Play Store review prep — background-location and emergency features get extra scrutiny; prepare justification docs and demo video.
- [ ] Localization for target markets.
- [ ] Beta program → staged rollout → GA.

**Exit criteria:** Approved on both stores; monitored production launch with on-call for safety-critical failures.

---

### Phase 6 — Post-Launch Enhancements *(ongoing)*
- Wearable support (Apple Watch / Wear OS one-press SOS).
- Community features (verified safe zones, women-only community reports).
- Voice-activated trigger ("Hey [app], help").
- Widget & quick-tile shortcuts, Siri Shortcuts / Google Assistant.
- Journey monitoring with automated check-ins.
- Guardian dashboard web app.

---

## 5. Platform-Specific Considerations

### Android
- **Background execution:** Foreground Service (type `location`) with persistent notification — required by modern Android. Handle Doze mode, battery optimization exemption requests, `FOREGROUND_SERVICE_LOCATION` permission (Android 14+).
- **Shake while locked:** achievable via the foreground service holding a sensor listener.
- **Permissions:** `ACCESS_BACKGROUND_LOCATION` requires a separate flow and Play Console declaration.
- **OEM quirks:** aggressive battery killers (Xiaomi, Oppo, Samsung) — guide users to whitelist the app.

### iOS
- **Background limits are stricter.** True "shake while app fully killed" is **not reliably possible** — set expectations. Mitigations: `Always` location permission keeps the app alive for location; use the **Action Button / Back Tap / Lock Screen widget / Control Center control (iOS 18+)** and **Siri Shortcut** as reliable one-gesture triggers.
- **Background modes:** `location` + `Background processing`; handle `Always` vs `When In Use` upgrade prompt carefully.
- **APNs** for push; critical alerts entitlement (requires Apple approval) can bypass silent mode for SOS.
- **App Review:** emergency + background location apps face manual review — provide a clear demo account and justification.

---

## 6. Data Model (starting point)

```
User        { id, phone, name, medicalNote?, createdAt }
Contact     { id, ownerId, contactUserId?, phone, name, priority, status }
SosEvent    { id, userId, triggerType(manual|shake|button), startedAt,
              endedAt?, status(active|resolved|cancelled), lat, lng, batteryPct }
LiveSession { id, userId, startedAt, expiresAt, active, watchers[] }
Location    { sessionId, lat, lng, accuracy, speed, ts }   // time-series
Ack         { sosEventId, guardianId, response, ts }
Media       { sosEventId, type(audio|photo|video), url, ts }
```

---

## 7. Key Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| iOS can't shake-trigger when killed | Set expectations; offer Action Button / widget / Siri triggers; keep app alive via Always location. |
| False SOS alarms erode trust | Cancel countdown, sensitivity calibration, stealth override for real danger. |
| Alert fails on no network | SMS fallback + offline queue + retry. |
| Battery drain from tracking | Adaptive update intervals, motion-based throttling, clear battery UX. |
| Store rejection (background location) | Early prototype submission, justification docs, demo video, minimal scopes. |
| Misuse for stalking | Consent-based, mutual visibility, notifications when someone tracks you. |
| Safety-critical bugs | High test coverage, staged rollout, on-call, crash monitoring. |

---

## 8. Success Metrics
- SOS trigger-to-delivery latency (target < 5s p95).
- Alert delivery success rate (target > 99%).
- False-positive shake rate (target < 1 per user per week).
- Guardian acknowledgment rate and time.
- Crash-free sessions (target > 99.5%).
- Background-tracking reliability across device matrix.

---

## 9. Suggested Team & Timeline Summary

| Phase | Focus | Est. Duration |
|-------|-------|---------------|
| 0 | Foundation | 1–2 wks |
| 1 | Auth + Contacts + Manual SOS | 3–4 wks |
| 2 | Live location sharing | 3–4 wks |
| 3 | Shake-to-alert | 2–3 wks |
| 4 | Escalation + media | 3–4 wks |
| 5 | Hardening + launch | 3–4 wks |
| 6 | Enhancements | Ongoing |

**MVP (Phases 0–3): ~9–13 weeks.** Full v1 (through Phase 5): ~15–21 weeks.

---

*This is a living document. Refine scope and estimates against your team size, target launch regions, and regulatory environment.*
