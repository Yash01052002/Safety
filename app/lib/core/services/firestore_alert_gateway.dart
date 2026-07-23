import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/ack.dart';
import '../models/sos_event.dart';
import '../models/trusted_contact.dart';
import '../../features/sos/sos_service.dart';

/// Production [AlertGateway]. Writes the SOS event to Firestore, which triggers
/// the `onSosCreated` Cloud Function (see functions/index.js) to fan out FCM
/// push to app guardians and Twilio SMS to the rest.
///
/// Live location points are written as a subcollection the guardian app / web
/// track page listens to in real time.
class FirestoreAlertGateway implements AlertGateway {
  FirestoreAlertGateway({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('sosEvents');

  /// Public, capability-URL-scoped projection that the guardian web track page
  /// reads. Only the minimum needed to render a live map — never the full
  /// private event. The document id equals the event id (the opaque link).
  DocumentReference<Map<String, dynamic>> _publicTrack(String eventId) =>
      _db.collection('publicTracks').doc(eventId);

  @override
  Future<String> dispatch(
      SosEvent event, List<TrustedContact> contacts) async {
    final doc = await _events.add({
      ...event.toMap(),
      // Snapshot recipients so the function knows who to notify.
      'recipients': contacts
          .map((c) => {
                'name': c.name,
                'phone': c.phone,
                'hasApp': c.hasApp,
                'priority': c.priority,
              })
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  @override
  Future<void> pushLocation(String eventId, Position pos) async {
    await _events.doc(eventId).collection('track').add({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'speed': pos.speed,
      'ts': FieldValue.serverTimestamp(),
    });
    // Keep a denormalized "latest" on the event for quick reads.
    await _events.doc(eventId).set({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Mirror the latest point to the public track the web page listens to.
    await _publicTrack(eventId).set({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(String eventId, SosStatus status) async {
    await _events.doc(eventId).set({
      'status': status.name,
      'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Reflect resolution to the web page so it can stop and show "safe".
    await _publicTrack(eventId).set({
      'status': status.name,
      'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> attachMedia(String eventId, String type, String url) async {
    await _events.doc(eventId).collection('media').add({
      'type': type,
      'url': url,
      'ts': FieldValue.serverTimestamp(),
    });
    // Mirror to the public track so guardians can open the evidence.
    await _publicTrack(eventId).set({
      'media': FieldValue.arrayUnion([
        {'type': type, 'url': url}
      ]),
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<Ack>> watchAcks(String eventId) {
    return _events
        .doc(eventId)
        .collection('acks')
        .orderBy('at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Ack.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> acknowledge(String eventId, Ack ack) async {
    await _events.doc(eventId).collection('acks').add(ack.toMap());
    // Surface the latest response on the public track so the web page and the
    // person in distress can see help is coming.
    await _publicTrack(eventId).set({
      'lastAck': ack.toMap(),
    }, SetOptions(merge: true));
  }
}
