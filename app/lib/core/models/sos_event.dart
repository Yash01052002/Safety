/// How an SOS was triggered.
enum SosTrigger { manual, shake, hardwareButton }

/// Lifecycle state of an SOS event.
enum SosStatus { active, resolved, cancelled }

/// A single SOS emergency event.
class SosEvent {
  final String id;
  final String userId;
  final SosTrigger trigger;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SosStatus status;
  final double? lat;
  final double? lng;
  final int? batteryPct;

  /// Minutes to wait for an acknowledgment before the backend escalates to the
  /// next-priority contact. Captured from settings at trigger time.
  final int? escalationMinutes;

  const SosEvent({
    required this.id,
    required this.userId,
    required this.trigger,
    required this.startedAt,
    this.endedAt,
    this.status = SosStatus.active,
    this.lat,
    this.lng,
    this.batteryPct,
    this.escalationMinutes,
  });

  factory SosEvent.fromMap(String id, Map<String, dynamic> map) {
    return SosEvent(
      id: id,
      userId: map['userId'] as String? ?? '',
      trigger: SosTrigger.values.firstWhere(
        (t) => t.name == map['trigger'],
        orElse: () => SosTrigger.manual,
      ),
      startedAt: DateTime.tryParse(map['startedAt'] as String? ?? '') ??
          DateTime.now(),
      endedAt: map['endedAt'] != null
          ? DateTime.tryParse(map['endedAt'] as String)
          : null,
      status: SosStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SosStatus.active,
      ),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      batteryPct: (map['batteryPct'] as num?)?.toInt(),
      escalationMinutes: (map['escalationMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'trigger': trigger.name,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'status': status.name,
        'lat': lat,
        'lng': lng,
        'batteryPct': batteryPct,
        'escalationMinutes': escalationMinutes,
      };
}
