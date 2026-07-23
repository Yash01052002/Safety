import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/features/journey/journey_controller.dart';

void main() {
  test('start activates a journey with a future deadline', () {
    final c = JourneyController();
    addTearDown(c.dispose);
    c.start(eta: const Duration(minutes: 30));
    expect(c.isActive, isTrue);
    expect(c.journey!.remaining.inMinutes, greaterThan(25));
    expect(c.journey!.isOverdue, isFalse);
  });

  test('extend pushes the deadline out and clears the check-in prompt', () {
    final c = JourneyController();
    addTearDown(c.dispose);
    c.start(eta: const Duration(minutes: 1));
    final before = c.journey!.deadline;
    c.extend(const Duration(minutes: 15));
    expect(c.journey!.deadline.isAfter(before), isTrue);
    expect(c.needsCheckIn, isFalse);
  });

  test('arriveSafely ends the journey', () {
    final c = JourneyController();
    addTearDown(c.dispose);
    c.start(eta: const Duration(minutes: 10));
    c.arriveSafely();
    expect(c.isActive, isFalse);
    expect(c.journey, isNull);
  });

  test('starting twice is a no-op while one is active', () {
    final c = JourneyController();
    addTearDown(c.dispose);
    c.start(eta: const Duration(minutes: 10));
    final first = c.journey!.deadline;
    c.start(eta: const Duration(hours: 5));
    expect(c.journey!.deadline, first);
  });
}
