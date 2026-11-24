import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editing a menu replaces the existing personal plan explicitly', () {
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final menu = File('lib/features/shared/menu_builder_page.dart').readAsStringSync();

    expect(repository, contains("replaceExisting ? 'replace_personal_plan_for_date' : 'set_personal_plan_for_date'"));
    expect(menu, contains('replaceExisting: true'));
  });

  test('order and restaurant edit flows preserve explicit replacement intent', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final mode = File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();
    final restaurant = File('lib/features/food_modes/chatgpt_restaurant_page.dart').readAsStringSync();

    expect(today, contains("_openMode(FoodMode.order, replaceExistingDecision: true)"));
    expect(today, contains("_openMode(FoodMode.dineOut, replaceExistingDecision: true)"));
    expect(mode, contains('replaceExisting: widget.replaceExistingDecision'));
    expect(mode, contains('replaceExistingDecision: widget.replaceExistingDecision'));
    expect(restaurant, contains('replaceExisting: widget.replaceExistingDecision'));
  });

  test('replacement RPC only updates an existing personal plan and leaves normal selection guarded', () {
    final migration = File('supabase/migrations/20261124170000_replace_existing_personal_decision.sql').readAsStringSync();

    expect(migration, contains('replace_personal_plan_for_date'));
    expect(migration, contains('FOR UPDATE'));
    expect(migration, contains('Für diesen Tag gibt es keine bestehende persönliche Entscheidung zum Ändern.'));
    expect(migration, contains('public.shared_recipe_plans'));
    expect(migration, contains('DELETE FROM public.shopping_items'));
    expect(migration, contains('GRANT EXECUTE'));
  });
}
