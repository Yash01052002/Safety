# Phase 6 — Native modules

These pieces need platform-native code, so they live outside `lib/`. All the
tap-to-SOS surfaces converge on the **`suraksha://sos` deep link**, which
`QuickTriggerService` (Dart) already turns into an SOS — so none of them need
new app logic, only wiring.

> Prerequisite: run `flutter create .` in `app/` once to generate the
> `android/` (Gradle, `MainActivity`) and `ios/` (Xcode project, `AppDelegate`)
> shells, then re-apply the committed `AndroidManifest.xml` / `Info.plist`.

## Shipped in this repo (drop-in source)

### Android home-screen / lock-screen widget
- `android/app/src/main/kotlin/app/suraksha/SosWidgetProvider.kt`
- `android/app/src/main/res/layout/sos_widget.xml`
- `android/app/src/main/res/drawable/sos_widget_background.xml`
- `android/app/src/main/res/xml/sos_widget_info.xml`
- `<receiver>` declared in `AndroidManifest.xml`.

Ensure the module **namespace / applicationId is `app.suraksha`** (in
`android/app/build.gradle`) so the `package app.suraksha` in the Kotlin files
matches — or change the package in both Kotlin files and the manifest.

### Android Quick Settings tile
- `android/app/src/main/kotlin/app/suraksha/SosTileService.kt`
- `<service>` with `BIND_QUICK_SETTINGS_TILE` declared in `AndroidManifest.xml`.
- Users add it once via the QS edit screen (pencil → drag "SOS" in).

### iOS home-screen / lock-screen widget (WidgetKit)
- `ios/SosWidget/SosWidget.swift`
- In Xcode: **File → New → Target → Widget Extension**, name it `SosWidget`,
  replace the generated Swift with this file. Supports `systemSmall` and the
  `accessoryCircular` **lock-screen** family. Opens `suraksha://sos`.

### Wear OS companion (one-press SOS on the wrist) — scaffolded
Standalone Android module under `app/wear/`:
- `wear/build.gradle` — Compose-for-Wear app, id `app.suraksha` (must match the
  phone app id so the two pair).
- `wear/src/main/kotlin/app/suraksha/wear/MainActivity.kt` — a single big SOS
  button (Compose for Wear OS) with sending/sent/failed states.
- `wear/src/main/kotlin/app/suraksha/wear/SosSender.kt` — delivers the SOS two
  ways: a `MessageClient` `/sos` message **and** `RemoteActivityHelper` opening
  `suraksha://sos` on the phone.
- Phone side: `android/app/.../SosWearListenerService.kt`
  (`WearableListenerService`) receives the `/sos` message and fires the SOS even
  when the app is closed; declared as a `<service>` in the phone manifest.

**Wiring** (after `flutter create .`):
1. `android/settings.gradle` → add `include ':wear'` and the module path.
2. Phone `android/app/build.gradle` → add
   `implementation 'com.google.android.gms:play-services-wearable:18.2.0'`.
3. Sign the watch APK with the **same key** as the phone app so they pair.
4. Build/install: `./gradlew :wear:installDebug` onto a paired watch/emulator.

## Still to build (larger native efforts)

### Apple Watch companion (watchOS app) — scaffolded
watchOS app sources under `app/ios/SurakshaWatch/`:
- `SurakshaWatchApp.swift` — `@main` app.
- `ContentView.swift` — single big SOS button (SwiftUI) with idle/sending/
  sent/queued/failed states.
- `WatchSosSender.swift` — `WCSession` sender: `sendMessage` when the phone is
  reachable, else `transferUserInfo` (queued, guaranteed) so nothing is dropped.

Phone side: `app/ios/Runner/PhoneSessionDelegate.swift` — a `WCSessionDelegate`
that opens `suraksha://sos` on receipt (live or queued), reusing the existing
handler.

**Wiring** (in Xcode, after `flutter create .`):
1. **File → New → Target → watchOS → App**, name it `SurakshaWatch`; replace the
   generated sources with the three files above.
2. Add `PhoneSessionDelegate.swift` to the **Runner** target and call
   `PhoneSessionDelegate.shared.activate()` in
   `application(_:didFinishLaunchingWithOptions:)`.
3. The `suraksha` URL scheme is already in `Runner/Info.plist`; ensure the watch
   app's bundle id is `<Runner.bundle.id>.watchkitapp`.

### Always-listening voice trigger — implemented (needs a key + keyword)
"Hey Siri, send SOS" already works via a user-created **Shortcut** bound to
`suraksha://sos`. A true always-on hotword is implemented with on-device
keyword spotting (Picovoice Porcupine):
- `lib/core/services/voice_trigger_service.dart` — wraps `PorcupineManager`;
  no audio leaves the device. Reports `isConfigured == false` and no-ops if the
  key or keyword asset is missing, so the app is unaffected without setup.
- Opt-in setting `voiceTriggerEnabled` (default **off**), enabled only after an
  explicit mic-privacy consent dialog (Shake settings → Voice trigger).
- The home screen starts/stops the listener to match the setting; the wake word
  fires the normal SOS flow (honouring stealth/countdown).

**Setup to activate:**
1. Create a free access key at the Picovoice Console and train a wake word
   (e.g. "Hey Suraksha") → download the `.ppn`.
2. Bundle it as `assets/hey_suraksha.ppn` and declare it under
   `flutter/assets` in `pubspec.yaml`.
3. Build with the key: `flutter run --dart-define=PICOVOICE_ACCESS_KEY=...`.
4. Microphone permission is already declared (Android `RECORD_AUDIO`, iOS
   `NSMicrophoneUsageDescription`).

**Background note:** the listener runs in the main isolate, so it keeps working
while the app is backgrounded or the screen is locked *because* the Phase 2
foreground service keeps the process alive. It does **not** run after the app is
fully force-quit. Evaluate battery draw before enabling by default.
