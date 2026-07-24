import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/live_session.dart';
import '../../core/repositories/live_share_repository.dart';
import '../../core/services/location_service.dart';

/// Drives a proactive live-share session: starts location streaming, mirrors
/// points to the guardian-visible track, auto-stops on expiry, and adapts the
/// update distance to battery level to conserve power on long shares.
class LiveShareController extends ChangeNotifier {
  LiveShareController({
    required this.repo,
    required this.locationService,
  });

  final LiveShareRepository repo;
  final LocationService locationService;
  final Battery _battery = Battery();

  LiveSession? _session;
  LiveSession? get session => _session;
  bool get isSharing => _session?.active ?? false;

  StreamSubscription<Position>? _posSub;
  Timer? _expiryTimer;

  Future<void> start(ShareDuration choice) async {
    if (isSharing) return;
    if (!await locationService.ensurePermission(background: true)) return;

    _session = await repo.start(duration: choice.duration);
    notifyListeners();

    final filter = await _batteryAwareFilter();
    _posSub = locationService
        .liveStream(distanceFilterMeters: filter)
        .listen((pos) => repo.pushLocation(_session!.id, pos));

    if (choice.duration != null) {
      _expiryTimer = Timer(choice.duration!, stop);
    }
  }

  Future<void> stop() async {
    final s = _session;
    if (s == null) return;
    _posSub?.cancel();
    _posSub = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await repo.stop(s.id);
    _session = null;
    notifyListeners();
  }

  /// Widen the distance filter (fewer updates) as battery drops.
  Future<int> _batteryAwareFilter() async {
    try {
      final level = await _battery.batteryLevel;
      if (level <= 15) return 60;
      if (level <= 35) return 30;
      return 15;
    } catch (_) {
      return 20;
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }
}
