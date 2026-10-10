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
          '${unit == 'other' ? _canonicalUnit(item.unit).toLowerCase() : ''}';
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
            : first.name.trim().replaceAll(RegExp(r'\s+'), ' '),
        quantity: _round(converted),
        unit: targetUnit,
        checked: sourceItems.every((item) => item.checked),
        category: first.category,
        sources: List<ShoppingItem>.unmodifiable(sourceItems),
      );
    }).toList()
      ..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (byName != 0) return byName;
        final byUnit = a.unit.toLowerCase().compareTo(b.unit.toLowerCase());
        if (byUnit != 0) return byUnit;
        return a.key.compareTo(b.key);
      });
    return List<AggregatedShoppingItem>.unmodifiable(result);
  }

  String _unitFamily(String raw) {
    switch (_normalizedUnit(raw)) {
      case 'kg':
      case 'kilogram':
      case 'kilogramm':
      case 'g':
      case 'gr':
      case 'gram':
      case 'gramm':
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

  String _normalizedUnit(String raw) =>
      raw.trim().toLowerCase().replaceAll('.', '');

  String _canonicalUnit(String raw) {
    switch (_normalizedUnit(raw)) {
      case 'stk':
      case 'st':
      case 'stück':
      case 'stueck':
        return 'Stück';
      case 'el':
      case 'essl':
      case 'esslöffel':
      case 'essloeffel':
        return 'EL';
      case 'tl':
      case 'teel':
      case 'teelöffel':
      case 'teeloeffel':
        return 'TL';
      default:
        return raw.trim();
    }
  }

  bool _isKilogram(String unit) =>
      {'kg', 'kilogram', 'kilogramm'}.contains(_normalizedUnit(unit));

  bool _isLiter(String unit) =>
      {'l', 'liter', 'litre'}.contains(_normalizedUnit(unit));

  String _targetUnit(String family, Iterable<String> units) {
    if (family == 'mass') {
      return units.any(_isKilogram) ? 'kg' : 'g';
    }
    if (family == 'volume') {
      return units.any(_isLiter) ? 'l' : 'ml';
    }
    return _canonicalUnit(units.first);
  }

  num _toBase(num quantity, String rawUnit, String family) {
    final unit = _normalizedUnit(rawUnit);
    if (family == 'mass' && _isKilogram(unit)) return quantity * 1000;
    if (family == 'volume' && _isLiter(unit)) return quantity * 1000;
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
