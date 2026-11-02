import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nachträgliche Katalogkonsolidierung bewahrt alle Lebensmittelreferenzen', () {
    final source = File(
      'supabase/migrations/20261102150000_complete_legacy_food_reference_migration.sql',
    ).readAsStringSync();

    expect(source, contains("('onb_hackfleisch', 'mixed_minced_meat')"));
    expect(source, contains("('onb_mais', 'corn')"));
    expect(source, contains("('corn', 'Mais', 'Gemüse'"));
    expect(source, contains("array['Hackfleisch']"));
    expect(source, contains('insert into public.user_food_preferences'));
    expect(source, contains('update public.recipe_ingredients'));
    expect(source, contains('update public.shopping_items'));
    expect(source, contains('where item.food_id = merge.source_id'));
    expect(source, contains('raise exception'));
    expect(source, contains('where source_food.created_by is null'));
  });

  test('Lebensmittel werden erst nach Umhängen aller Referenzen gelöscht', () {
    final source = File(
      'supabase/migrations/20261102150000_complete_legacy_food_reference_migration.sql',
    ).readAsStringSync();

    final preferences = source.indexOf('insert into public.user_food_preferences');
    final recipes = source.indexOf('update public.recipe_ingredients');
    final shopping = source.indexOf('update public.shopping_items');
    final deletion = source.indexOf('delete from public.foods');

    expect(preferences, lessThan(deletion));
    expect(recipes, lessThan(deletion));
    expect(shopping, lessThan(deletion));
  });
}
