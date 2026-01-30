
import 'package:flutter_riverpod/legacy.dart';
import 'period_filter.dart';

class PeriodFilterNotifier extends StateNotifier<PeriodFilter> {
  PeriodFilterNotifier() : super(PeriodFilter.month(DateTime.now()));

  void setAllTime() => state = const PeriodFilter.allTime();
  void setYear(DateTime d) => state = PeriodFilter.year(d);
  void setMonth(DateTime d) => state = PeriodFilter.month(d);
  void setDay(DateTime d) => state = PeriodFilter.day(d);
}

final periodFilterProvider =
    StateNotifierProvider<PeriodFilterNotifier, PeriodFilter>(
      (ref) => PeriodFilterNotifier(),
    );
