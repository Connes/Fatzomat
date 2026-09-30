import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe image workflow uses the existing image picker dependency', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final service = File('lib/data/services/recipe_image_service.dart').readAsStringSync();
    final repo = File('lib/data/repositories/recipe_repository.dart').readAsStringSync();

    expect(pubspec, contains('image_picker:'));
    expect(service, contains("static const bucket = 'recipe-images';"));
    expect(service, contains('createSignedUrl'));
    expect(service, contains('signedUrlLifetimeSeconds = 60 * 60 * 24 * 7'));
    expect(repo, contains('_deleteImageIfUnreferenced'));
    expect(repo, contains("'image_path': upload.path"));
    expect(repo, contains('removeRecipeImage'));
  });


  test('recipe image upload refreshes an expired Supabase session', () {
    final auth = File('lib/core/auth_session_service.dart').readAsStringSync();
    final service = File('lib/data/services/recipe_image_service.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(auth, contains('session.isExpired'));
    expect(auth, contains('refreshSession()'));
    expect(auth, contains('runWithRefresh'));
    expect(service, contains('AuthSessionService.runWithRefresh'));
    expect(main, contains('AuthSessionService.ensureValidSession'));
    expect(main, isNot(contains('final auth = Supabase.instance.client.auth;')));
  });

  test('recipe JSON stays separate from the storage image path', () {
    final model = File('lib/data/models/recipe.dart').readAsStringSync();
    expect(model, contains("'image_url': imageUrl"));
    expect(model, isNot(contains("'image_path': imagePath")));
  });

  test('import preview exposes an optional recipe image picker', () {
    final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    expect(source, contains('Rezeptbild (optional)'));
    expect(source, contains('Bild auswählen'));
    expect(source, contains('Bild ersetzen'));
    expect(source, contains('RecipeImageService'));
  });

  test('recipe detail exposes image management', () {
    final source = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    expect(source, contains('Rezeptbild verwalten'));
    expect(source, contains('Bild entfernen'));
    expect(source, contains('manageRecipeImage'));
  });

  test('today and history resolve storage image paths', () {
    final today = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final todayModel = File('lib/data/models/today_plan.dart').readAsStringSync();
    final historyModel = File('lib/data/models/personal_history_entry.dart').readAsStringSync();
    expect(today, contains('recipes(name,description,servings,image_url,image_path)'));
    expect(today, contains('_resolveNestedRecipeImage'));
    expect(todayModel, contains('final String? imagePath;'));
    expect(historyModel, contains('final String? imagePath;'));
  });

  test('accepted shared recipe copies preserve image_path and storage access follows recipe references', () {
    final migration = File('supabase/migrations/20260930100000_recipe_image_sharing_hardening.sql').readAsStringSync();
    expect(migration, contains('source_recipe.image_path'));
    expect(migration, contains('where r.image_path = name'));
  });
}
