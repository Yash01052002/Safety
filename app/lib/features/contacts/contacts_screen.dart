import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

import '../../core/models/trusted_contact.dart';
import '../../core/repositories/contacts_repository.dart';

/// Manage trusted contacts (guardians): add from the phonebook or by hand,
/// reorder to set escalation priority, and remove.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key, required this.repo});

  final ContactsRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trusted contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addContact(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add'),
      ),
      body: StreamBuilder<List<TrustedContact>>(
        stream: repo.watch(),
        builder: (context, snap) {
          final contacts = snap.data ?? const [];
          if (contacts.isEmpty) {
            return const _EmptyState();
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: contacts.length,
            onReorder: (oldIndex, newIndex) {
              final list = [...contacts];
              if (newIndex > oldIndex) newIndex--;
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              repo.reorder(list);
            },
            itemBuilder: (context, i) {
              final c = contacts[i];
              return ListTile(
                key: ValueKey(c.id),
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(c.name),
                subtitle: Text(c.phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.hasApp)
                      const Tooltip(
                        message: 'Has the app — gets push alerts',
                        child: Icon(Icons.phone_iphone, size: 18),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => repo.remove(c.id),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addContact(BuildContext context) async {
    // Try the phonebook first; fall back to manual entry.
    if (await fc.FlutterContacts.requestPermission()) {
      final picked = await fc.FlutterContacts.openExternalPick();
      if (picked != null && picked.phones.isNotEmpty) {
        await repo.add(TrustedContact(
          id: '',
          name: picked.displayName,
          phone: picked.phones.first.number,
        ));
        return;
      }
    }
    if (context.mounted) await _manualEntry(context);
  }

  Future<void> _manualEntry(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Phone (+country code)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved == true && phoneCtrl.text.trim().isNotEmpty) {
      await repo.add(TrustedContact(
        id: '',
        name: nameCtrl.text.trim().isEmpty ? 'Contact' : nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      ));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Add the people you trust.\nThey\'ll be alerted with your live '
              'location when you send an SOS.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
