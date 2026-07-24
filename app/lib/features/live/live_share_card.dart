import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/live_session.dart';
import 'guardian_map_screen.dart';
import 'live_share_controller.dart';

/// Home-screen card to start/stop a proactive live-location share. Hidden in
/// dev mode where no [LiveShareController] is provided.
class LiveShareCard extends StatelessWidget {
  const LiveShareCard({super.key});

  LiveShareController? _controller(BuildContext context) {
    try {
      return Provider.of<LiveShareController>(context);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller(context);
    if (controller == null) return const SizedBox.shrink();

    if (controller.isSharing) {
      return _SharingActive(controller: controller);
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.share_location, color: Color(0xFF2E7D32)),
        title: const Text('Share live location'),
        subtitle: const Text('Let a guardian follow your trip'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pickDuration(context, controller),
      ),
    );
  }

  Future<void> _pickDuration(
      BuildContext context, LiveShareController controller) async {
    final choice = await showModalBottomSheet<ShareDuration>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Share for how long?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            for (final d in ShareDuration.values)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(d.label),
                onTap: () => Navigator.pop(ctx, d),
              ),
          ],
        ),
      ),
    );
    if (choice != null) await controller.start(choice);
  }
}

class _SharingActive extends StatelessWidget {
  const _SharingActive({required this.controller});
  final LiveShareController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session!;
    final remaining = session.remaining;
    return Card(
      color: const Color(0xFF2E7D32).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.share_location, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Sharing live location',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                if (remaining != null)
                  Text('${remaining.inMinutes} min left'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Preview'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GuardianMapScreen(trackId: session.id),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    onPressed: controller.stop,
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
