import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/today_plan.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../data/services/shopping_list_aggregator.dart';

/// Personal shopping list aggregated across the next three calendar days.
class MultiDayShoppingListPage extends StatefulWidget {
  const MultiDayShoppingListPage({super.key});

  @override
  State<MultiDayShoppingListPage> createState() => _MultiDayShoppingListPageState();
}

class _MultiDayShoppingListPageState extends State<MultiDayShoppingListPage> with WidgetsBindingObserver {
  final _repo = PersonalTodayRepository();
  final _aggregator = const ShoppingListAggregator();
  late List<DateTime> _days;
  DateTime _observedToday = DateTime.now();
  Timer? _dayBoundaryTimer;
  final Set<String> _selected = <String>{};
  final Set<String> _expanded = <String>{};
  final Set<String> _updatingItems = <String>{};
  List<List<TodayPlan>> _plans = const [];
  List<ShoppingItem> _items = const [];
  bool _loading = true;
  bool _showOnlyOpen = false;
  bool _completingList = false;
  bool _hasInitializedExpansion = false;
  Object? _error;
  int _generation = 0;
  RealtimeChannel? _channel;

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
  List<DateTime> _makeDays(DateTime today) =>
      List.generate(3, (i) => today.add(Duration(days: i)));

  String _key(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _dayTitle(DateTime day) {
    final date = '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.';
    return date;
  }

  List<DateTime> get _activeDays => [
        for (var i = 0; i < _days.length; i++)
          if (i < _plans.length &&
              _plans[i].where((plan) => plan.isRecipe).any(
                    (plan) => _items.any((item) => item.planId == plan.id),
                  ))
            _days[i],
      ];

  void _checkDayBoundary() {
    final today = _dateOnly(DateTime.now());
    if (today == _observedToday || !mounted) return;
    final oldTodayKey = _key(_observedToday);
    final newTodayKey = _key(today);
    setState(() {
      _days = _makeDays(today);
      _plans = const [];
      _items = const [];
      _hasInitializedExpansion = false;
      // Carry the default selection forward with the calendar. Preserve any
      // explicitly selected future day that remains in the new three-day view.
      final hadOnlyTodaySelected = _selected.length == 1 && _selected.contains(oldTodayKey);
      _selected.removeWhere((key) => !_days.any((day) => _key(day) == key));
      if (hadOnlyTodaySelected || _selected.isEmpty) _selected.add(newTodayKey);
      _expanded.removeWhere((key) => !_days.any((day) => _key(day) == key));
      if (_expanded.isEmpty) _expanded.add(newTodayKey);
      _observedToday = today;
    });
    load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkDayBoundary();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _observedToday = _dateOnly(DateTime.now());
    _days = _makeDays(_observedToday);
    _dayBoundaryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkDayBoundary());
    _selected.add(_key(_observedToday));
    _subscribe();
    load();
  }

  void _subscribe() {
    try {
      final client = Supabase.instance.client;
      _channel = client.channel('personal-shopping-list');
      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'personal_today_plans',
            callback: (_) => load(showLoading: false),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shopping_items',
            callback: (_) => load(showLoading: false),
          )
          .subscribe();
    } on AssertionError {
      // Widget tests/previews may mount before Supabase is initialized.
    }
  }

  Future<void> load({bool showLoading = true}) async {
    if (!mounted) return;
    final generation = ++_generation;
    if (showLoading) {
      setState(() { _loading = true; _error = null; });
    }
    try {
      final loadedPlans = await Future.wait(_days.map(_repo.plannedPlansForDate));
      // Accepted shared recipes belong exclusively to the shared shopping list.
      // Keep the personal plan and its ingredients in storage; only exclude them
      // from this private list's presentation and aggregation.
      final plans = loadedPlans
          .map((day) => day.where((plan) => !plan.isSharedAccepted).toList(growable: false))
          .toList(growable: false);
      final ids = plans.expand((day) => day).where((p) => p.isRecipe).map((p) => p.id).toSet();
      final items = await _repo.shoppingItemsForPlans(ids);
      if (!mounted || generation != _generation) return;
      setState(() {
        _plans = plans;
        _items = items;
        final activeKeys = _activeDays.map(_key).toSet();
        _selected.removeWhere((key) => !activeKeys.contains(key));
        if (!_selected.any(activeKeys.contains) && activeKeys.isNotEmpty) {
          _selected.add(activeKeys.first);
        }
        _expanded.removeWhere((key) => !activeKeys.contains(key));
        // Completed days must collapse immediately, including when the user
        // checks the final item while that day's list is currently open.
        _expanded.removeWhere((key) => _activeDays.any(
              (day) => _key(day) == key && _isDayCompleted(day),
            ));
        // Initially open the first day that still needs shopping. Completed
        // days stay collapsed after reload and can be opened manually by
        // tapping their day header.
        if (!_hasInitializedExpansion) {
          final firstIncompleteDay = _activeDays.where((day) => !_isDayCompleted(day));
          if (firstIncompleteDay.isNotEmpty) {
            _expanded.add(_key(firstIncompleteDay.first));
          }
          _hasInitializedExpansion = true;
        }
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() { _error = e; _loading = false; });
    }
  }

  List<TodayPlan> _plansFor(DateTime day) {
    final index = _days.indexWhere((d) => _key(d) == _key(day));
    return index < 0 || index >= _plans.length ? const [] : _plans[index];
  }

  String _categoryName(String category) =>
      category.trim().isEmpty ? 'Weitere Zutaten' : category.trim();

  List<String> _categoryNames(List<AggregatedShoppingItem> items) {
    final categories = items.map((item) => _categoryName(item.category)).toSet().toList()
      ..sort((a, b) {
        if (a == 'Weitere Zutaten') return 1;
        if (b == 'Weitere Zutaten') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return categories;
  }

  Future<void> _updatePlanServings(TodayPlan plan, int servings) async {
    if (servings < 1 || servings > 12) return;
    try {
      final updated = await _repo.updateServings(plan.id, servings);
      if (!updated) throw StateError('Die Personenzahl konnte nicht gespeichert werden.');
      await load(showLoading: false);
      if (mounted) {
        AppFeedback.showSnackBar(context, 
          SnackBar(content: Text('Einkaufsmengen für ${plan.displayTitle} aktualisiert.')),
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showSnackBar(context, 
          SnackBar(content: Text('Personenzahl konnte nicht geändert werden: $e')),
        );
      }
    }
  }

  Future<void> _toggleItem(AggregatedShoppingItem item, bool checked) async {
    if (_updatingItems.contains(item.key) || !mounted) return;
    setState(() => _updatingItems.add(item.key));
    try {
      await Future.wait(item.sources
          .where((source) => source.checked != checked)
          .map((source) => _repo.setShoppingChecked(source.id, checked)));
      await load(showLoading: false);
    } catch (e) {
      // Some requests may already have reached the server when another fails.
      // Reload regardless, so the aggregate reflects persisted state instead
      // of leaving a misleading checkbox state on screen.
      await load(showLoading: false);
      if (mounted) {
        AppFeedback.showSnackBar(context, SnackBar(
          content: Text('Einkaufsartikel konnte nicht vollständig aktualisiert werden: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _updatingItems.remove(item.key));
    }
  }

  bool _isDayCompleted(DateTime day) {
    final plans = _plansFor(day).where((plan) => plan.isRecipe &&
        _items.any((item) => item.planId == plan.id)).toList();
    return plans.isNotEmpty && plans.every((plan) => plan.shoppingListCompletedAt != null);
  }

  Future<void> _completeShoppingList(List<AggregatedShoppingItem> items) async {
    if (_completingList || items.isEmpty || items.any((item) => !item.checked) || !mounted) return;
    final planIds = items.expand((item) => item.sources).map((item) => item.planId).whereType<String>().toSet();
    setState(() => _completingList = true);
    try {
      await Future.wait(planIds.map(_repo.completeShoppingList));
      setState(() {
        for (final day in _activeDays) {
          final ids = _plansFor(day).where((plan) => plan.isRecipe).map((plan) => plan.id).toSet();
          if (ids.isNotEmpty && ids.every(planIds.contains)) _expanded.remove(_key(day));
        }
      });
      await load(showLoading: false);
      if (mounted) {
        AppFeedback.showSnackBar(context, 
          const SnackBar(content: Text('Einkaufsliste erledigt. Die Zutaten bleiben gespeichert.')),
        );
      }
    } catch (e) {
      await load(showLoading: false);
      if (mounted) {
        AppFeedback.showSnackBar(context, 
          SnackBar(content: Text('Einkaufsliste konnte nicht als erledigt gespeichert werden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _completingList = false);
    }
  }

  Future<void> _setVisibleChecked(
    List<AggregatedShoppingItem> items, {
    required bool checked,
  }) async {
    final pending = items.where((item) =>
        item.checked != checked && !_updatingItems.contains(item.key)).toList();
    if (pending.isEmpty || !mounted) return;
    final keys = pending.map((item) => item.key).toSet();
    setState(() => _updatingItems.addAll(keys));
    try {
      await Future.wait(pending.expand((item) => item.sources)
          .where((source) => source.checked != checked)
          .map((source) => _repo.setShoppingChecked(source.id, checked)));
      await load(showLoading: false);
    } catch (e) {
      // Some writes may have succeeded before another failed. Reload persisted
      // state so the visible aggregate never pretends the whole batch succeeded.
      await load(showLoading: false);
      if (mounted) {
        AppFeedback.showSnackBar(context, SnackBar(
          content: Text(
            checked
                ? 'Zutaten konnten nicht vollständig abgehakt werden: $e'
                : 'Zutaten konnten nicht vollständig zurückgesetzt werden: $e',
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _updatingItems.removeAll(keys));
    }
  }

  @override
  void dispose() {
    _dayBoundaryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_channel != null) {
      try {
        Supabase.instance.client.removeChannel(_channel!);
      } on AssertionError {
        // Ignore unavailable Supabase in previews/tests.
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = _activeDays;
    final activeKeys = activeDays.map(_key).toSet();
    final selectedDays = activeDays
        .where((day) => _selected.contains(_key(day)))
        .toList(growable: false);
    final selectedPlanIds = <String>{
      for (final day in selectedDays)
        ..._plansFor(day).where((plan) => plan.isRecipe).map((plan) => plan.id),
    };
    // The aggregate list is independent of the day ExpansionTiles. Hide it
    // when every selected day is completed and collapsed; reopening a completed
    // day header makes the saved ingredients visible again.
    final shouldShowAggregatedList = selectedDays.isEmpty || selectedDays.any(
      (day) => !_isDayCompleted(day) || _expanded.contains(_key(day)),
    );
    final visibleItems = _items
        .where((item) => selectedPlanIds.contains(item.planId))
        .toList(growable: false);
    final aggregated = _aggregator.aggregate(visibleItems);
    final filteredItems = _showOnlyOpen
        ? aggregated.where((item) => !item.checked).toList(growable: false)
        : aggregated;
    final checkedCount = aggregated.where((item) => item.checked).length;
    final progress = aggregated.isEmpty ? 0.0 : checkedCount / aggregated.length;
    final canCompleteList =
        aggregated.isNotEmpty && aggregated.every((item) => item.checked);

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.today,
      appBar: const TogetherAppBar(title: Text('Einkaufsliste')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Einkaufsliste konnte nicht geladen werden.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: load,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (activeDays.isEmpty)
                        AppSurface(
                          color: AppDesign.surface,
                          bordered: false,
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppDesign.primarySoft,
                                  borderRadius: BorderRadius.circular(AppDesign.radiusXl),
                                ),
                                child: const Icon(
                                  Icons.shopping_basket_outlined,
                                  size: 30,
                                  color: AppDesign.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Noch keine Einkaufsliste',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppDesign.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sobald du ein Rezept für heute oder einen der nächsten Tage auswählst, erscheinen hier nur die dafür benötigten Zutaten.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppDesign.secondaryText,
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        AppSurface(
                          color: AppDesign.surface,
                          bordered: false,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${selectedDays.length} von ${activeDays.length} Tagen ausgewählt',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppDesign.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _selected
                                    ..clear()
                                    ..addAll(activeKeys);
                                }),
                                child: const Text('Alle Tage'),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _selected
                                    ..clear()
                                    ..add(_key(activeDays.first));
                                }),
                                child: const Text('Erster Tag'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final day in activeDays)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              color: AppDesign.surface,
                              surfaceTintColor: Colors.transparent,
                              child: ExpansionTile(
                                key: PageStorageKey(_key(day)),
                                initiallyExpanded: _expanded.contains(_key(day)),
                                onExpansionChanged: (open) => setState(() {
                                  if (open) {
                                    _expanded.add(_key(day));
                                  } else {
                                    _expanded.remove(_key(day));
                                  }
                                }),
                                leading: Checkbox(
                                  value: _selected.contains(_key(day)),
                                  activeColor: AppDesign.primaryDark,
                                  onChanged: (value) => setState(() {
                                    if (value == true) {
                                      _selected.add(_key(day));
                                    } else {
                                      _selected.remove(_key(day));
                                    }
                                  }),
                                ),
                                title: Text(
                                  _dayTitle(day),
                                  style: const TextStyle(
                                    color: AppDesign.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: _isDayCompleted(day)
                                    ? const Text('Erledigt')
                                    : null,
                                children: _plansFor(day)
                                    .where((plan) => plan.isRecipe)
                                    .map((plan) => ListTile(
                                          leading: const Icon(
                                            Icons.restaurant_menu_rounded,
                                            color: AppDesign.primaryDark,
                                          ),
                                          title: Text(
                                            plan.displayTitle,
                                            style: const TextStyle(color: AppDesign.text),
                                          ),
                                          subtitle: Text(
                                            '${plan.servings} Personen',
                                            style: const TextStyle(color: AppDesign.secondaryText),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Eine Person weniger',
                                                onPressed: plan.servings <= 1
                                                    ? null
                                                    : () => _updatePlanServings(plan, plan.servings - 1),
                                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                              ),
                                              IconButton(
                                                tooltip: 'Eine Person mehr',
                                                onPressed: plan.servings >= 12
                                                    ? null
                                                    : () => _updatePlanServings(plan, plan.servings + 1),
                                                icon: const Icon(Icons.add_circle_outline_rounded),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        if (shouldShowAggregatedList) ...[
                          const SizedBox(height: 6),
                          AppSurface(
                          color: AppDesign.surface,
                          bordered: false,
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zusammengefasste Zutaten',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppDesign.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              if (aggregated.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$checkedCount von ${aggregated.length} Zutaten erledigt',
                                        style: const TextStyle(color: AppDesign.text),
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).round()}%',
                                      style: const TextStyle(
                                        color: AppDesign.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 7,
                                    backgroundColor: AppDesign.surfaceSoft,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 0,
                                  children: [
                                    if (aggregated.any((item) => !item.checked))
                                      TextButton.icon(
                                        onPressed: _updatingItems.isEmpty
                                            ? () => _setVisibleChecked(aggregated, checked: true)
                                            : null,
                                        icon: const Icon(Icons.done_all_rounded),
                                        label: const Text('Alle abhaken'),
                                      ),
                                    if (aggregated.any((item) => item.checked))
                                      TextButton.icon(
                                        onPressed: _updatingItems.isEmpty
                                            ? () => _setVisibleChecked(aggregated, checked: false)
                                            : null,
                                        icon: const Icon(Icons.restart_alt_rounded),
                                        label: const Text('Alle zurücksetzen'),
                                      ),
                                  ],
                                ),
                                FilterChip(
                                  label: const Text('Nur offene Zutaten'),
                                  selected: _showOnlyOpen,
                                  avatar: const Icon(Icons.checklist_rounded),
                                  onSelected: (selected) => setState(() => _showOnlyOpen = selected),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _completingList || !canCompleteList
                                        ? null
                                        : () => _completeShoppingList(aggregated),
                                    icon: _completingList
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check_circle_outline_rounded),
                                    label: const Text('Einkaufsliste erledigt'),
                                  ),
                                ),
                                if (!canCompleteList) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Hake zuerst alle Zutaten ab, um die Einkaufsliste abzuschließen.',
                                    style: TextStyle(color: AppDesign.secondaryText),
                                  ),
                                ],
                                const SizedBox(height: 8),
                              ],
                              if (aggregated.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    'Für die ausgewählten Tage sind keine Zutaten vorhanden.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppDesign.secondaryText,
                                        ),
                                  ),
                                )
                              else if (filteredItems.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    'Alle Zutaten sind bereits erledigt.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppDesign.secondaryText,
                                        ),
                                  ),
                                )
                              else
                                for (final category in _categoryNames(filteredItems)) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                                    child: Text(
                                      category,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppDesign.text,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  ...filteredItems
                                      .where((item) => _categoryName(item.category) == category)
                                      .map((item) => CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            value: item.checked,
                                            onChanged: _updatingItems.contains(item.key)
                                                ? null
                                                : (value) => _toggleItem(item, value == true),
                                            title: Text(
                                              item.name,
                                              style: TextStyle(
                                                color: item.checked
                                                    ? AppDesign.secondaryText
                                                    : AppDesign.text,
                                                decoration: item.checked
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                                decorationColor: AppDesign.secondaryText,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${item.quantity} ${item.unit}'.trim(),
                                              style: TextStyle(
                                                color: AppDesign.secondaryText,
                                                decoration: item.checked
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                                decorationColor: AppDesign.secondaryText,
                                              ),
                                            ),
                                            secondary: _updatingItems.contains(item.key)
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Text(
                                                    '${item.sources.length}×',
                                                    style: const TextStyle(color: AppDesign.secondaryText),
                                                  ),
                                          )),
                                ],
                            ],
                          ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}
