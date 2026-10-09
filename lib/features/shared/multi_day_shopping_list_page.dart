import 'package:flutter/material.dart';

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

class _MultiDayShoppingListPageState extends State<MultiDayShoppingListPage> {
  final _repo = PersonalTodayRepository();
  final _aggregator = const ShoppingListAggregator();
  late final List<DateTime> _days;
  final Set<String> _selected = <String>{};
  final Set<String> _expanded = <String>{};
  List<List<TodayPlan>> _plans = const [];
  List<ShoppingItem> _items = const [];
  bool _loading = true;
  Object? _error;
  int _generation = 0;

  String _key(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _label(int index) => index == 0 ? 'Heute' : index == 1 ? 'Morgen' : 'Übermorgen';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = List.generate(3, (i) => today.add(Duration(days: i)));
    _selected.add(_key(today));
    _expanded.add(_key(today));
    load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    setState(() { _loading = true; _error = null; });
    try {
      final plans = await Future.wait(_days.map(_repo.plannedPlansForDate));
      final ids = plans.expand((day) => day).where((p) => p.isRecipe).map((p) => p.id).toSet();
      final items = await _repo.shoppingItemsForPlans(ids);
      if (!mounted || generation != _generation) return;
      setState(() { _plans = plans; _items = items; _loading = false; });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() { _error = e; _loading = false; });
    }
  }

  List<TodayPlan> _plansFor(DateTime day) {
    final index = _days.indexWhere((d) => _key(d) == _key(day));
    return index < 0 || index >= _plans.length ? const [] : _plans[index];
  }

  Future<void> _toggleItem(AggregatedShoppingItem item, bool checked) async {
    try {
      for (final source in item.sources) {
        if (source.checked != checked) await _repo.setShoppingChecked(source.id, checked);
      }
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Einkaufsartikel konnte nicht aktualisiert werden: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlanIds = <String>{};
    for (final day in _days.where((d) => _selected.contains(_key(d)))) {
      selectedPlanIds.addAll(_plansFor(day).where((p) => p.isRecipe).map((p) => p.id));
    }
    final visibleItems = _items.where((item) => selectedPlanIds.contains(
      // The repository keeps each source item's plan ID in the query, but the
      // public model intentionally doesn't expose it. Resolve via plan groups below.
      item.planId,
    )).toList();
    final aggregated = _aggregator.aggregate(visibleItems);

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.today,
      appBar: const TogetherAppBar(title: Text('Einkaufsliste')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Einkaufsliste konnte nicht geladen werden.'), const SizedBox(height: 12), FilledButton(onPressed: load, child: const Text('Erneut versuchen'))])))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      for (var i = 0; i < _days.length; i++)
                        Card(
                          child: ExpansionTile(
                            key: PageStorageKey(_key(_days[i])),
                            initiallyExpanded: _expanded.contains(_key(_days[i])),
                            onExpansionChanged: (open) => setState(() { if (open) { _expanded.add(_key(_days[i])); } else { _expanded.remove(_key(_days[i])); } }),
                            leading: Checkbox(
                              value: _selected.contains(_key(_days[i])),
                              activeColor: AppDesign.primaryDark,
                              onChanged: (value) => setState(() {
                                if (value == true) { _selected.add(_key(_days[i])); } else { _selected.remove(_key(_days[i])); }
                              }),
                            ),
                            title: Text(_label(i), style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${_plansFor(_days[i]).where((p) => p.isRecipe).length} geplante Rezepte'),
                            children: _plansFor(_days[i]).map((plan) => ListTile(
                              leading: const Icon(Icons.restaurant_menu_rounded),
                              title: Text(plan.displayTitle),
                              subtitle: Text('${plan.servings} Portionen'),
                            )).toList(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text('Zusammengefasste Zutaten', style: Theme.of(context).textTheme.titleLarge),
                      if (aggregated.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Für die ausgewählten Tage sind keine Zutaten vorhanden.'))
                      else
                        ...aggregated.map((item) => CheckboxListTile(
                          value: item.checked,
                          onChanged: (value) => _toggleItem(item, value == true),
                          title: Text(item.name),
                          subtitle: Text('${item.quantity} ${item.unit}'.trim()),
                          secondary: Text('${item.sources.length}×'),
                        )),
                    ],
                  ),
                ),
    );
  }

}
