import 'package:flutter/material.dart';

import 'multi_day_shopping_list_page.dart';

/// The shopping list has one consistent entry point, whether or not a
/// connection exists. Shared and personal recipe plans are combined by the
/// multi-day list itself.
class ShoppingListPage extends StatelessWidget {
  final ValueListenable<int>? refreshSignal;

  const ShoppingListPage({super.key, this.refreshSignal});

  @override
  Widget build(BuildContext context) =>
      MultiDayShoppingListPage(refreshSignal: refreshSignal);
}
