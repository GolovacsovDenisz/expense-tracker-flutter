import 'package:expense_tracker_fresh/core/categories/expense_categories.dart';
import 'package:expense_tracker_fresh/core/period/period_filter.dart';
import 'package:expense_tracker_fresh/core/period/period_provider.dart';
import 'package:expense_tracker_fresh/core/widgets/main_bottom_nav.dart';
import 'package:expense_tracker_fresh/features/expenses/application/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker_fresh/core/widgets/states/app_loading.dart';
import 'package:expense_tracker_fresh/core/widgets/states/app_error.dart';
import 'package:expense_tracker_fresh/core/widgets/states/app_empty.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }

  void _shiftPeriod(PeriodFilter period, int delta) {
    if (period.type == PeriodType.allTime) return;

    final a = period.anchor!;
    final n = ref.read(periodFilterProvider.notifier);

    switch (period.type) {
      case PeriodType.year:
        n.setYear(DateTime(a.year + delta, 1, 1));
        break;
      case PeriodType.month:
        n.setMonth(DateTime(a.year, a.month + delta, 1));
        break;
      case PeriodType.day:
        n.setDay(DateTime(a.year, a.month, a.day + delta));
        break;
      case PeriodType.allTime:
        break;
    }
  }

  String _periodLabel(PeriodFilter p) {
    switch (p.type) {
      case PeriodType.allTime:
        return 'ALL TIME';
      case PeriodType.year:
        return '${p.anchor!.year}';
      case PeriodType.month:
        return '${_monthName(p.anchor!.month).toUpperCase()} ${p.anchor!.year}';
      case PeriodType.day:
        final d = p.anchor!;
        return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month).toUpperCase()} ${d.year}';
    }
  }

  Future<void> _openPeriodSheet(PeriodFilter period) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final n = ref.read(periodFilterProvider.notifier);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 10,
              children: [
                const Center(
                  child: Text(
                    'Period',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('All time'),
                  onTap: () {
                    n.setAllTime();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Year'),
                  onTap: () {
                    n.setYear(DateTime.now());
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month),
                  title: const Text('Month'),
                  onTap: () {
                    n.setMonth(DateTime.now());
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.today),
                  title: const Text('Today'),
                  onTap: () {
                    n.setDay(DateTime.now());
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Select day'),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: period.type == PeriodType.day
                          ? period.anchor!
                          : now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked == null) return;
                    if (!mounted) return;
                    n.setDay(picked);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _money(String currency, int cents) {
    return '$currency ${(cents / 100).toStringAsFixed(2)}';
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _todayEndExclusive() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  int _monthsCount(DateTime start, DateTime endExclusive) {
    final s = DateTime(start.year, start.month, 1);
    final eMonthStart = DateTime(endExclusive.year, endExclusive.month, 1);

    int m = (eMonthStart.year - s.year) * 12 + (eMonthStart.month - s.month);

    if (endExclusive.isAfter(eMonthStart)) m += 1;

    return m <= 0 ? 1 : m;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(expensesRepositoryProvider);
    final period = ref.watch(periodFilterProvider);

    final stream = repo.watchExpenses(period);

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        // 1) ERROR
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 80,
              centerTitle: true,
              title: InkWell(
                onTap: () => _openPeriodSheet(period),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          splashRadius: 20,
                          onPressed: () => _shiftPeriod(period, -1),
                        ),
                        const Text(
                          '-EUR 0.00',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          splashRadius: 20,
                          onPressed: () => _shiftPeriod(period, 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _periodLabel(period),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: AppError(message: 'Error: ${snapshot.error}'),
            bottomNavigationBar: const MainBottomNav(currentIndex: 1),
          );
        }

        // 2) LOADING
        if (!snapshot.hasData) {
          return const Scaffold(
            body: AppLoading(message: 'Loading dashboard...'),
            bottomNavigationBar: MainBottomNav(currentIndex: 1),
          );
        }

        // 3) DATA
        final items = snapshot.data!;
        final currency = items.isEmpty ? 'EUR' : items.first.currency;
        final totalCents = items.fold<int>(0, (s, e) => s + e.amountCents);
        final todayEnd = _todayEndExclusive();

        DateTime rangeStart;
        DateTime rangeEndExclusive;

        if (period.type == PeriodType.allTime) {
          final minSpentAt = items.isEmpty
              ? DateTime.now()
              : items
                    .map((e) => e.spentAt)
                    .reduce((a, b) => a.isBefore(b) ? a : b);

          rangeStart = _dayStart(minSpentAt);
          rangeEndExclusive = todayEnd;
        } else {
          rangeStart = period.start;
          rangeEndExclusive = _minDate(period.end, todayEnd);
        }

        final daysCount = rangeEndExclusive
            .difference(rangeStart)
            .inDays
            .clamp(1, 999999);
        final monthsCount = _monthsCount(rangeStart, rangeEndExclusive);

        final avgPerDayCents = (totalCents / daysCount).round();
        final avgPerMonthCents = (totalCents / monthsCount).round();

        final activeDays = items
            .map((e) => _dayStart(e.spentAt))
            .toSet()
            .length;

        final byCat = <String, int>{};
        for (final e in items) {
          byCat[e.categoryId] = (byCat[e.categoryId] ?? 0) + e.amountCents;
        }
        final catRows = byCat.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // 4) EMPTY
        if (items.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 80,
              centerTitle: true,
              title: InkWell(
                onTap: () => _openPeriodSheet(period),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          splashRadius: 20,
                          onPressed: () => _shiftPeriod(period, -1),
                        ),
                        Text(
                          '-${_money(currency, 0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          splashRadius: 20,
                          onPressed: () => _shiftPeriod(period, 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _periodLabel(period),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: AppEmpty(
              title: 'No expenses for this period',
              subtitle: 'Add an expense to see analytics here',
              icon: Icons.pie_chart_outline,
              action: FilledButton.icon(
                onPressed: () => context.push('/expenses/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push('/expenses/add'),
              child: const Icon(Icons.add),
            ),
            bottomNavigationBar: const MainBottomNav(currentIndex: 1),
          );
        }

        // 5) NORMAL UI
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            centerTitle: true,
            title: InkWell(
              onTap: () => _openPeriodSheet(period),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        splashRadius: 20,
                        onPressed: () => _shiftPeriod(period, -1),
                      ),
                      Text(
                        '-${_money(currency, totalCents)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        splashRadius: 20,
                        onPressed: () => _shiftPeriod(period, 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _periodLabel(period),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.pie_chart_outline),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All categories',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            _money(currency, totalCents),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: Text('Avg / day')),
                              Text(
                                _money(currency, avgPerDayCents),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: Text('Avg / month')),
                              Text(
                                _money(currency, avgPerMonthCents),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: Text('Active days')),
                              Text(
                                '$activeDays',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: catRows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final entry = catRows[i];
                        final cat = categoryById(entry.key);
                        final cents = entry.value;

                        final pct = totalCents == 0 ? 0.0 : cents / totalCents;
                        final pctClamped = pct.clamp(0.0, 1.0);

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            context.go('/home', extra: {'categoryId': cat.id});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: cat.color.withValues(
                                        alpha: 0.15,
                                      ),
                                      child: Icon(cat.icon, color: cat.color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        cat.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _money(currency, cents),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: pctClamped,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${(pctClamped * 100).toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/expenses/add'),
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: const MainBottomNav(currentIndex: 1),
        );
      },
    );
  }
}
