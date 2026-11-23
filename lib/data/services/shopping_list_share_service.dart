import '../models/shopping_item.dart';
import 'shopping_list_aggregator.dart';

/// Formats only unchecked shopping rows for sharing outside the app.
class ShoppingListShareService {
  const ShoppingListShareService();

  String buildText({
    required Iterable<ShoppingItem> items,
    required String title,
    String? subtitle,
    int? servings,
  }) {
    final openItems = const ShoppingListAggregator().aggregate(
      items.where((item) => !item.checked),
    );
    if (openItems.isEmpty) return '';

    final categories = <String, List<AggregatedShoppingItem>>{};
    for (final item in openItems) {
      final category = item.category.trim().isEmpty
          ? 'Weitere Zutaten'
          : item.category.trim();
      categories.putIfAbsent(category, () => <AggregatedShoppingItem>[]).add(item);
    }
    final categoryNames = categories.keys.toList()
      ..sort((a, b) {
        if (a == 'Weitere Zutaten') return 1;
        if (b == 'Weitere Zutaten') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final sections = <String>[];
    for (final category in categoryNames) {
      final lines = categories[category]!.map((item) {
        final quantity = item.showQuantity
            ? '${_formatQuantity(item.quantity)} ${item.unit.trim().isEmpty ? 'Stück' : item.unit.trim()} '
            : '';
        return '• $quantity${item.name}';
      });
      sections.add('_$category_\n${lines.join('\n')}');
    }

    return [
      '🛒 $title',
      '',
      if (subtitle != null && subtitle.trim().isNotEmpty) subtitle.trim(),
      if (servings != null) '$servings Personen',
      if ((subtitle != null && subtitle.trim().isNotEmpty) || servings != null) '',
      '*Offene Zutaten*',
      '',
      sections.join('\n\n'),
    ].join('\n');
  }

  String _formatQuantity(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
