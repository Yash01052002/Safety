import 'package:flutter/foundation.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';

/// Always-listening wake-word trigger using on-device keyword spotting
/// (Picovoice Porcupine). Detection runs entirely on-device — no audio leaves
/// the phone — but it is still opt-in and gated behind a privacy disclosure
/// because it keeps the microphone active.
///
/// Requires a Picovoice access key (compile-time `--dart-define
/// PICOVOICE_ACCESS_KEY=...`) and a trained keyword file bundled as an asset.
/// If either is missing the service reports [isConfigured] == false and does
/// nothing, so the rest of the app is unaffected.
class VoiceTriggerService {
  VoiceTriggerService({
    required this.accessKey,
    this.keywordAssetPath = 'assets/hey_suraksha.ppn',
  });

  final String accessKey;
  final String keywordAssetPath;

  PorcupineManager? _manager;
  bool _listening = false;

  bool get isConfigured => accessKey.isNotEmpty;
  bool get isListening => _listening;

  /// Start listening. [onWake] fires when the wake word is detected. Returns
  /// false if unconfigured or if the engine failed to start (e.g. missing
  /// keyword asset, mic permission denied) — callers should surface that so the
  /// setting can be reverted.
  Future<bool> start(void Function() onWake) async {
    if (!isConfigured || _listening) return _listening;
    try {
      _manager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        [keywordAssetPath],
        (_) => onWake(),
        errorCallback: (e) => debugPrint('Porcupine error: ${e.message}'),
      );
      await _manager!.start();
      _listening = true;
      return true;
    } on PorcupineException catch (e) {
      debugPrint('Voice trigger start failed: ${e.message}');
      await _cleanup();
      return false;
    } catch (e) {
      debugPrint('Voice trigger start failed: $e');
      await _cleanup();
      return false;
    }
  }

  Future<void> stop() async {
    if (!_listening) return;
    await _cleanup();
  }

  Future<void> _cleanup() async {
    try {
      await _manager?.stop();
    } catch (_) {}
    try {
      await _manager?.delete();
    } catch (_) {}
    _manager = null;
    _listening = false;
  }

  void dispose() {
    _cleanup();
  }
}
