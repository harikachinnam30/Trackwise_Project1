import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_league/streaks.dart';

Map<String, Object?> record(int id, String date, {bool complete = true}) => {
  'habit_id': id, 'created_at': '${date}T12:00:00', 'completed': complete ? 1 : 0,
};

void main() {
  test('empty history has zero streak', () {
    final s = calculateStreak([], now: DateTime(2026, 10, 27));
    expect(s.current, 0); expect(s.longest, 0);
  });
  test('consecutive completions count one per day', () {
    final s = calculateStreak([
      record(1, '2026-10-25'), record(1, '2026-10-26'),
      record(1, '2026-10-26'), record(1, '2026-10-27'),
    ], now: DateTime(2026, 10, 27));
    expect(s.current, 3); expect(s.longest, 3);
  });
  test('yesterday streak remains active until end of today', () {
    final s = calculateStreak([record(1, '2026-10-26')], now: DateTime(2026, 10, 27));
    expect(s.current, 1);
  });
  test('missed day breaks current streak but preserves best', () {
    final s = calculateStreak([
      record(1, '2026-10-20'), record(1, '2026-10-21'), record(1, '2026-10-22'),
      record(1, '2026-10-26'),
    ], now: DateTime(2026, 10, 27));
    expect(s.current, 1); expect(s.longest, 3);
  });
  test('incomplete records are excluded', () {
    final s = calculateStreak([record(1, '2026-10-27', complete: false)], now: DateTime(2026, 10, 27));
    expect(s.current, 0);
  });
  test('habit-specific streak ignores other habits', () {
    final s = calculateStreak([record(1, '2026-10-26'), record(2, '2026-10-27')], habitId: 1, now: DateTime(2026, 10, 27));
    expect(s.current, 1);
  });
}
