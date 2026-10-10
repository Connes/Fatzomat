import '../models/shopping_item.dart';

/// A display-only shopping row backed by one or more persisted items.
/// Source IDs remain intact so checking an aggregate can update each day
/// independently instead of inventing a database identity.
class AggregatedShoppingItem {
  final String key;
  final String name;
  final num quantity;
  final String unit;
  final bool checked;
  final String category;
  final List<ShoppingItem> sources;

  const AggregatedShoppingItem({
    required this.key,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.checked,
    required this.category,
    required this.sources,
  });
}

class ShoppingListAggregator {
  const ShoppingListAggregator();

  List<AggregatedShoppingItem> aggregate(Iterable<ShoppingItem> input) {
    final buckets = <String, List<ShoppingItem>>{};
    for (final item in input) {
      final unit = _unitFamily(item.unit);
      final nameKey = item.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final normalizedFoodId = item.foodId?.trim();
      final identity = (normalizedFoodId?.isNotEmpty ?? false)
          ? 'food:$normalizedFoodId'
          : nameKey.isNotEmpty
              ? 'name:$nameKey'
              // Malformed/blank names must not collapse unrelated rows into
              // one aggregate. Keep them independently addressable by ID.
              : 'item:${item.id}';
      // Only merge units that have a known conversion. Unknown units are
      // kept separate by their normalized spelling.
      final key = '$identity|$unit|'
          '${unit == 'other' ? item.unit.trim().toLowerCase() : ''}';
      buckets.putIfAbsent(key, () => <ShoppingItem>[]).add(item);
    }

    final result = buckets.entries.map((entry) {
      final sourceItems = entry.value;
      final first = sourceItems.first;
      final family = _unitFamily(first.unit);
      final targetUnit = _targetUnit(family, sourceItems.map((i) => i.unit));
      final quantity = sourceItems.fold<num>(
        0,
        (sum, item) => sum + _toBase(item.quantity, item.unit, family),
      );
      final converted = _fromBase(quantity, targetUnit, family);
      return AggregatedShoppingItem(
        key: entry.key,
        name: first.name.trim().isEmpty
            ? 'Unbenannter Artikel (${first.id})'
            : first.name.trim(),
        quantity: _round(converted),
        unit: targetUnit,
        checked: sourceItems.every((item) => item.checked),
        category: first.category,
        sources: List<ShoppingItem>.unmodifiable(sourceItems),
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<AggregatedShoppingItem>.unmodifiable(result);
  }

  String _unitFamily(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'kg':
      case 'g':
      case 'gram':
      case 'grams':
        return 'mass';
      case 'l':
      case 'liter':
      case 'litre':
      case 'ml':
      case 'milliliter':
      case 'millilitre':
        return 'volume';
      default:
        return 'other';
    }
  }

  String _targetUnit(String family, Iterable<String> units) {
    if (family == 'mass') {
      return units.any((u) => {'kg'}.contains(u.trim().toLowerCase())) ? 'kg' : 'g';
    }
    if (family == 'volume') {
      return units.any((u) => {'l', 'liter', 'litre'}.contains(u.trim().toLowerCase())) ? 'l' : 'ml';
    }
    return units.first.trim();
  }

  num _toBase(num quantity, String rawUnit, String family) {
    final unit = rawUnit.trim().toLowerCase();
    if (family == 'mass' && unit == 'kg') return quantity * 1000;
    if (family == 'volume' && {'l', 'liter', 'litre'}.contains(unit)) return quantity * 1000;
    return quantity;
  }

  num _fromBase(num quantity, String targetUnit, String family) {
    if (family == 'mass' && targetUnit == 'kg') return quantity / 1000;
    if (family == 'volume' && targetUnit == 'l') return quantity / 1000;
    return quantity;
  }

  num _round(num value) {
    final rounded = (value * 1000).round() / 1000;
    return rounded == rounded.roundToDouble() ? rounded.toInt() : rounded;
  }
}
