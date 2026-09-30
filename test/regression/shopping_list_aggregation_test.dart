import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.13.8 merges identical recipe shopping items across sections', () {
    final migration = File(
      'supabase/migrations/20260928143000_merge_duplicate_recipe_shopping_items.sql',
    ).readAsStringSync();

    expect(migration, contains('merge_recipe_shopping_item'));
    expect(migration, contains("si.source = 'recipe'"));
    expect(migration, contains('lower(btrim(si.name)) = lower(btrim(new.name))'));
    expect(migration, contains('lower(btrim(si.unit)) = lower(btrim(new.unit))'));
    expect(migration, contains('quantity + new.quantity'));
  });
}
