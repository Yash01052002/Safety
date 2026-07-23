import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/safety_report.dart';

/// Reads and writes community safety reports.
///
/// Firestore range queries only support one field, so we bound by latitude
/// server-side and filter longitude/exact distance on the client. Fine for the
/// small radii a map viewport needs; swap in geohash querying if scale demands.
class SafetyReportRepository {
  SafetyReportRepository({required this.userId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('safetyReports');

  Future<void> add({
    required double lat,
    required double lng,
    required SafetyCategory category,
    String? note,
  }) async {
    final report = SafetyReport(
      id: '',
      reporterId: userId,
      lat: lat,
      lng: lng,
      category: category,
      note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      createdAt: DateTime.now(),
    );
    await _col.add({
      ...report.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reports within [radiusKm] of ([lat],[lng]).
  Future<List<SafetyReport>> nearby({
    required double lat,
    required double lng,
    double radiusKm = 3,
    int limit = 200,
  }) async {
    final latDelta = radiusKm / 111.0; // ~111 km per degree latitude
    final snap = await _col
        .where('lat', isGreaterThanOrEqualTo: lat - latDelta)
        .where('lat', isLessThanOrEqualTo: lat + latDelta)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => SafetyReport.fromMap(d.id, d.data()))
        .where((r) => distanceKm(lat, lng, r.lat, r.lng) <= radiusKm)
        .toList();
  }
}

/// Great-circle distance in km (haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthKm = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return earthKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180.0;
