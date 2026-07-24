import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Account & data controls required for privacy compliance (GDPR / India DPDP /
/// CCPA): the user can delete their account and all associated data.
///
/// The heavy lifting (subcollections, Storage media, public tracks) runs
/// server-side in the `deleteUserData` callable so nothing is orphaned; the
/// client then removes the auth account and signs out.
class AccountService {
  Future<void> deleteAccountAndData() async {
    // Purge Firestore + Storage data with admin privileges.
    await FirebaseFunctions.instance.httpsCallable('deleteUserData').call();

    // Remove the auth identity. May require a recent sign-in; callers should
    // handle FirebaseAuthException('requires-recent-login') by re-authing.
    await FirebaseAuth.instance.currentUser?.delete();
    await FirebaseAuth.instance.signOut();
  }
}
