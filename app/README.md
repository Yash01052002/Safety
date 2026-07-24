# Suraksha — Women's Safety App

Cross-platform (Android + iOS) safety app built with **Flutter**. Core features:
**shake-to-alert SOS**, **live location sharing**, and **trusted-contact alerts**.

> This directory contains the app source and platform config through **Phases
> 0–4 and the code deliverables of Phase 5** of the
> [master plan](../MASTER_PLAN.md). It is designed to be built with the Flutter
> SDK (not yet installed in this environment). Remaining Phase 5 work is
> process/testing/ops — tracked in [`../docs/LAUNCH_CHECKLIST.md`](../docs/LAUNCH_CHECKLIST.md).

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
| **Background foreground-service** (location + shake, screen locked) | `lib/core/services/background_service.dart` | ✅ Phase 2 |
| **Proactive live-share** (duration picker, auto-expiry, battery-aware) | `lib/features/live/`, `lib/core/repositories/live_share_repository.dart` | ✅ Phase 2 |
| **In-app guardian live map** (Google Maps) | `lib/features/live/guardian_map_screen.dart` | ✅ Phase 2 |
| **Shake sensitivity calibration** (live test meter, persisted) | `lib/features/settings/shake_settings_screen.dart` | ✅ Phase 3 |
| **SOS settings** (threshold, shakes, countdown, stealth) | `lib/core/models/sos_settings.dart`, `lib/core/services/settings_service.dart` | ✅ Phase 3 |
| **Trigger fallbacks** (Quick Action + `suraksha://sos` deep link) | `lib/core/services/quick_trigger_service.dart` | ✅ Phase 3 |
| **Media evidence** (audio/photo → Firebase Storage) | `lib/core/services/media_service.dart` | ✅ Phase 4 |
| **Siren + flashlight strobe** (opt-in) | `lib/core/services/alarm_service.dart` | ✅ Phase 4 |
| **Guardian acknowledgment** ("on my way" / "call police") | `lib/features/live/guardian_map_screen.dart`, `lib/core/models/ack.dart` | ✅ Phase 4 |
| **Escalation ladder** (unanswered SOS → next tier) | `functions/index.js` (`escalateUnacknowledged`) | ✅ Phase 4 |
| **Ack notification back to the user** | `functions/index.js` (`onAckCreated`) | ✅ Phase 4 |
| **Storage security rules** | `storage.rules` | ✅ Phase 4 |
| **Expiring track links** (leaked-URL hardening) | `firestore.rules`, gateways | ✅ Phase 5 |
| **Locale-aware emergency numbers** | `lib/core/services/emergency_numbers.dart` | ✅ Phase 5 |
| **Account & data deletion + retention** | `lib/core/services/account_service.dart`, `functions/index.js` | ✅ Phase 5 |
| **Privacy & data-controls screen** | `lib/features/privacy/privacy_screen.dart` | ✅ Phase 5 |
| **Localization scaffolding** (en + hi) | `l10n.yaml`, `lib/l10n/*.arb` | ✅ Phase 5 |
| **Accessibility on SOS button** | `lib/features/sos/sos_button.dart` | ✅ Phase 5 |
| **Journey monitoring** (ETA timer → auto-SOS if overdue) | `lib/features/journey/` | ✅ Phase 6 |
| **Android App Shortcut / Assistant** (long-press → Send SOS) | `android/.../res/xml/shortcuts.xml` | ✅ Phase 6 |
| **Community safety map** (pseudonymous area reports, radius query) | `lib/features/community/`, `lib/core/repositories/safety_report_repository.dart` | ✅ Phase 6 |
| **Home-screen / lock-screen SOS widget** (Android + iOS) | `android/.../SosWidgetProvider.kt`, `ios/SosWidget/SosWidget.swift` | ✅ Phase 6 (native) |
| **Android Quick Settings SOS tile** | `android/.../SosTileService.kt` | ✅ Phase 6 (native) |
| Android permissions + foreground service | `android/app/src/main/AndroidManifest.xml` | ✅ |
| iOS permissions + background modes | `ios/Runner/Info.plist` | ✅ |
| Dev gateway (console, backendless demo) | `lib/core/services/console_alert_gateway.dart` | ✅ fallback |

## Not yet done (next steps)

- **Phases 0–4 done; Phase 5 code done.** Remaining Phase 5 work is process/
  testing/ops — see [`../docs/LAUNCH_CHECKLIST.md`](../docs/LAUNCH_CHECKLIST.md).
- **End-to-end encryption** of location/media is still a design task (not built).
- **Firebase-in-isolate writes** (Phase 2 hardening): the background isolate
  forwards `position`/`shake` to the UI isolate, which stays alive under the
  foreground service. For writes while the app is *fully killed*, initialize
  Firebase inside `onStart` and write directly. Stub is in place.
- **Localization:** run `flutter run` once to generate `AppLocalizations`, then
  add `AppLocalizations.delegate` and migrate hardcoded strings to `.arb` keys.
- The **siren** needs a bundled `assets/siren.mp3` (see `assets/README.md`);
  Google Maps needs an API key (Android + iOS).
- **Phase 6 (remaining):** wearables (Apple Watch / Wear OS) and an
  always-listening voice trigger still need native modules — see
  [`../docs/NATIVE_MODULES.md`](../docs/NATIVE_MODULES.md). Journey monitoring,
  the community safety map, the home-screen/lock-screen SOS widgets (Android +
  iOS), and the Android Quick Settings tile are done.
- **Community map scaling:** the `nearby` query bounds by latitude and filters
  distance client-side (fine for a viewport radius). Move to geohash querying
  and add server-side moderation/rate-limiting before large-scale rollout.

## iOS trigger fallbacks (Phase 3)

Because iOS can't reliably run shake detection when the app is force-quit, the
app exposes `suraksha://sos`. Users bind it once via the **Shortcuts** app
("Open URL" → `suraksha://sos`) and assign that Shortcut to the **Action Button**
(iPhone 15 Pro+), **Back Tap** (Settings → Accessibility → Touch), a
**lock-screen / Control Center widget**, or **"Hey Siri, send SOS"**. The
home-screen long-press **Quick Action** works on both platforms.

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
