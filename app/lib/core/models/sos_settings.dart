/// User-tunable settings for shake-to-alert and SOS behavior.
class SosSettings {
  /// Whether shake-to-alert is armed.
  final bool shakeEnabled;

  /// Acceleration spike threshold in G. Lower = more sensitive (easier to
  /// trigger, more false positives). Typical range 2.0–3.5.
  final double thresholdG;

  /// Number of spikes required within the detection window to fire.
  final int requiredShakes;

  /// Seconds of cancellable countdown before the alert actually sends.
  final int countdownSeconds;

  /// Stealth mode: skip the countdown and any visible confirmation, so an
  /// attacker can't see (or cancel) the alert. Used when openly cancelling is
  /// unsafe.
  final bool stealthMode;

  const SosSettings({
    this.shakeEnabled = true,
    this.thresholdG = 2.7,
    this.requiredShakes = 3,
    this.countdownSeconds = 5,
    this.stealthMode = false,
  });

  SosSettings copyWith({
    bool? shakeEnabled,
    double? thresholdG,
    int? requiredShakes,
    int? countdownSeconds,
    bool? stealthMode,
  }) {
    return SosSettings(
      shakeEnabled: shakeEnabled ?? this.shakeEnabled,
      thresholdG: thresholdG ?? this.thresholdG,
      requiredShakes: requiredShakes ?? this.requiredShakes,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      stealthMode: stealthMode ?? this.stealthMode,
    );
  }

  Map<String, dynamic> toMap() => {
        'shakeEnabled': shakeEnabled,
        'thresholdG': thresholdG,
        'requiredShakes': requiredShakes,
        'countdownSeconds': countdownSeconds,
        'stealthMode': stealthMode,
      };

  factory SosSettings.fromMap(Map<String, dynamic> map) {
    return SosSettings(
      shakeEnabled: map['shakeEnabled'] as bool? ?? true,
      thresholdG: (map['thresholdG'] as num?)?.toDouble() ?? 2.7,
      requiredShakes: (map['requiredShakes'] as num?)?.toInt() ?? 3,
      countdownSeconds: (map['countdownSeconds'] as num?)?.toInt() ?? 5,
      stealthMode: map['stealthMode'] as bool? ?? false,
    );
  }
}
