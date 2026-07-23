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
