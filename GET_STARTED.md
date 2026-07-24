# Get Started — building & running Suraksha

This repo holds the **source** for the Suraksha safety app. It isn't on an app
store yet and there's no prebuilt APK/IPA — you build it yourself. Two paths:

- **A. Quick look** — run the app with no backend to click through the whole UI
  (~15 min if you have Flutter). SOS just logs to the console.
- **B. Full functionality** — wire up Firebase + keys so SOS actually reaches
  guardians, the map works, etc.

All app code lives in [`app/`](app/). Deeper references:
[`app/README.md`](app/README.md), [`docs/LAUNCH_CHECKLIST.md`](docs/LAUNCH_CHECKLIST.md),
[`docs/NATIVE_MODULES.md`](docs/NATIVE_MODULES.md).

---

## Prerequisites

1. **Flutter SDK ≥ 3.19** — https://docs.flutter.dev/get-started/install
   Verify with `flutter doctor` (fix anything it flags red).
2. **Android:** Android Studio + an Android device (USB debugging on) or an
   emulator.
3. **iOS (Mac only):** Xcode. Installing on a physical iPhone also needs an
   Apple Developer account.

---

## A. Quick look (no backend, "dev mode")

The app is built to launch **without** Firebase — alerts are logged to the
console instead of sent, so you can exercise the full UI immediately.

```bash
cd app
flutter create .        # generates the android/ + ios/ native shells
flutter pub get
flutter run             # pick your connected device / emulator
```

> After `flutter create .`, if it overwrote `android/app/src/main/AndroidManifest.xml`
> or `ios/Runner/Info.plist`, restore the committed versions (they hold the
> permissions and background modes). See `app/README.md`.

### Build an installable Android APK

```bash
cd app
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Copy that file to an Android phone and open it (allow "install from unknown
sources"). That's the closest thing to a "download".

### iOS

```bash
cd app
open ios/Runner.xcworkspace      # set your Team + bundle id in Xcode, then Run
# or: flutter build ios
```

---

## B. Full functionality

To make SOS actually deliver and the maps/voice features work, add the backend
and keys. Minimum to get a **working SOS end-to-end**:

### 1. Firebase (auth, database, push, SMS)

```bash
npm i -g firebase-tools
firebase login
cd app
flutterfire configure     # creates lib/firebase_options.dart + platform config
cd functions && npm install && cd ..
```

Then configure SMS (guardians without the app) and deploy the backend:

```bash
firebase functions:config:set \
  twilio.sid=ACxxxx twilio.token=xxxx twilio.from="+1..." \
  app.trackbase="https://<your-hosting-domain>"

firebase deploy --only functions,firestore:rules,storage,hosting
```

Paste your **web** Firebase config into `app/web_track/index.html` (the
`firebaseConfig` placeholders) so the guardian tracking link works.

Once Firebase is configured, the app leaves dev mode automatically and shows the
phone-number sign-in.

### 2. Google Maps (guardian & community maps)

Create an API key (Maps SDK for Android + iOS) in Google Cloud and add it:
- Android: `app/android/app/src/main/AndroidManifest.xml` (a
  `com.google.android.geo.API_KEY` `<meta-data>`).
- iOS: `app/ios/Runner/AppDelegate.swift` via `GMSServices.provideAPIKey(...)`.

### 3. Optional extras

- **Voice wake word:** Picovoice key + a trained `.ppn` —
  `flutter run --dart-define=PICOVOICE_ACCESS_KEY=...` (see `docs/NATIVE_MODULES.md`).
- **Siren:** add `assets/siren.mp3` and declare it (see `app/assets/README.md`).
- **Watch / widgets:** native targets — `docs/NATIVE_MODULES.md`.

---

## Sanity checks before you build

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

(These weren't run in the environment that generated the code, so run them once
locally and clear anything that surfaces.)

---

## Which path do I want?

| Goal | Path |
|------|------|
| See what the app looks like / demo the UI | **A** — dev mode, Android APK |
| Actually send an SOS to a real contact | **B** — Firebase + Twilio |
| Ship it to other people | Complete `docs/LAUNCH_CHECKLIST.md`, then submit to the stores |
