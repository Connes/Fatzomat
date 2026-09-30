import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current;

  String read(String path) => File('${root.path}/$path').readAsStringSync();

  test('personal Today repository carries the optional recipe image and history', () {
    final repo = read('lib/data/repositories/personal_today_repository.dart');
    expect(repo, contains('personal_decision_history'));
    expect(repo, contains('recipes(name,description,servings,image_url,image_path)'));
  });

  test('personal Today RLS requires owned or saved recipe access', () {
    final migration = read('supabase/migrations/202609200003_personal_first_hardening_and_history.sql');
    expect(migration, contains('personal today own insert'));
    expect(migration, contains('r.created_by = (select auth.uid())'));
    expect(migration, contains('rs.user_id = (select auth.uid())'));
  });

  test('shared plan RLS does not accept arbitrary recipe ids', () {
    final migration = read('supabase/migrations/202609200003_personal_first_hardening_and_history.sql');
    expect(migration, contains('shared plans own insert'));
    expect(migration, contains('shared plans member update'));
    expect(migration, contains('public.is_connection_member(connection_id)'));
  });

  test('personal history is user-isolated', () {
    final migration = read('supabase/migrations/202609200003_personal_first_hardening_and_history.sql');
    expect(migration, contains('personal history own select'));
    expect(migration, contains('user_id = (select auth.uid())'));
  });

  test('personal favorite flow does not depend on CollaborationRepository', () {
    final source = read('lib/features/recipes/add_favorite_recipe_dialog.dart');
    expect(source, isNot(contains('CollaborationRepository')));
    expect(source, contains('RecipeRepository'));
  });

  test('Today result card renders the existing recipe detail image fallback', () {
    final source = read('lib/features/shared/today_page.dart');
    expect(source, contains("recipe_detail_background.png"));
    expect(source, contains('plan.imageUrl'));
  });
}
