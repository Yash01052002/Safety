/// A trusted contact ("guardian") who receives alerts.
class TrustedContact {
  final String id;
  final String name;
  final String phone;

  /// Lower number = higher priority in the escalation ladder.
  final int priority;

  /// Whether this contact also uses the app (gets rich push instead of SMS).
  final bool hasApp;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    this.priority = 0,
    this.hasApp = false,
  });

  factory TrustedContact.fromMap(String id, Map<String, dynamic> map) {
    return TrustedContact(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      hasApp: map['hasApp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'priority': priority,
        'hasApp': hasApp,
      };
}
