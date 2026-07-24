import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/sos_settings.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../sos/shake_detector.dart';

/// Lets the user calibrate shake sensitivity with live feedback, and set the
/// cancel-countdown and stealth behavior.
class ShakeSettingsScreen extends StatefulWidget {
  const ShakeSettingsScreen({super.key});

  @override
  State<ShakeSettingsScreen> createState() => _ShakeSettingsScreenState();
}

class _ShakeSettingsScreenState extends State<ShakeSettingsScreen> {
  late ShakeDetector _tester;
  int _spikes = 0;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsService>().settings;
    _tester = ShakeDetector(
      thresholdG: s.thresholdG,
      requiredShakes: s.requiredShakes,
      onSpike: (count) => setState(() {
        _spikes = count;
        _fired = false;
      }),
      onShake: () => setState(() {
        _fired = true;
        _spikes = 0;
      }),
    )..start();
  }

  @override
  void dispose() {
    _tester.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    final s = service.settings;

    void save(SosSettings next) {
      service.update(next);
      _tester.configure(
        thresholdG: next.thresholdG,
        requiredShakes: next.requiredShakes,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shake to alert')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TestMeter(spikes: _spikes, needed: s.requiredShakes, fired: _fired),
          const SizedBox(height: 24),

          Text('Sensitivity', style: Theme.of(context).textTheme.titleMedium),
          Text(
            'Lower threshold = easier to trigger (but more false alarms). '
            'Test by shaking your phone above.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            value: s.thresholdG,
            min: 1.8,
            max: 3.6,
            divisions: 18,
            label: s.thresholdG.toStringAsFixed(1),
            onChanged: (v) => save(s.copyWith(thresholdG: v)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('More sensitive'),
              Text('Firmer shake'),
            ],
          ),
          const SizedBox(height: 16),

          Text('Shakes required: ${s.requiredShakes}',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: s.requiredShakes.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            label: '${s.requiredShakes}',
            onChanged: (v) => save(s.copyWith(requiredShakes: v.round())),
          ),
          const Divider(height: 32),

          Text('When triggered', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cancel countdown'),
            subtitle: Text('${s.countdownSeconds} seconds to cancel a false alarm'),
            trailing: SizedBox(
              width: 160,
              child: Slider(
                value: s.countdownSeconds.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                label: '${s.countdownSeconds}s',
                onChanged: (v) =>
                    save(s.copyWith(countdownSeconds: v.round())),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Stealth mode'),
            subtitle: const Text(
                'Send instantly with no visible countdown — for when it isn\'t '
                'safe to show the screen.'),
            value: s.stealthMode,
            onChanged: (v) => save(s.copyWith(stealthMode: v)),
          ),
          const Divider(height: 32),

          Text('During an emergency',
              style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Record audio evidence'),
            subtitle: const Text(
                'Capture a short audio clip on SOS and attach it for guardians.'),
            value: s.captureAudioOnSos,
            onChanged: (v) => save(s.copyWith(captureAudioOnSos: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Siren + flashlight strobe'),
            subtitle: const Text(
                'Draw attention on SOS. Ignored in stealth mode.'),
            value: s.sirenOnSos,
            onChanged: (v) => save(s.copyWith(sirenOnSos: v)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Escalate if unanswered'),
            subtitle: Text(
                'Notify the next contact after ${s.escalationMinutes} min '
                'with no response.'),
            trailing: SizedBox(
              width: 160,
              child: Slider(
                value: s.escalationMinutes.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '${s.escalationMinutes} min',
                onChanged: (v) =>
                    save(s.copyWith(escalationMinutes: v.round())),
              ),
            ),
          ),
          const Divider(height: 32),

          Text('Voice trigger', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Say a wake word to trigger'),
            subtitle: const Text(
                'Listens on-device for a wake word so you can trigger hands-'
                'free. Recognition happens entirely on your phone — no audio is '
                'recorded or sent. Uses the microphone and more battery.'),
            value: s.voiceTriggerEnabled,
            onChanged: (v) async {
              if (!v) {
                save(s.copyWith(voiceTriggerEnabled: false));
                return;
              }
              final ok = await _confirmVoiceConsent();
              if (ok) save(s.copyWith(voiceTriggerEnabled: true));
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmVoiceConsent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn on voice trigger?'),
        content: const Text(
            'To listen for your wake word, the app keeps the microphone active '
            'and analyses sound on your device. No audio is stored or sent '
            'anywhere. You can turn this off at any time.\n\n'
            'This uses extra battery and needs microphone permission.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable')),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _TestMeter extends StatelessWidget {
  const _TestMeter(
      {required this.spikes, required this.needed, required this.fired});
  final int spikes;
  final int needed;
  final bool fired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fired
            ? AppTheme.emergencyRed.withOpacity(0.12)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            fired ? 'Would trigger SOS ✓' : 'Test your shake',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: fired ? AppTheme.emergencyRed : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(needed, (i) {
              final on = i < spikes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  on ? Icons.circle : Icons.circle_outlined,
                  color: on ? AppTheme.emergencyRed : Colors.grey,
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
