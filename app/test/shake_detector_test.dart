import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha/core/models/ack.dart';
import 'package:suraksha/core/models/sos_event.dart';
import 'package:suraksha/core/models/sos_settings.dart';
import 'package:suraksha/core/models/trusted_contact.dart';
import 'package:suraksha/core/services/emergency_numbers.dart';
import 'package:suraksha/features/sos/sos_service.dart';

/// A fake gateway that records interactions without any network — implements
/// the full [AlertGateway] surface so it stays in sync with the interface.
class _FakeGateway implements AlertGateway {
  final List<SosEvent> dispatched = [];
  final List<SosStatus> statuses = [];
  final List<Ack> acks = [];

  @override
  Future<String> dispatch(SosEvent event, List<TrustedContact> contacts) async {
    dispatched.add(event);
    return 'evt-${dispatched.length}';
  }

  @override
  Future<void> pushLocation(String eventId, Position pos) async {}

  @override
  Future<void> updateStatus(String eventId, SosStatus status) async {
    statuses.add(status);
  }

  @override
  Future<void> attachMedia(String eventId, String type, String url) async {}

  @override
  Stream<List<Ack>> watchAcks(String eventId) => Stream.value(const <Ack>[]);

  @override
  Future<void> acknowledge(String eventId, Ack ack) async {
    acks.add(ack);
  }
}

void main() {
  test('SosEvent round-trips through its data map', () {
    final e = SosEvent(
      id: 'x',
      userId: 'u',
      trigger: SosTrigger.shake,
      startedAt: DateTime.parse('2026-01-01T00:00:00Z'),
      escalationMinutes: 4,
    );
    final restored = SosEvent.fromMap('x', e.toMap());
    expect(restored.trigger, SosTrigger.shake);
    expect(restored.status, SosStatus.active);
    expect(restored.escalationMinutes, 4);
  });

  test('SosSettings round-trips and keeps defaults for missing keys', () {
    const s = SosSettings(
      thresholdG: 3.1,
      stealthMode: true,
      sirenOnSos: true,
      voiceTriggerEnabled: true,
    );
    final restored = SosSettings.fromMap(s.toMap());
    expect(restored.thresholdG, 3.1);
    expect(restored.stealthMode, isTrue);
    expect(restored.sirenOnSos, isTrue);
    expect(restored.voiceTriggerEnabled, isTrue);
    // Missing keys fall back to defaults.
    expect(SosSettings.fromMap(const {}).requiredShakes, 3);
    expect(SosSettings.fromMap(const {}).voiceTriggerEnabled, isFalse);
  });

  test('Ack round-trips response and name', () {
    final a = Ack(
      id: 'a',
      guardianName: 'Mom',
      response: AckResponse.callingPolice,
      at: DateTime.parse('2026-01-01T00:00:00Z'),
    );
    final restored = Ack.fromMap('a', a.toMap());
    expect(restored.guardianName, 'Mom');
    expect(restored.response, AckResponse.callingPolice);
  });

  test('EmergencyNumbers resolves by country and falls back to 112', () {
    expect(EmergencyNumbers.forCountry('US'), '911');
    expect(EmergencyNumbers.forCountry('in'), '112');
    expect(EmergencyNumbers.forCountry('ZZ'), '112');
    expect(EmergencyNumbers.forCountry(null), '112');
  });

  test('fake gateway satisfies the full AlertGateway surface', () async {
    final g = _FakeGateway();
    final id = await g.dispatch(
      SosEvent(
        id: '',
        userId: 'u',
        trigger: SosTrigger.manual,
        startedAt: DateTime.now(),
      ),
      const [],
    );
    await g.acknowledge(id, Ack(
      id: '',
      guardianName: 'Dad',
      response: AckResponse.onMyWay,
      at: DateTime.now(),
    ));
    expect(g.dispatched, hasLength(1));
    expect(g.acks.single.response, AckResponse.onMyWay);
  });
}
