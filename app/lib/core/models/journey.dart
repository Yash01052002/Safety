/// A monitored trip: "I'm heading somewhere, expect me by [deadline]." If the
/// user doesn't arrive (or check in) by the deadline, the app auto-escalates to
/// an SOS so guardians are alerted even if the user can't reach their phone.
class Journey {
  final DateTime startedAt;

  /// When the user is expected to arrive / check in.
  final DateTime deadline;

  /// Optional free-text destination shown to guardians on escalation.
  final String? destination;

  const Journey({
    required this.startedAt,
    required this.deadline,
    this.destination,
  });

  Duration get remaining => deadline.difference(DateTime.now());
  bool get isOverdue => DateTime.now().isAfter(deadline);

  Journey copyWith({DateTime? deadline}) => Journey(
        startedAt: startedAt,
        deadline: deadline ?? this.deadline,
        destination: destination,
      );
}
