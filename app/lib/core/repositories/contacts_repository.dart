import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trusted_contact.dart';

/// CRUD for a user's trusted contacts, stored under
/// `users/{uid}/contacts/{contactId}` in Firestore.
class ContactsRepository {
  ContactsRepository({required this.userId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(userId).collection('contacts');

  /// Live stream of contacts ordered by escalation priority.
  Stream<List<TrustedContact>> watch() {
    return _col.orderBy('priority').snapshots().map(
          (snap) => snap.docs
              .map((d) => TrustedContact.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<TrustedContact>> fetch() async {
    final snap = await _col.orderBy('priority').get();
    return snap.docs
        .map((d) => TrustedContact.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> add(TrustedContact contact) async {
    await _col.add(contact.toMap());
  }

  Future<void> update(TrustedContact contact) async {
    await _col.doc(contact.id).set(contact.toMap());
  }

  Future<void> remove(String contactId) async {
    await _col.doc(contactId).delete();
  }

  /// Persist a reordered list, writing each item's new priority index.
  Future<void> reorder(List<TrustedContact> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.set(
        _col.doc(ordered[i].id),
        {'priority': i},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
