import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/live_session.dart';

/// Persists proactive live-share sessions. Writes to two places:
///   • `liveSessions/{id}`  — the owner's private record of the session
///   • `publicTracks/{id}`  — the minimal, link-scoped projection the guardian
///                            web page and in-app map read (kind: "share")
///
/// Reusing `publicTracks` means the existing track page works unchanged.
class LiveShareRepository {
  LiveShareRepository({required this.userId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  Future<LiveSession> start({Duration? duration}) async {
    final now = DateTime.now();
    final expiresAt = duration == null ? null : now.add(duration);

    // Resolve the sharer's display name for the guardian-visible projection.
    final profile = await _db.collection('users').doc(userId).get();
    final userName = profile.data()?['name'] as String? ?? 'A friend';

    final ref = _db.collection('liveSessions').doc();
    final session = LiveSession(
      id: ref.id,
      userId: userId,
      startedAt: now,
      expiresAt: expiresAt,
    );
    await ref.set(session.toMap());

    await _db.collection('publicTracks').doc(ref.id).set({
      'kind': 'share',
      'userName': userName,
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt?.toIso8601String(),
    });
    return session;
  }

  Future<void> pushLocation(String sessionId, Position pos) async {
    await _db.collection('publicTracks').doc(sessionId).set({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> stop(String sessionId) async {
    await _db.collection('liveSessions').doc(sessionId).set(
      {'active': false, 'endedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await _db.collection('publicTracks').doc(sessionId).set(
      {'status': 'ended', 'endedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
