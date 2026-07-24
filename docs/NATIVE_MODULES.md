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

## Still to build (larger native efforts)

### Wear OS companion (one-press SOS on the wrist)
A separate Gradle module (`:wear`) with a Compose-for-Wear tile/app whose button
either (a) opens `suraksha://sos` on the phone via the Wearable
`MessageClient`/`RemoteActivityHelper`, or (b) calls the backend directly. Needs
its own manifest, build config, and pairing logic — scaffold with Android
Studio's Wear OS module template.

### Apple Watch companion (watchOS app)
A WatchKit app target in the same Xcode workspace. A single SOS button sends a
message to the phone via `WCSession` (or hits the backend). Add via Xcode
**File → New → Target → Watch App**.

### Always-listening voice trigger
"Hey Siri, send SOS" already works today via a user-created **Shortcut** bound
to `suraksha://sos` (no code). A true always-on hotword ("Hey Suraksha, help")
needs an on-device keyword-spotting engine (e.g. Porcupine) running in the
foreground service, plus clear mic-privacy disclosure — evaluate battery and
false-trigger cost before committing.
