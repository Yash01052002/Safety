# App assets

Add a looping siren sound here as `siren.mp3`, then declare it in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/siren.mp3
```

`AlarmService` (`lib/core/services/alarm_service.dart`) plays this when the
siren option is enabled. It's not committed because it's a binary; the service
fails gracefully (flashlight strobe still runs) if the asset is missing.

## Voice wake word (`hey_suraksha.ppn`)

For the always-listening voice trigger, add a Picovoice keyword file here as
`hey_suraksha.ppn` and declare it under `flutter/assets`:

```yaml
flutter:
  assets:
    - assets/hey_suraksha.ppn
```

Train it at the Picovoice Console and build with
`--dart-define=PICOVOICE_ACCESS_KEY=...`. Without the key/asset the voice
trigger stays inert (see `docs/NATIVE_MODULES.md`).
