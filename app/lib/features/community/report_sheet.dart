import 'package:flutter/material.dart';

import '../../core/models/safety_report.dart';

/// Result of the report sheet.
class ReportChoice {
  final SafetyCategory category;
  final String? note;
  const ReportChoice(this.category, this.note);
}

/// Bottom sheet to pick a safety category and add an optional note for the
/// currently-centred location.
class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  SafetyCategory? _selected;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How does this area feel?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Your report is anonymous to other users.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in SafetyCategory.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _selected == c,
                  avatar: Icon(
                    c.isPositive ? Icons.verified_user : Icons.warning_amber,
                    size: 18,
                    color: c.isPositive ? Colors.green : Colors.redAccent,
                  ),
                  onSelected: (_) => setState(() => _selected = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            maxLength: 200,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Add a note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(
                      context, ReportChoice(_selected!, _noteCtrl.text)),
              child: const Text('Submit report'),
            ),
          ),
        ],
      ),
    );
  }
}
