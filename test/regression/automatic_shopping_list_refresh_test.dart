import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shopping tab refreshes when selected and recipe ingredients are ensured on save', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final shopping = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();

    expect(shell, contains('_shoppingRefreshSignal.value++'));
    expect(shell, contains('ShoppingListPage(refreshSignal: _shoppingRefreshSignal)'));
    expect(shopping, contains('widget.refreshSignal?.addListener(_onRefreshRequested)'));
    expect(shopping, contains('if (mounted) load(showLoading: false)'));
    expect(repository, contains('await ensurePersonalRecipeShoppingItems(id);'));
  });
}
