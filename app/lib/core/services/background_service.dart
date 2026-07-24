import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'settings_service.dart';

/// Configures and runs the Android foreground service (and iOS background
/// handler) that keeps **location streaming** and **shake detection** alive
/// while the app is backgrounded or the screen is locked.
///
/// Communication with the UI isolate uses [FlutterBackgroundService.invoke] /
/// [on]: the service emits `position` and `shake` events; the UI sends
/// `startShare` / `stopShare` / `configure` commands.
class SafetyBackgroundService {
  static const _channelId = 'suraksha_foreground';
  static const _notifId = 8801;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Android needs a notification channel for the persistent foreground note.
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'Suraksha protection',
      description: 'Keeps location sharing and shake-to-alert active.',
      importance: Importance.low, // low = quiet but persistent
    ));

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false, // started explicitly when protection is enabled
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Suraksha is protecting you',
        initialNotificationContent: 'Shake-to-alert is on.',
        foregroundServiceNotificationId: _notifId,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: _onIosBackground,
        autoStart: false,
      ),
    );
  }

  static Future<void> startProtection() =>
      FlutterBackgroundService().startService();

  static void stopProtection() =>
      FlutterBackgroundService().invoke('stopService');
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  // iOS grants only short background windows; location `Always` keeps the app
  // alive for location callbacks. Return true to signal work was handled.
  return true;
}

/// Entry point that runs in the background isolate.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  StreamSubscription<Position>? posSub;
  StreamSubscription<AccelerometerEvent>? accSub;

  // ── Shake detection (mirrors ShakeDetector; kept self-contained so the
  //    isolate has no dependency on the UI tree). Sensitivity comes from the
  //    same persisted settings the calibration screen writes. ──
  const gravity = 9.80665;
  var thresholdG = 2.7;
  var requiredShakes = 3;
  SettingsService.readRaw().then((s) {
    thresholdG = s.thresholdG;
    requiredShakes = s.requiredShakes;
  });
  final spikeTimes = <DateTime>[];
  DateTime? lastSpike;
  DateTime? firedAt;

  accSub = accelerometerEventStream().listen((e) {
    final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    final gForce = (magnitude - gravity).abs() / gravity;
    if (gForce < thresholdG) return;

    final now = DateTime.now();
    if (firedAt != null && now.difference(firedAt!) < const Duration(seconds: 3)) {
      return;
    }
    if (lastSpike != null &&
        now.difference(lastSpike!) < const Duration(milliseconds: 120)) {
      return;
    }
    lastSpike = now;
    spikeTimes.add(now);
    spikeTimes.removeWhere(
        (t) => now.difference(t) > const Duration(milliseconds: 1200));
    if (spikeTimes.length >= requiredShakes) {
      spikeTimes.clear();
      firedAt = now;
      // Notify the UI isolate to run the full SOS flow (which has auth/gateway).
      service.invoke('shake');
    }
  });

  // ── Live location streaming ──
  void startLocation() {
    posSub?.cancel();
    posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((pos) {
      service.invoke('position', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': pos.speed,
        'accuracy': pos.accuracy,
        'ts': DateTime.now().toIso8601String(),
      });
    });
  }

  // Commands from the UI isolate.
  service.on('startShare').listen((_) => startLocation());
  service.on('stopShare').listen((_) {
    posSub?.cancel();
    posSub = null;
  });
  service.on('stopService').listen((_) async {
    await posSub?.cancel();
    await accSub?.cancel();
    await service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    service.on('setForeground').listen((_) => service.setAsForegroundService());
  }
}
