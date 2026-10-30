import 'package:flutter/material.dart';

import 'multi_day_shopping_list_page.dart';

/// The shopping list has one consistent entry point, whether or not a
/// connection exists. Shared and personal recipe plans are combined by the
/// multi-day list itself.
class ShoppingListPage extends StatelessWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const MultiDayShoppingListPage();
}
