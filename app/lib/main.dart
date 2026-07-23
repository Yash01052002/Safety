import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/console_alert_gateway.dart';
import 'core/services/location_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/sos/sos_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Phase 1: initialize Firebase here before runApp().
  //   await Firebase.initializeApp();
  // and swap ConsoleAlertGateway → FirestoreAlertGateway.
  runApp(const SurakshaApp());
}

class SurakshaApp extends StatelessWidget {
  const SurakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locationService = LocationService();
    final gateway = ConsoleAlertGateway();

    return ChangeNotifierProvider(
      create: (_) => SosController(
        gateway: gateway,
        locationService: locationService,
        // Phase 1: real user id from FirebaseAuth.
        currentUserId: 'dev-user',
      ),
      child: MaterialApp(
        title: 'Suraksha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
