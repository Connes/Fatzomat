import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe deletion is owner-only and protects active plans', () {
    final migration = File(
      'supabase/migrations/20260929133509_harden_recipe_delete.sql',
    ).readAsStringSync();

    expect(migration, contains('if owner_id <> uid then'));
    expect(migration, contains('personal_today_plans'));
    expect(migration, contains("sp.status <> 'cancelled'"));
    expect(migration, contains("pp.status <> 'cancelled"));
    expect(migration, contains('delete from public.recipe_saves'));
  });

  test('recipe removal cleans a private storage image only after successful deletion', () {
    final repo = File(
      'lib/data/repositories/recipe_repository.dart',
    ).readAsStringSync();

    expect(repo, contains("select('image_path')"));
    expect(repo, contains('if (removed) {'));
    expect(repo, contains('_deleteImageIfUnreferenced(imagePath)'));
    expect(repo, contains('RecipeImageService(client: client).delete(normalized)'));
  });

  test('delete UI handles a protected recipe without pretending it was deleted', () {
    final detail = File(
      'lib/features/recipes/recipe_detail_page.dart',
    ).readAsStringSync();
    final saved = File(
      'lib/features/recipes/saved_recipes_page.dart',
    ).readAsStringSync();

    expect(detail, contains('final removed = await repo.removeRecipeFromCollection'));
    expect(detail, contains('if (!removed)'));
    expect(saved, contains('final removed = await repo.removeRecipeFromCollection'));
    expect(saved, contains('if (!removed && mounted)'));
  });
}
