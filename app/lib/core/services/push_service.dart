import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles inbound FCM on the guardian's device: requests permission, and when
/// an SOS push is tapped, opens the sender's live-track link.
///
/// Foreground display uses the system tray via a high-priority channel; for a
/// custom in-app banner, pair with flutter_local_notifications (already a dep).
class PushService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Cold start: app opened by tapping the notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);

    // Warm start: app in background, notification tapped.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Foreground receipt — log for now; a banner can be shown here.
    FirebaseMessaging.onMessage.listen((m) {
      debugPrint('SOS push (foreground): ${m.notification?.title}');
    });
  }

  Future<void> _handleTap(RemoteMessage message) async {
    if (message.data['type'] != 'sos') return;
    final url = message.data['trackUrl'];
    if (url is String && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
