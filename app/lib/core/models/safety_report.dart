/// A community report about how safe an area feels. Reports are pseudonymous:
/// [reporterId] is kept for moderation only and never shown to other users.
enum SafetyCategory {
  safe('Feels safe', true),
  wellLit('Well lit / busy', true),
  poorlyLit('Poorly lit', false),
  harassment('Harassment reported', false),
  unsafe('Feels unsafe', false),
  other('Other', false);

  const SafetyCategory(this.label, this.isPositive);
  final String label;

  /// True for positive/safe signals, false for cautions — drives map colour.
  final bool isPositive;
}

class SafetyReport {
  final String id;
  final String reporterId;
  final double lat;
  final double lng;
  final SafetyCategory category;
  final String? note;
  final DateTime createdAt;

  const SafetyReport({
    required this.id,
    required this.reporterId,
    required this.lat,
    required this.lng,
    required this.category,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'lat': lat,
        'lng': lng,
        'category': category.name,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SafetyReport.fromMap(String id, Map<String, dynamic> map) {
    return SafetyReport(
      id: id,
      reporterId: map['reporterId'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      category: SafetyCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => SafetyCategory.other,
      ),
      note: map['note'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
