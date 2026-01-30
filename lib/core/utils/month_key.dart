String monthKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$y-$m'; // e.g. 2026-01
}

DateTime firstDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

DateTime firstDayOfNextMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 1);
}