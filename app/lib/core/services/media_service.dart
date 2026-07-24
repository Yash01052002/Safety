import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Captures short evidence on an SOS — an audio clip, and optionally a photo —
/// and uploads it to Firebase Storage under the event, returning download URLs
/// the gateway attaches for guardians.
class MediaService {
  /// Record a short audio clip on SOS and upload it.
  ///
  /// Audio capture is currently disabled: the `record` plugin family ships
  /// mutually-incompatible federated packages (record_linux vs
  /// record_platform_interface) that fail the build. To re-enable, add a
  /// working recorder (e.g. a fixed `record` release, or `flutter_sound`) and
  /// restore the capture body — the call site already treats a null result as
  /// "no evidence", so nothing else needs to change. Photo capture is
  /// unaffected.
  Future<String?> recordAndUploadAudio({
    required String userId,
    required String eventId,
    int seconds = 20,
  }) async {
    return null;
  }

  /// Snap a single photo (front camera by default) and upload it.
  Future<String?> captureAndUploadPhoto({
    required String userId,
    required String eventId,
  }) async {
    try {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 60,
      );
      if (shot == null) return null;
      return _upload(
          userId, eventId, File(shot.path), 'photo.jpg', 'image/jpeg');
    } catch (e) {
      debugPrint('photo capture failed: $e');
      return null;
    }
  }

  Future<String?> _upload(String userId, String eventId, File file,
      String name, String contentType) async {
    final ref = FirebaseStorage.instance
        .ref('sosMedia/$userId/$eventId/$name');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
