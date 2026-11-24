import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe edit accepts every recipe selectable from the shared recipe collection', () {
    final migration = File('supabase/migrations/20261124183000_align_recipe_edit_availability.sql').readAsStringSync();

    expect(migration, contains('WHERE r.id = p_recipe_id'));
    expect(migration, contains("IF NOT FOUND THEN RAISE EXCEPTION 'Rezept ist nicht mehr verfügbar.'"));
    expect(migration, isNot(contains('recipe_saves')));
    expect(migration, contains('auth.uid()'));
  });
}
