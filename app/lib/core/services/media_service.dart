import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Captures short evidence on an SOS — an audio clip, and optionally a photo —
/// and uploads it to Firebase Storage under the event, returning download URLs
/// the gateway attaches for guardians.
class MediaService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Record [seconds] of audio, upload it, and return its download URL.
  /// Silent on any failure — evidence is best-effort and must never block the
  /// alert itself.
  Future<String?> recordAndUploadAudio({
    required String userId,
    required String eventId,
    int seconds = 20,
  }) async {
    try {
      if (!await _recorder.hasPermission()) return null;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/sos_$eventId.m4a';

      await _recorder.start(const RecordConfig(), path: path);
      await Future.delayed(Duration(seconds: seconds));
      final result = await _recorder.stop();
      if (result == null) return null;

      return _upload(userId, eventId, File(result), 'audio.m4a', 'audio/mp4');
    } catch (e) {
      debugPrint('audio capture failed: $e');
      return null;
    }
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
