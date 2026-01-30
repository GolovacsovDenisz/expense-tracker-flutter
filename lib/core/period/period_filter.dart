enum PeriodType { allTime, year, month, day }

class PeriodFilter {
  const PeriodFilter.allTime() : type = PeriodType.allTime, anchor = null;

  PeriodFilter.year(DateTime d)
    : type = PeriodType.year,
      anchor = DateTime(d.year, 1, 1);

  PeriodFilter.month(DateTime d)
    : type = PeriodType.month,
      anchor = DateTime(d.year, d.month, 1);

  PeriodFilter.day(DateTime d)
    : type = PeriodType.day,
      anchor = DateTime(d.year, d.month, d.day);

  final PeriodType type;

  final DateTime? anchor;

  DateTime get start {
    if (type == PeriodType.allTime) {
      throw StateError('AllTime has no start');
    }
    return anchor!;
  }

  DateTime get end {
    final s = start;
    switch (type) {
      case PeriodType.year:
        return DateTime(s.year + 1, 1, 1);
      case PeriodType.month:
        return DateTime(s.year, s.month + 1, 1);
      case PeriodType.day:
        return DateTime(s.year, s.month, s.day + 1);
      case PeriodType.allTime:
        throw StateError('AllTime has no end');
    }
  }
}
