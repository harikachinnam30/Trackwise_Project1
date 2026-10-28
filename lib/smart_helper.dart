class HabitSuggestion {
  final int target;
  final String reason;
  const HabitSuggestion(this.target, this.reason);
}

/// Rule-based recommendation, not a trained machine-learning model.
HabitSuggestion recommendTarget(List<int> recentProgress, int currentTarget) {
  if (currentTarget < 1 || currentTarget > 100) throw ArgumentError('Invalid target');
  if (recentProgress.isEmpty) return HabitSuggestion(currentTarget, 'No history yet; keep your chosen target.');
  if (recentProgress.any((p) => p < 0 || p > 100)) throw ArgumentError('Invalid history');
  final recent = recentProgress.take(3).toList();
  final average = recent.reduce((a,b) => a+b) / recent.length;
  final next = average >= 80 ? (currentTarget + 5).clamp(1,100) : average < 40 ? (currentTarget - 5).clamp(1,100) : currentTarget;
  return HabitSuggestion(next.toInt(), 'Last ${recent.length} progress values averaged ${average.toStringAsFixed(0)}%; suggested target $next.');
}

int baselineTarget(int currentTarget) => currentTarget;
