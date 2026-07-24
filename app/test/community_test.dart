import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/core/models/safety_report.dart';
import 'package:suraksha/core/repositories/safety_report_repository.dart';

void main() {
  test('distanceKm is ~0 for the same point and grows with separation', () {
    expect(distanceKm(12.9716, 77.5946, 12.9716, 77.5946), closeTo(0, 0.001));
    // Bengaluru → Mumbai is ~840 km.
    final d = distanceKm(12.9716, 77.5946, 19.0760, 72.8777);
    expect(d, greaterThan(800));
    expect(d, lessThan(900));
  });

  test('distanceKm ~1.11 km for 0.01° of latitude', () {
    expect(distanceKm(0, 0, 0.01, 0), closeTo(1.11, 0.05));
  });

  test('SafetyReport round-trips category and note', () {
    final r = SafetyReport(
      id: 'r1',
      reporterId: 'u1',
      lat: 1.5,
      lng: 2.5,
      category: SafetyCategory.harassment,
      note: 'poorly lit underpass',
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
    );
    final back = SafetyReport.fromMap('r1', r.toMap());
    expect(back.category, SafetyCategory.harassment);
    expect(back.note, 'poorly lit underpass');
    expect(back.lat, 1.5);
    expect(back.category.isPositive, isFalse);
  });

  test('unknown category falls back to other', () {
    final back = SafetyReport.fromMap('x', {'category': 'nonsense'});
    expect(back.category, SafetyCategory.other);
  });
}
