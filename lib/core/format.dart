/// Human formatting: runtimes, relative snapshot times, counts.
///
/// Snapshot times render the way the V7 screens show them — "Today 09:41",
/// "Yesterday 18:02", "2 days ago 17:44" — computed from real timestamps,
/// never invented.
library;

/// Formats a runtime in seconds as "3:48".
String formatDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Formats a signed runtime delta in seconds as "+14s" / "−17s" / "±0s".
String formatRuntimeDelta(int deltaSeconds) {
  if (deltaSeconds == 0) return '±0s';
  if (deltaSeconds > 0) return '+${deltaSeconds}s';
  return '−${-deltaSeconds}s';
}

/// Clock time as "09:41".
String formatClock(DateTime at) {
  final h = at.hour.toString().padLeft(2, '0');
  final m = at.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Relative day label: "Today 09:41", "Yesterday 18:02", "2 days ago 17:44".
String formatRelative(DateTime at, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final dayStart = DateTime(current.year, current.month, current.day);
  final atDay = DateTime(at.year, at.month, at.day);
  final days = dayStart.difference(atDay).inDays;
  final clock = formatClock(at);
  if (days <= 0) return 'Today $clock';
  if (days == 1) return 'Yesterday $clock';
  return '$days days ago $clock';
}

/// Short relative label without the clock: "Today", "Yesterday", "3 days ago".
String formatRelativeDay(DateTime at, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final dayStart = DateTime(current.year, current.month, current.day);
  final atDay = DateTime(at.year, at.month, at.day);
  final days = dayStart.difference(atDay).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '$days days ago';
}

/// "1 snapshot" / "9 snapshots".
String plural(int count, String singular, [String? pluralForm]) {
  if (count == 1) return '1 $singular';
  return '$count ${pluralForm ?? '${singular}s'}';
}
