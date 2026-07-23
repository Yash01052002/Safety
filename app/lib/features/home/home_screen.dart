import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/sos_event.dart';
import '../../core/models/trusted_contact.dart';
import '../../core/repositories/contacts_repository.dart';
import '../../core/theme/app_theme.dart';
import '../contacts/contacts_screen.dart';
import '../sos/shake_detector.dart';
import '../sos/sos_button.dart';
import '../sos/sos_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ShakeDetector _shake;
  bool _shakeEnabled = true;

  /// Live guardians. Populated from Firestore when a ContactsRepository is
  /// provided (authenticated build); falls back to a dev placeholder otherwise.
  List<TrustedContact> _contacts = const [
    TrustedContact(id: '1', name: 'Mom', phone: '+10000000000', priority: 0),
  ];

  ContactsRepository? get _repo {
    // Optional: absent in dev mode (no Firebase / no provider registered).
    try {
      return Provider.of<ContactsRepository>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _shake = ShakeDetector(onShake: _onShake);
    if (_shakeEnabled) _shake.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = _repo;
    if (repo != null) {
      repo.watch().listen((list) {
        if (mounted) setState(() => _contacts = list);
      });
    }
  }

  void _onShake() {
    final sos = context.read<SosController>();
    // Shake fires with a short countdown so a genuine accident can be cancelled.
    sos.trigger(SosTrigger.shake, _contacts, countdownSeconds: 5);
  }

  @override
  void dispose() {
    _shake.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suraksha'),
        actions: [
          Row(
            children: [
              const Icon(Icons.vibration, size: 18),
              Switch(
                value: _shakeEnabled,
                onChanged: (v) {
                  setState(() => _shakeEnabled = v);
                  v ? _shake.start() : _shake.stop();
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Trusted contacts',
            onPressed: () {
              final repo = _repo;
              if (repo == null) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ContactsScreen(repo: repo),
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: sos.isCountingDown
              ? _CountdownView(remaining: sos.countdownRemaining)
              : sos.isActive
                  ? _ActiveView(event: sos.active!)
                  : _IdleView(contacts: _contacts),
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.contacts});
  final List<TrustedContact> contacts;

  @override
  Widget build(BuildContext context) {
    final sos = context.read<SosController>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SosButton(
          onTriggered: () => sos.trigger(SosTrigger.manual, contacts),
        ),
        const SizedBox(height: 32),
        Text('Shake your phone or hold the button to alert your guardians.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Text('${contacts.length} trusted contact(s) configured',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CountdownView extends StatelessWidget {
  const _CountdownView({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final sos = context.read<SosController>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$remaining',
            style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w900,
                color: AppTheme.emergencyRed)),
        const Text('Sending SOS…', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: sos.cancelCountdown,
          child: const Text("I'm safe — cancel"),
        ),
      ],
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.event});
  final SosEvent event;

  @override
  Widget build(BuildContext context) {
    final sos = context.read<SosController>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_tethering,
            color: AppTheme.emergencyRed, size: 72),
        const SizedBox(height: 16),
        Text('SOS ACTIVE',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppTheme.emergencyRed)),
        const SizedBox(height: 8),
        const Text('Your live location is being shared with your guardians.',
            textAlign: TextAlign.center),
        if (event.lat != null && event.lng != null) ...[
          const SizedBox(height: 8),
          Text('Last: ${event.lat!.toStringAsFixed(4)}, '
              '${event.lng!.toStringAsFixed(4)}'),
        ],
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.safeGreen),
          onPressed: sos.resolve,
          child: const Text("I'm safe now — stop sharing"),
        ),
      ],
    );
  }
}
