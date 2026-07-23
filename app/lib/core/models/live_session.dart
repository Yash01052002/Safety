/// A proactive (non-emergency) live-location sharing session — e.g. "share my
/// location with Mom until I get home". Distinct from an [SosEvent], but it
/// reuses the same public track projection so guardians can watch it on the
/// existing web page and in-app map.
class LiveSession {
  final String id;
  final String userId;
  final DateTime startedAt;

  /// When sharing auto-expires. Null means "until I stop".
  final DateTime? expiresAt;

  final bool active;

  const LiveSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.expiresAt,
    this.active = true,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Duration? get remaining =>
      expiresAt == null ? null : expiresAt!.difference(DateTime.now());

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'startedAt': startedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'active': active,
      };

  factory LiveSession.fromMap(String id, Map<String, dynamic> map) {
    return LiveSession(
      id: id,
      userId: map['userId'] as String? ?? '',
      startedAt: DateTime.tryParse(map['startedAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'] as String)
          : null,
      active: map['active'] as bool? ?? true,
    );
  }
}

/// Preset durations offered in the share sheet.
enum ShareDuration {
  fifteenMin(Duration(minutes: 15), '15 minutes'),
  oneHour(Duration(hours: 1), '1 hour'),
  eightHours(Duration(hours: 8), '8 hours'),
  untilStopped(null, 'Until I stop');

  const ShareDuration(this.duration, this.label);
  final Duration? duration;
  final String label;
}
