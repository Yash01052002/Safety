import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Wraps device location: one-shot fixes for an SOS and a continuous stream
/// for live sharing. Battery-aware distance filtering keeps updates lean.
class LocationService {
  StreamSubscription<Position>? _liveSub;

  /// Ensures location services are on and permission is granted.
  /// Returns true if we can read location.
  Future<bool> ensurePermission({bool background = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    // Background/live sharing wants "always"; foreground SOS accepts "whileInUse".
    if (background && permission == LocationPermission.whileInUse) {
      // Caller should route the user to settings to upgrade to Always.
      return true;
    }
    return true;
  }

  /// A single best-effort fix for an outgoing SOS. Falls back to last known
  /// position if a fresh fix times out.
  Future<Position?> currentFix({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Continuous stream for live sharing. [distanceFilterMeters] throttles
  /// updates; raise it to save battery when the user is moving fast.
  Stream<Position> liveStream({int distanceFilterMeters = 15}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  void stopLive() {
    _liveSub?.cancel();
    _liveSub = null;
  }
}
