import 'package:flutter/material.dart';

import '../../core/services/account_service.dart';

/// Privacy & data controls (GDPR / India DPDP / CCPA). Explains what data is
/// collected and lets the user delete their account and all data.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, this.accountService});

  final AccountService? accountService;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('What we store', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            '• Your name and phone number (to identify you and your guardians).\n'
            '• Your trusted contacts.\n'
            '• Location only while an SOS or a live share is active — never in '
            'the background otherwise.\n'
            '• Optional audio/photo evidence you capture during an SOS.\n\n'
            'Location and media are shared only with the guardians you choose, '
            'through time-limited links that expire automatically.',
          ),
          const SizedBox(height: 24),
          Text('Your rights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'You can delete your account and all associated data at any time. '
            'This removes your profile, contacts, SOS history, live-share '
            'sessions, and any stored media — permanently.',
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.description_outlined),
            label: const Text('Read the full privacy policy'),
            onPressed: () {
              // Point at your hosted policy (Firebase Hosting / website).
              // launchUrl(Uri.parse('https://suraksha.app/privacy'));
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            icon: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.delete_forever),
            label: const Text('Delete my account & data'),
            onPressed: _busy ? null : _confirmDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
            'This permanently deletes your account and all your data. It '
            'cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await (widget.accountService ?? AccountService()).deleteAccountAndData();
      // Auth-state listener returns the app to the login screen.
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e. Try signing in again.')),
        );
      }
    }
  }
}
