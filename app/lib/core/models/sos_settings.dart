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

  /// Record short audio evidence on SOS and attach it for guardians.
  final bool captureAudioOnSos;

  /// Sound a loud siren + strobe the flashlight on SOS (opt-in; the inverse of
  /// stealth — use to attract attention / deter).
  final bool sirenOnSos;

  /// Minutes to wait for a guardian acknowledgment before escalating to the
  /// next-priority contact.
  final int escalationMinutes;

  const SosSettings({
    this.shakeEnabled = true,
    this.thresholdG = 2.7,
    this.requiredShakes = 3,
    this.countdownSeconds = 5,
    this.stealthMode = false,
    this.captureAudioOnSos = true,
    this.sirenOnSos = false,
    this.escalationMinutes = 3,
  });

  SosSettings copyWith({
    bool? shakeEnabled,
    double? thresholdG,
    int? requiredShakes,
    int? countdownSeconds,
    bool? stealthMode,
    bool? captureAudioOnSos,
    bool? sirenOnSos,
    int? escalationMinutes,
  }) {
    return SosSettings(
      shakeEnabled: shakeEnabled ?? this.shakeEnabled,
      thresholdG: thresholdG ?? this.thresholdG,
      requiredShakes: requiredShakes ?? this.requiredShakes,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      stealthMode: stealthMode ?? this.stealthMode,
      captureAudioOnSos: captureAudioOnSos ?? this.captureAudioOnSos,
      sirenOnSos: sirenOnSos ?? this.sirenOnSos,
      escalationMinutes: escalationMinutes ?? this.escalationMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'shakeEnabled': shakeEnabled,
        'thresholdG': thresholdG,
        'requiredShakes': requiredShakes,
        'countdownSeconds': countdownSeconds,
        'stealthMode': stealthMode,
        'captureAudioOnSos': captureAudioOnSos,
        'sirenOnSos': sirenOnSos,
        'escalationMinutes': escalationMinutes,
      };

  factory SosSettings.fromMap(Map<String, dynamic> map) {
    return SosSettings(
      shakeEnabled: map['shakeEnabled'] as bool? ?? true,
      thresholdG: (map['thresholdG'] as num?)?.toDouble() ?? 2.7,
      requiredShakes: (map['requiredShakes'] as num?)?.toInt() ?? 3,
      countdownSeconds: (map['countdownSeconds'] as num?)?.toInt() ?? 5,
      stealthMode: map['stealthMode'] as bool? ?? false,
      captureAudioOnSos: map['captureAudioOnSos'] as bool? ?? true,
      sirenOnSos: map['sirenOnSos'] as bool? ?? false,
      escalationMinutes: (map['escalationMinutes'] as num?)?.toInt() ?? 3,
    );
  }
}
