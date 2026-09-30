import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Personal Today retains plan editing while shared plan editing stays in collaboration', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final repo = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();
    final model = File('lib/data/models/today_plan.dart').readAsStringSync();
    final migration = File('supabase/migrations/202609160001_v81_today_plan_editing.sql').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.31+243'));
    expect(source, contains('class TodayPage'));
    // Today is intentionally a minimal decision surface now. The underlying
    // plan-editing/synchronization functions remain in the page for existing
    // workflows and regression coverage, but their old dashboard controls are
    // no longer part of the Today UI.
        expect(source, contains('Future<void> removeTodayPlan() async'));
    expect(source, contains('controller = TodayController();'));
    expect(source, contains('controller.dispose();'));
        expect(repo, contains('updateSharedRecipePlanServings'));
    expect(repo, contains('replaceSharedRecipePlan'));
    expect(repo, contains('removeSharedRecipePlan'));
    expect(model, contains('final int servings'));
    expect(migration, contains('update_shared_recipe_plan_servings'));
    expect(migration, contains('replace_shared_recipe_plan'));
    expect(migration, contains('cancel_shared_recipe_plan'));
    expect(migration, contains("source = 'recipe'"));
  });
}
