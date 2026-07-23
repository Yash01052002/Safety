import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/contacts_repository.dart';
import '../../core/repositories/live_share_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_alert_gateway.dart';
import '../../core/services/location_service.dart';
import '../../core/services/push_service.dart';
import '../../features/home/home_screen.dart';
import '../../features/journey/journey_controller.dart';
import '../../features/live/live_share_controller.dart';
import '../../features/sos/sos_service.dart';
import 'login_screen.dart';

/// Routes between the login screen and the authenticated app based on Firebase
/// auth state, and provides per-user services (SOS controller, contacts repo)
/// once signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authState(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          return LoginScreen(auth: auth);
        }
        return _AuthedScope(userId: user.uid);
      },
    );
  }
}

class _AuthedScope extends StatefulWidget {
  const _AuthedScope({required this.userId});
  final String userId;

  @override
  State<_AuthedScope> createState() => _AuthedScopeState();
}

class _AuthedScopeState extends State<_AuthedScope> {
  @override
  void initState() {
    super.initState();
    // Start listening for inbound SOS pushes (this user acting as a guardian).
    PushService().init();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final locationService = LocationService();
    return MultiProvider(
      providers: [
        Provider<ContactsRepository>(
          create: (_) => ContactsRepository(userId: userId),
        ),
        ChangeNotifierProvider<SosController>(
          create: (_) => SosController(
            gateway: FirestoreAlertGateway(),
            locationService: locationService,
            currentUserId: userId,
          ),
        ),
        ChangeNotifierProvider<LiveShareController>(
          create: (_) => LiveShareController(
            repo: LiveShareRepository(userId: userId),
            locationService: locationService,
          ),
        ),
        ChangeNotifierProvider<JourneyController>(
          create: (_) => JourneyController(),
        ),
      ],
      child: const HomeScreen(),
    );
  }
}
