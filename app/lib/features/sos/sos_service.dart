import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/sos_event.dart';
import '../../core/models/trusted_contact.dart';
import '../../core/services/location_service.dart';

/// Orchestrates an SOS: capture location + battery, build the alert, deliver to
/// guardians via app push (backend) with an SMS fallback, and start live share.
///
/// Delivery is intentionally behind [AlertGateway] so the transport (Firebase,
/// custom API, pure SMS) can be swapped without touching trigger logic.
abstract class AlertGateway {
  /// Push a rich alert to guardians who have the app. Returns event id.
  Future<String> dispatch(SosEvent event, List<TrustedContact> contacts);

  /// Push a live location update for an active event.
  Future<void> pushLocation(String eventId, Position pos);

  /// Mark an event resolved/cancelled.
  Future<void> updateStatus(String eventId, SosStatus status);
}

class SosController extends ChangeNotifier {
  SosController({
    required this.gateway,
    required this.locationService,
    required this.currentUserId,
  });

  final AlertGateway gateway;
  final LocationService locationService;
  final String currentUserId;
  final Battery _battery = Battery();

  SosEvent? _active;
  SosEvent? get active => _active;
  bool get isActive => _active?.status == SosStatus.active;

  StreamSubscription<Position>? _liveSub;

  /// A pending countdown so the user can cancel a false alarm.
  Timer? _countdown;
  int _countdownRemaining = 0;
  int get countdownRemaining => _countdownRemaining;
  bool get isCountingDown => _countdown?.isActive ?? false;

  /// Begin an SOS. In [silent] (stealth) mode the cancel countdown is skipped
  /// and the alert fires immediately — used when openly cancelling is unsafe.
  Future<void> trigger(
    SosTrigger trigger,
    List<TrustedContact> contacts, {
    bool silent = false,
    int countdownSeconds = 5,
  }) async {
    if (isActive || isCountingDown) return;

    if (silent || countdownSeconds <= 0) {
      await _fire(trigger, contacts);
      return;
    }

    _countdownRemaining = countdownSeconds;
    notifyListeners();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) async {
      _countdownRemaining--;
      notifyListeners();
      if (_countdownRemaining <= 0) {
        t.cancel();
        await _fire(trigger, contacts);
      }
    });
  }

  /// Cancel a pending (pre-fire) SOS during the countdown.
  void cancelCountdown() {
    _countdown?.cancel();
    _countdown = null;
    _countdownRemaining = 0;
    notifyListeners();
  }

  Future<void> _fire(SosTrigger trigger, List<TrustedContact> contacts) async {
    _countdown?.cancel();
    _countdownRemaining = 0;

    await locationService.ensurePermission();
    final pos = await locationService.currentFix();
    final battery = await _safeBattery();

    final event = SosEvent(
      id: '', // assigned by gateway
      userId: currentUserId,
      trigger: trigger,
      startedAt: DateTime.now(),
      status: SosStatus.active,
      lat: pos?.latitude,
      lng: pos?.longitude,
      batteryPct: battery,
    );

    String eventId;
    try {
      eventId = await gateway.dispatch(event, contacts);
    } catch (e) {
      // Backend unreachable — fall straight to SMS so the alert still goes out.
      debugPrint('SOS dispatch failed, using SMS fallback: $e');
      await _smsFallback(contacts, pos);
      eventId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    }

    _active = SosEvent(
      id: eventId,
      userId: event.userId,
      trigger: event.trigger,
      startedAt: event.startedAt,
      status: SosStatus.active,
      lat: event.lat,
      lng: event.lng,
      batteryPct: event.batteryPct,
    );
    notifyListeners();

    _startLiveShare(eventId);
  }

  void _startLiveShare(String eventId) {
    _liveSub?.cancel();
    _liveSub = locationService.liveStream().listen((pos) {
      gateway.pushLocation(eventId, pos);
    });
  }

  /// Open the SMS composer pre-filled to the top-priority guardian. This is the
  /// no-network / no-backend last resort; it requires a user tap to send.
  Future<void> _smsFallback(
      List<TrustedContact> contacts, Position? pos) async {
    if (contacts.isEmpty) return;
    final sorted = [...contacts]..sort((a, b) => a.priority.compareTo(b.priority));
    final numbers = sorted.map((c) => c.phone).join(',');
    final mapLink = pos != null
        ? 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}'
        : '(location unavailable)';
    final body =
        Uri.encodeComponent('I need help. My location: $mapLink — sent via Suraksha');
    final uri = Uri.parse('sms:$numbers?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> resolve() async {
    final e = _active;
    if (e == null) return;
    _liveSub?.cancel();
    _liveSub = null;
    try {
      await gateway.updateStatus(e.id, SosStatus.resolved);
    } catch (_) {}
    _active = null;
    notifyListeners();
  }

  Future<int?> _safeBattery() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _liveSub?.cancel();
    super.dispose();
  }
}
