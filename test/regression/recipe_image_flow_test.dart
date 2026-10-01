import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezeptbilder werden nach dem Upload als private Storage-Bilder aufgelöst', () {
    final service = File('lib/data/services/recipe_image_service.dart').readAsStringSync();
    final repo = File('lib/data/repositories/recipe_repository.dart').readAsStringSync();
    final detail = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final auth = File('lib/core/auth_session_service.dart').readAsStringSync();

    expect(service, contains("static const bucket = 'recipe-images'"));
    expect(service, contains('uploadBinary('));
    expect(service, contains('createSignedUrl(path'));
    expect(service, contains('runWithRefresh'));
    expect(repo, contains('resolveSignedUrl(path)'));
    expect(repo, contains('imageUrl: signedUrl ?? recipe.imageUrl'));
    expect(detail, contains('Rezeptbild verwalten'));
    expect(detail, contains('Image.network('));
    expect(detail, contains("recipe!.imageUrl?.trim().isNotEmpty == true"));
    expect(saved, contains('recipe.imageUrl?.trim().isNotEmpty == true'));
    expect(saved, contains('Image.network('));
    expect(auth, contains('_refreshInFlight'));
    expect(auth, contains('_refreshSession(supabase)'));
  });
}
