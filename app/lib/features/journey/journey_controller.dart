import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/journey.dart';

/// Drives a monitored journey (safety timer). Ticks down to the deadline,
/// asks for a check-in shortly before it, and — if the deadline passes with no
/// check-in — invokes [onOverdue] once so the UI can auto-fire an SOS.
///
/// Timing lives here; the SOS trigger is injected so this stays decoupled from
/// the alert stack (and testable without it).
class JourneyController extends ChangeNotifier {
  /// Called exactly once when a journey goes overdue. Wired by the UI to the
  /// SOS trigger.
  VoidCallback? onOverdue;

  /// How long before the deadline to prompt for a check-in.
  final Duration checkInLead;

  JourneyController({this.checkInLead = const Duration(minutes: 2)});

  Journey? _journey;
  Journey? get journey => _journey;
  bool get isActive => _journey != null;

  bool _needsCheckIn = false;
  bool get needsCheckIn => _needsCheckIn;

  Timer? _ticker;

  void start({required Duration eta, String? destination}) {
    if (isActive) return;
    final now = DateTime.now();
    _journey = Journey(
      startedAt: now,
      deadline: now.add(eta),
      destination: destination,
    );
    _needsCheckIn = false;
    _startTicking();
    notifyListeners();
  }

  /// Push the deadline out (user needs more time).
  void extend(Duration by) {
    final j = _journey;
    if (j == null) return;
    _journey = j.copyWith(deadline: j.deadline.add(by));
    _needsCheckIn = false;
    notifyListeners();
  }

  /// Confirms the user is fine; clears the pending check-in prompt.
  void checkIn() {
    if (!isActive) return;
    _needsCheckIn = false;
    notifyListeners();
  }

  /// Ends the journey successfully (arrived safely).
  void arriveSafely() {
    _ticker?.cancel();
    _ticker = null;
    _journey = null;
    _needsCheckIn = false;
    notifyListeners();
  }

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final j = _journey;
      if (j == null) return;

      if (j.isOverdue) {
        _ticker?.cancel();
        _ticker = null;
        final j2 = _journey;
        _journey = null; // consume before firing so onOverdue can't re-enter
        _needsCheckIn = false;
        notifyListeners();
        if (j2 != null) onOverdue?.call();
        return;
      }

      final shouldPrompt = j.remaining <= checkInLead;
      if (shouldPrompt != _needsCheckIn) {
        _needsCheckIn = shouldPrompt;
      }
      notifyListeners(); // update the countdown display each tick
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
