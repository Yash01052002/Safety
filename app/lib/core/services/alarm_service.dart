import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';

/// Loud, attention-grabbing response for an SOS: a looping siren plus a
/// strobing flashlight. Opt-in (the inverse of stealth mode) — used to deter an
/// attacker or draw help from nearby people.
class AlarmService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _strobe;
  bool _torchOn = false;
  bool get isActive => _strobe != null;

  /// Start the siren + strobe. [sirenAsset] must be bundled in assets (declared
  /// in pubspec under `flutter/assets`).
  Future<void> start({String sirenAsset = 'assets/siren.mp3'}) async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(sirenAsset.replaceFirst('assets/', '')));
    } catch (e) {
      debugPrint('siren failed: $e');
    }
    _startStrobe();
  }

  void _startStrobe() {
    _strobe?.cancel();
    _strobe = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      try {
        _torchOn ? await TorchLight.disableTorch() : await TorchLight.enableTorch();
        _torchOn = !_torchOn;
      } catch (_) {
        // No torch on this device — siren alone still runs.
      }
    });
  }

  Future<void> stop() async {
    _strobe?.cancel();
    _strobe = null;
    try {
      await _player.stop();
      if (_torchOn) {
        await TorchLight.disableTorch();
        _torchOn = false;
      }
    } catch (_) {}
  }

  void dispose() {
    _strobe?.cancel();
    _player.dispose();
  }
}
