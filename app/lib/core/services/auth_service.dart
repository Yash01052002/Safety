import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_user.dart';

/// Phone-number (OTP) authentication + user profile, backed by Firebase Auth
/// and Firestore. Phone identity fits the trusted-contacts model where
/// guardians are addressed by number.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authState() => _auth.authStateChanges();
  User? get current => _auth.currentUser;

  /// Kick off phone verification. On most Android devices [onVerified] may fire
  /// automatically (instant verification); otherwise [onCodeSent] provides a
  /// verificationId to pair with the SMS code in [confirmCode].
  Future<void> startPhoneAuth({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(UserCredential cred) onVerified,
    required void Function(FirebaseAuthException e) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (cred) async {
        final result = await _auth.signInWithCredential(cred);
        onVerified(result);
      },
      verificationFailed: onError,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Complete manual OTP entry.
  Future<UserCredential> confirmCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Create the profile document on first sign-in and register this device's
  /// FCM token so the user can also receive guardian acknowledgments.
  Future<AppUser> ensureProfile({required String name, String? medicalNote}) async {
    final user = _auth.currentUser!;
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      final profile = AppUser(
        id: user.uid,
        phone: user.phoneNumber ?? '',
        name: name,
        medicalNote: medicalNote,
        createdAt: DateTime.now(),
      );
      await ref.set(profile.toMap());
    }
    await _registerToken(ref);
    return AppUser.fromMap(user.uid, (await ref.get()).data()!);
  }

  Future<void> _registerToken(DocumentReference ref) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.set({'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (_) {
      // Non-fatal: user can still send alerts, just won't receive push.
    }
  }

  Future<void> signOut() => _auth.signOut();
}
