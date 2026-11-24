import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe edit accepts every recipe selectable from the shared recipe collection', () {
    final migration = File('supabase/migrations/20261124183000_align_recipe_edit_availability.sql').readAsStringSync();

    expect(migration, contains('WHERE r.id = p_recipe_id'));
    expect(migration, contains("IF NOT FOUND THEN RAISE EXCEPTION 'Rezept ist nicht mehr verfügbar.'"));
    expect(migration, isNot(contains('FROM public.recipe_saves')));
    expect(migration, contains('auth.uid()'));
  });

  test('personal plan metadata update accepts an already visible planned recipe', () {
    final migration = File('supabase/migrations/20261124184500_allow_visible_recipe_plan_metadata_updates.sql').readAsStringSync();

    expect(migration, contains('DROP POLICY IF EXISTS "personal today own update"'));
    expect(migration, contains('USING (user_id = (SELECT auth.uid()))'));
    expect(migration, contains('EXISTS ('));
    expect(migration, contains('FROM public.recipes r'));
    expect(migration, contains('WHERE r.id = personal_today_plans.recipe_id'));
    expect(migration, contains('CREATE POLICY "personal today own update"'));
  });
}
