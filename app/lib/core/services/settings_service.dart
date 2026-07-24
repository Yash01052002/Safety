import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sos_settings.dart';

/// Persists [SosSettings] locally (SharedPreferences) and exposes them as a
/// [ChangeNotifier] so the shake detector and UI react to changes live.
///
/// Stored under a single JSON key so the background isolate can read the same
/// value with one lookup.
class SettingsService extends ChangeNotifier {
  static const _key = 'sos_settings_v1';

  SosSettings _settings = const SosSettings();
  SosSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _settings = SosSettings.fromMap(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {/* keep defaults on corrupt data */}
    }
    notifyListeners();
  }

  Future<void> update(SosSettings next) async {
    _settings = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(next.toMap()));
  }

  /// Read the persisted settings without a notifier — for the background
  /// isolate, which has no access to the app's provider tree.
  static Future<SosSettings> readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const SosSettings();
    try {
      return SosSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const SosSettings();
    }
  }
}
