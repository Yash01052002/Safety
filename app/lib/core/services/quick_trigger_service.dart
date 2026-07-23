import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

/// Alternative ways to fire an SOS without opening the app to the home screen —
/// important because iOS can't reliably shake-trigger when the app is killed.
///
///  • **Quick Action**: long-press the app icon → "Send SOS" (both platforms).
///  • **Deep link** `suraksha://sos`: invokable by an iOS **Shortcut**, which
///    the user can bind to the **Action Button**, **Back Tap**, a **lock-screen
///    / Control Center widget**, or **"Hey Siri, send SOS"**. On Android the
///    same link backs an app shortcut / assistant action.
///
/// All paths converge on [onTrigger].
class QuickTriggerService {
  QuickTriggerService({required this.onTrigger});

  /// Called when any fallback fires an SOS.
  final void Function() onTrigger;

  final QuickActions _quickActions = const QuickActions();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  Future<void> init() async {
    // Home-screen long-press shortcut.
    await _quickActions.initialize((type) {
      if (type == 'action_sos') onTrigger();
    });
    await _quickActions.setShortcutItems(const [
      // Add a platform icon resource named 'ic_sos' and set `icon: 'ic_sos'`
      // to customize; omitted here so a missing asset can't crash startup.
      ShortcutItem(type: 'action_sos', localizedTitle: 'Send SOS'),
    ]);

    // Cold start via deep link (e.g. Shortcut launched the app).
    final initial = await _appLinks.getInitialLink();
    if (_isSosLink(initial)) onTrigger();

    // Deep links while running.
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (_isSosLink(uri)) onTrigger();
    }, onError: (e) => debugPrint('deep link error: $e'));
  }

  bool _isSosLink(Uri? uri) =>
      uri != null && uri.scheme == 'suraksha' && uri.host == 'sos';

  void dispose() => _linkSub?.cancel();
}
