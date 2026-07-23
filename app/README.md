# Suraksha — Women's Safety App

Cross-platform (Android + iOS) safety app built with **Flutter**. Core features:
**shake-to-alert SOS**, **live location sharing**, and **trusted-contact alerts**.

> This directory contains the app source and platform config through **Phase 0
> and most of Phase 1** of the [master plan](../MASTER_PLAN.md). It is designed
> to be built with the Flutter SDK (not yet installed in this environment).

## What's implemented so far

| Area | File | Status |
|------|------|--------|
| Shake detection (tunable, false-positive resistant) | `lib/features/sos/shake_detector.dart` | ✅ core logic |
| SOS orchestration (countdown, silent mode, SMS fallback, live share) | `lib/features/sos/sos_service.dart` | ✅ core logic |
| Location service (one-shot fix + live stream) | `lib/core/services/location_service.dart` | ✅ |
| SOS button + home UI (idle / countdown / active) | `lib/features/home/`, `lib/features/sos/sos_button.dart` | ✅ |
| Data models (user, contact, SOS event) | `lib/core/models/` | ✅ |
| Theme / design system | `lib/core/theme/app_theme.dart` | ✅ |
| **Phone-OTP auth + profile** | `lib/core/services/auth_service.dart`, `lib/features/auth/` | ✅ Phase 1 |
| **Auth gate (login ↔ app routing)** | `lib/features/auth/auth_gate.dart` | ✅ Phase 1 |
| **Contacts repository (Firestore CRUD + reorder)** | `lib/core/repositories/contacts_repository.dart` | ✅ Phase 1 |
| **Contacts UI (phonebook pick, manual add, priority reorder)** | `lib/features/contacts/contacts_screen.dart` | ✅ Phase 1 |
| **Firestore alert gateway** (writes event → triggers fan-out) | `lib/core/services/firestore_alert_gateway.dart` | ✅ Phase 1 |
| **Cloud Function: FCM push + Twilio SMS fan-out** | `functions/index.js` | ✅ Phase 1 |
| **Guardian web live-track page** (no login, Leaflet map, realtime) | `web_track/index.html` | ✅ Phase 1 |
| **Guardian push handling** (tap SOS → open live map) | `lib/core/services/push_service.dart` | ✅ Phase 1 |
| **Firestore security rules** | `firestore.rules` | ✅ Phase 1 |
| Android permissions + foreground service | `android/app/src/main/AndroidManifest.xml` | ✅ |
| iOS permissions + background modes | `ios/Runner/Info.plist` | ✅ |
| Dev gateway (console, backendless demo) | `lib/core/services/console_alert_gateway.dart` | ✅ fallback |

## Not yet done (next steps)

- **Phase 1 is complete.** Remaining work begins at Phase 2.
- **Background foreground-service integration** (Phase 2): move the shake
  listener + location stream into `flutter_background_service` so they run with
  the screen locked.
- **Guardian live map** view (Phase 2).
- **Escalation ladder + media capture** (Phase 4) — `escalateUnacknowledged`
  is stubbed in `functions/index.js`.
- iOS shake-when-killed workarounds: Action Button / Back Tap / Siri Shortcut.

## Backend setup (Firebase)

```bash
# One-time, from app/
npm i -g firebase-tools
firebase login
flutterfire configure          # generates lib/firebase_options.dart + platform config
cd functions && npm install && cd ..

# Twilio (SMS fallback) config
firebase functions:config:set \
  twilio.sid=ACxxxx twilio.token=xxxx twilio.from="+1..." \
  app.trackbase="https://track.yourdomain.app"

firebase deploy --only functions,firestore:rules,hosting
```

Then set `app.trackbase` to your Hosting URL and paste your **web** Firebase
config into `web_track/index.html` (the `firebaseConfig` placeholders) so the
guardian track page can read live location. The link format is
`https://<trackbase>/e/<eventId>`.

Without this config the app runs in **dev mode** (console gateway) so the
SOS / shake / live-share UI still works on a device with no backend.

## Build & run (requires Flutter SDK ≥ 3.19)

```bash
# 1. Install Flutter: https://docs.flutter.dev/get-started/install
# 2. From this app/ directory, generate the full platform shells:
flutter create .            # fills in android/ + ios/ Gradle/Xcode scaffolding
                            # (keep the AndroidManifest.xml and Info.plist here)
flutter pub get

# 3. Run on a connected device / emulator
flutter run

# 4. Tests
flutter test
```

> After `flutter create .`, re-apply the permission blocks from the committed
> `AndroidManifest.xml` and `Info.plist` if the generator overwrites them.

## Architecture

Trigger logic (shake / button / hardware) is decoupled from delivery via the
`AlertGateway` interface, so the transport (Firebase, custom API, pure SMS) can
be swapped without touching the SOS flow. State is exposed through
`SosController` (a `ChangeNotifier`) consumed by the UI with `provider`.

See [`../MASTER_PLAN.md`](../MASTER_PLAN.md) for the full phased roadmap.
