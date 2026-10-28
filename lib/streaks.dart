/// Calendar-day streaks based on completed activity records.
/// One or more completions on the same day count only once.
class StreakStats {
  final int current;
  final int longest;
  final Set<String> completedDays;
  const StreakStats(this.current, this.longest, this.completedDays);
}

String dayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

StreakStats calculateStreak(List<Map<String, Object?>> activities, {int? habitId, DateTime? now}) {
  final today = DateTime(now?.year ?? DateTime.now().year, now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
  final days = <DateTime>{};
  for (final activity in activities) {
    if (activity['completed'] != 1 || (habitId != null && activity['habit_id'] != habitId)) continue;
    final parsed = DateTime.tryParse('${activity['created_at'] ?? ''}')?.toLocal();
    if (parsed == null) continue;
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    if (!date.isAfter(today)) days.add(date);
  }
  if (days.isEmpty) return const StreakStats(0, 0, {});
  final sorted = days.toList()..sort();
  int longest = 1, run = 1;
  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i].difference(sorted[i - 1]).inDays == 1) { run++; } else { run = 1; }
    if (run > longest) longest = run;
  }
  var cursor = days.contains(today) ? today : today.subtract(const Duration(days: 1));
  var current = 0;
  while (days.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return StreakStats(current, longest, days.map(dayKey).toSet());
}
