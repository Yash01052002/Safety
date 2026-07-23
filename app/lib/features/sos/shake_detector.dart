import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Detects a deliberate "shake" gesture from the accelerometer and fires a
/// callback. Tuned to reduce false positives (walking, pocket jostle) while
/// staying responsive in a panic.
///
/// Detection model: count discrete high-G "shakes" that occur within a short
/// rolling window. A single jolt won't trigger; a sustained shake will.
class ShakeDetector {
  /// Acceleration magnitude (in G, gravity subtracted) above which a single
  /// movement counts as a shake spike. Higher = harder shake required.
  /// Mutable so the calibration screen can tune it live.
  double thresholdG;

  /// Number of spikes required within [window] to fire. Mutable (live-tunable).
  int requiredShakes;

  /// Rolling window in which spikes must accumulate.
  final Duration window;

  /// Minimum gap between two counted spikes (debounce a single jerk).
  final Duration minSpikeGap;

  /// Cooldown after firing before it can fire again.
  final Duration cooldown;

  final void Function() onShake;

  /// Optional hook fired on every counted spike — used by the calibration
  /// screen to visualize sensitivity while the user test-shakes.
  void Function(int spikeCount)? onSpike;

  ShakeDetector({
    required this.onShake,
    this.onSpike,
    this.thresholdG = 2.7,
    this.requiredShakes = 3,
    this.window = const Duration(milliseconds: 1200),
    this.minSpikeGap = const Duration(milliseconds: 120),
    this.cooldown = const Duration(seconds: 3),
  });

  /// Apply new sensitivity without dropping the sensor subscription.
  void configure({double? thresholdG, int? requiredShakes}) {
    if (thresholdG != null) this.thresholdG = thresholdG;
    if (requiredShakes != null) this.requiredShakes = requiredShakes;
  }

  StreamSubscription<AccelerometerEvent>? _sub;
  final List<DateTime> _spikeTimes = [];
  DateTime? _lastSpike;
  DateTime? _firedAt;

  static const double _gravity = 9.80665;

  void start() {
    _sub ??= accelerometerEventStream().listen(_onEvent);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _spikeTimes.clear();
    _lastSpike = null;
  }

  void _onEvent(AccelerometerEvent e) {
    // Magnitude of acceleration with gravity removed, expressed in G.
    final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    final gForce = (magnitude - _gravity).abs() / _gravity;

    if (gForce < thresholdG) return;

    final now = DateTime.now();

    // Still cooling down from a previous fire.
    if (_firedAt != null && now.difference(_firedAt!) < cooldown) return;

    // Debounce spikes that are too close together (one physical jerk).
    if (_lastSpike != null && now.difference(_lastSpike!) < minSpikeGap) return;

    _lastSpike = now;
    _spikeTimes.add(now);

    // Drop spikes older than the rolling window.
    _spikeTimes.removeWhere((t) => now.difference(t) > window);
    onSpike?.call(_spikeTimes.length);

    if (_spikeTimes.length >= requiredShakes) {
      _spikeTimes.clear();
      _firedAt = now;
      onShake();
    }
  }
}
