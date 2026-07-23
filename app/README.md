# Suraksha — Women's Safety App

Cross-platform (Android + iOS) safety app built with **Flutter**. Core features:
**shake-to-alert SOS**, **live location sharing**, and **trusted-contact alerts**.

> This directory contains the app source and platform config from **Phase 0 +
> the start of Phase 1** of the [master plan](../MASTER_PLAN.md). It is designed
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
| Android permissions + foreground service | `android/app/src/main/AndroidManifest.xml` | ✅ |
| iOS permissions + background modes | `ios/Runner/Info.plist` | ✅ |
| Dev gateway (console) | `lib/core/services/console_alert_gateway.dart` | ✅ placeholder |

## Not yet done (next steps)

- **Firebase wiring** (Phase 1): Auth (phone OTP), Firestore for users/contacts/
  events, Cloud Function → FCM push + Twilio SMS. Replace `ConsoleAlertGateway`
  with a `FirestoreAlertGateway`.
- **Contacts UI** (Phase 1): pick from phonebook, invite, priority order.
- **Background foreground-service integration** (Phase 2): move the shake
  listener + location stream into `flutter_background_service` so they run with
  the screen locked.
- **Guardian live map** + web track link (Phase 2).
- iOS shake-when-killed workarounds: Action Button / Back Tap / Siri Shortcut.

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
