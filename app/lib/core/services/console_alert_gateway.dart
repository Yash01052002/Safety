import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/ack.dart';
import '../models/sos_event.dart';
import '../models/trusted_contact.dart';
import '../../features/sos/sos_service.dart';

/// A no-backend [AlertGateway] used for local development and tests: it logs
/// what *would* be dispatched. Replace with `FirestoreAlertGateway` (Phase 1)
/// which writes the event to Firestore and triggers a Cloud Function that
/// sends FCM push + Twilio SMS to guardians.
class ConsoleAlertGateway implements AlertGateway {
  int _seq = 0;

  @override
  Future<String> dispatch(
      SosEvent event, List<TrustedContact> contacts) async {
    final id = 'evt-${++_seq}';
    debugPrint('── SOS DISPATCH [$id] ─────────────────────────');
    debugPrint('trigger=${event.trigger.name} '
        'loc=${event.lat},${event.lng} battery=${event.batteryPct}%');
    for (final c in contacts) {
      debugPrint('  → notify ${c.name} (${c.phone}) '
          'via ${c.hasApp ? "push" : "SMS"}');
    }
    debugPrint('───────────────────────────────────────────────');
    return id;
  }

  @override
  Future<void> pushLocation(String eventId, Position pos) async {
    debugPrint('[$eventId] live @ ${pos.latitude},${pos.longitude}');
  }

  @override
  Future<void> updateStatus(String eventId, SosStatus status) async {
    debugPrint('[$eventId] status → ${status.name}');
  }

  @override
  Future<void> attachMedia(String eventId, String type, String url) async {
    debugPrint('[$eventId] media ($type) → $url');
  }

  @override
  Stream<List<Ack>> watchAcks(String eventId) => Stream.value(const []);

  @override
  Future<void> acknowledge(String eventId, Ack ack) async {
    debugPrint('[$eventId] ack: ${ack.guardianName} → ${ack.response.label}');
  }
}
