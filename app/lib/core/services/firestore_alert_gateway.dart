import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

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
  }

  @override
  Future<void> updateStatus(String eventId, SosStatus status) async {
    await _events.doc(eventId).set({
      'status': status.name,
      'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
