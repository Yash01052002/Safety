import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'journey_controller.dart';

/// Home-screen card to start / monitor a "get me there safely" journey. Hidden
/// in dev mode where no [JourneyController] is provided.
class JourneyCard extends StatelessWidget {
  const JourneyCard({super.key});

  JourneyController? _controller(BuildContext context) {
    try {
      return Provider.of<JourneyController>(context);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller(context);
    if (controller == null) return const SizedBox.shrink();

    if (controller.isActive) {
      return _JourneyActive(controller: controller);
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.timer_outlined, color: Color(0xFF2E7D32)),
        title: const Text('Get me there safely'),
        subtitle: const Text("Auto-alert guardians if you don't arrive in time"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pickEta(context, controller),
      ),
    );
  }

  Future<void> _pickEta(
      BuildContext context, JourneyController controller) async {
    const options = <String, Duration>{
      '15 minutes': Duration(minutes: 15),
      '30 minutes': Duration(minutes: 30),
      '1 hour': Duration(hours: 1),
      '2 hours': Duration(hours: 2),
    };
    final eta = await showModalBottomSheet<Duration>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('I should arrive within…',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            for (final entry in options.entries)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(entry.key),
                onTap: () => Navigator.pop(ctx, entry.value),
              ),
          ],
        ),
      ),
    );
    if (eta != null) controller.start(eta: eta);
  }
}

class _JourneyActive extends StatelessWidget {
  const _JourneyActive({required this.controller});
  final JourneyController controller;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final j = controller.journey!;
    final remaining = j.remaining;
    final prompt = controller.needsCheckIn;

    return Card(
      color: (prompt ? AppTheme.emergencyRed : AppTheme.safeGreen)
          .withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: prompt ? AppTheme.emergencyRed : AppTheme.safeGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt ? 'Almost due — are you safe?' : 'Journey in progress',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  remaining.isNegative ? '00:00' : _fmt(remaining),
                  style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_alarm),
                    label: const Text('+15 min'),
                    onPressed: () =>
                        controller.extend(const Duration(minutes: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.safeGreen),
                    icon: const Icon(Icons.check),
                    label: const Text("I've arrived"),
                    onPressed: controller.arriveSafely,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
