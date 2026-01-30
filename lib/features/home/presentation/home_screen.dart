import 'package:expense_tracker_fresh/core/period/period_filter.dart'; // <-- поправь путь, если другой
import 'package:expense_tracker_fresh/core/period/period_provider.dart';
import 'package:expense_tracker_fresh/core/settings/theme_provider.dart';
import 'package:expense_tracker_fresh/core/widgets/app_drawer.dart';
import 'package:expense_tracker_fresh/core/widgets/main_bottom_nav.dart';
import 'package:expense_tracker_fresh/features/expenses/application/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker_fresh/core/categories/expense_categories.dart';
import 'package:expense_tracker_fresh/core/massengerKey/messenger_key.dart';
import 'package:expense_tracker_fresh/core/widgets/states/app_loading.dart';
import 'package:expense_tracker_fresh/core/widgets/states/app_error.dart';
import 'package:expense_tracker_fresh/core/widgets/states/app_empty.dart';

enum SortMode { dateDesc, amountDesc, amountAsc }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialCategoryId});
  final String? initialCategoryId;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _filterCategoryId = widget.initialCategoryId;
  }

  String? _filterCategoryId;
  SortMode _sortMode = SortMode.dateDesc;

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

  String _weekdayName(int wd) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[wd - 1];
  }

  String _formatAmount(String currency, int cents) {
    final v = (cents / 100).toStringAsFixed(2);
    return '$currency $v';
  }

  DateTime _dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

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

  // Панель фильтров (категория + сортировка)
  Widget _filtersBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _filterCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All'),
                ),
                ...expenseCategories.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(c.label),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _filterCategoryId = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<SortMode>(
              value: _sortMode,
              decoration: const InputDecoration(
                labelText: 'Sort',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: SortMode.dateDesc,
                  child: Text('Newest'),
                ),
                DropdownMenuItem(
                  value: SortMode.amountDesc,
                  child: Text('Amount ↓'),
                ),
                DropdownMenuItem(
                  value: SortMode.amountAsc,
                  child: Text('Amount ↑'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _sortMode = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(expensesRepositoryProvider);
    final period = ref.watch(periodFilterProvider);
    ref.watch(themeModeProvider);
    final stream = repo.watchExpenses(period);

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Transactions')),
            body: AppError(message: 'Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: AppLoading(message: 'Loading expenses...'),
          );
        }

        final items = snapshot.data!;

        final totalCents = items.fold<int>(
          0,
          (s, e) => s + (e.amountCents as num).toInt(),
        );

        final currency = items.isEmpty ? 'EUR' : (items.first.currency);

        // --- фильтры/сортировка ---
        List<dynamic> filtered = List.of(items);

        if (_filterCategoryId != null) {
          filtered = filtered
              .where((e) => (e.categoryId as String) == _filterCategoryId)
              .toList();
        }

        switch (_sortMode) {
          case SortMode.dateDesc:
            filtered.sort(
              (a, b) =>
                  (b.spentAt as DateTime).compareTo(a.spentAt as DateTime),
            );
            break;

          case SortMode.amountDesc:
            filtered.sort(
              (a, b) => (b.amountCents as num).toInt().compareTo(
                (a.amountCents as num).toInt(),
              ),
            );
            break;

          case SortMode.amountAsc:
            filtered.sort(
              (a, b) => (a.amountCents as num).toInt().compareTo(
                (b.amountCents as num).toInt(),
              ),
            );
            break;
        }

        final isAmountSort =
            _sortMode == SortMode.amountDesc || _sortMode == SortMode.amountAsc;

        final map = <DateTime, List<dynamic>>{};
        final dayKeys = <DateTime>[];
        if (!isAmountSort) {
          for (final e in filtered) {
            final k = _dayKey(e.spentAt as DateTime);
            (map[k] ??= []).add(e);
          }
          dayKeys.addAll(map.keys.toList()..sort((a, b) => b.compareTo(a)));
        }

        final brightness = Theme.of(context).brightness;

        return KeyedSubtree(
          key: ValueKey(brightness),
          child: Scaffold(
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
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: totalCents),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Text(
                              '-${_formatAmount(currency, value)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          },
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
            drawer: const AppDrawer(),
            body: Column(
              children: [
                _filtersBar(),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? AppEmpty(
                          title: 'No expenses yet',
                          subtitle: 'Add your first expense to get started',
                          icon: Icons.receipt_long,
                          action: FilledButton.icon(
                            onPressed: () => context.push('/expenses/add'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add expense'),
                          ),
                        )
                      : (isAmountSort
                            ? ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  100,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final e = filtered[index];
                                  final cat = categoryById(
                                    e.categoryId as String,
                                  );
                                  final note = e.note as String?;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ExpenseRow(
                                      e: e,
                                      cat: cat,
                                      note: note,
                                      currency: currency,
                                      repo: repo,
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  100,
                                ),
                                itemCount: dayKeys.length,
                                itemBuilder: (context, index) {
                                  final day = dayKeys[index];
                                  final dayItems = map[day]!;

                                  final now = DateTime.now();
                                  final isToday =
                                      day.year == now.year &&
                                      day.month == now.month &&
                                      day.day == now.day;

                                  final dayTotalCents = dayItems.fold<int>(
                                    0,
                                    (sum, e) =>
                                        sum + (e.amountCents as num).toInt(),
                                  );

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              day.day.toString().padLeft(
                                                2,
                                                '0',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 42,
                                                height: 1,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      (isToday
                                                          ? 'TODAY'
                                                          : _weekdayName(
                                                              day.weekday,
                                                            ).toUpperCase()),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_monthName(day.month).toUpperCase()} ${day.year}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatAmount(
                                                currency,
                                                dayTotalCents,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.pink.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...dayItems.map((e) {
                                        final cat = categoryById(
                                          e.categoryId as String,
                                        );
                                        final note = e.note as String?;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _ExpenseRow(
                                            e: e,
                                            cat: cat,
                                            note: note,
                                            currency: currency,
                                            repo: repo,
                                          ),
                                        );
                                      }),
                                      const Divider(height: 28),
                                    ],
                                  );
                                },
                              )),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push('/expenses/add'),
              child: const Icon(Icons.add),
            ),
            bottomNavigationBar: MainBottomNav(currentIndex: 0),
          ),
        );
      },
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.e,
    required this.cat,
    required this.note,
    required this.currency,
    required this.repo,
  });

  final dynamic e;
  final dynamic cat;
  final String? note;
  final String currency;
  final dynamic repo;

  String _formatAmount(String currency, int cents) {
    final v = (cents / 100).toStringAsFixed(2);
    return '$currency $v';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete expense?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (ok != true) return false;

        final removed = e;

        final messenger = messengerKeyImp.currentState;

        // важно: прячем текущий (анимацией), а не "чистим"
        messenger?.hideCurrentSnackBar();

        messenger?.showSnackBar(
          SnackBar(
            content: const Text('Expense deleted'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                await repo.addExpenseFromModel(removed);
                messenger.hideCurrentSnackBar();
              },
            ),
          ),
        );

        // (опционально, но железобетонно) — если вдруг где-то залипнет,
        // принудительно закроем после duration
        Future.delayed(const Duration(seconds: 2), () {
          if (messenger?.mounted ?? false) {
            messenger?.hideCurrentSnackBar();
          }
        });

        await repo.deleteExpense(removed.id);
        return true;
      },
      onDismissed: (_) {},
      child: Container(
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: cat.color.withValues(alpha: 0.15),
            child: Icon(cat.icon, color: cat.color),
          ),
          title: Text(
            cat.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: (note == null || note!.trim().isEmpty) ? null : Text(note!),
          trailing: Text(
            _formatAmount(currency, (e.amountCents as num).toInt()),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.pink.shade400,
            ),
          ),
          onTap: () => context.push('/expenses/add', extra: e),
        ),
      ),
    );
  }
}
