import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shopping list refreshes in the background when a recipe decision is saved', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final shopping = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final collaboration = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();

    expect(shell, isNot(contains('_shoppingRefreshSignal')));
    expect(shopping, contains('RecipeCollectionEvents.revision.addListener(_onRecipeCollectionChanged)'));
    expect(shopping, contains('if (mounted) load(showLoading: false)'));
    expect(shopping, contains('RecipeCollectionEvents.revision.removeListener(_onRecipeCollectionChanged)'));
    expect(repository, contains('await ensurePersonalRecipeShoppingItems(id);'));
    expect(repository, contains('RecipeCollectionEvents.notifyChanged();'));
    expect(collaboration, contains('RecipeCollectionEvents.notifyChanged();'));
    expect(collaboration, contains("await client.rpc('resolve_decision_request'"));
    expect(collaboration, contains("await client.rpc('accept_decision_share'"));
  });
}
