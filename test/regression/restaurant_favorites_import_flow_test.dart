import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plus action offers JSON import and ChatGPT add directly', () {
    final page = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();
    expect(page, contains("onPressed: _showAddOptions"));
    expect(page, contains("label: const Text('JSON-Datei importieren')"));
    expect(page, contains("label: const Text('Mit ChatGPT hinzufügen')"));
    expect(page, contains("if (choice == 'json')"));
    expect(page, contains('await _importFavoriteJson();'));
  });

  test('imported restaurants are saved through the account-scoped Supabase repository', () {
    final page = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();
    final repository = File('lib/data/repositories/restaurant_favorites_repository.dart').readAsStringSync();
    final migration = File('supabase/migrations/20261018045840_cloud_restaurant_favorites.sql').readAsStringSync();
    expect(page, contains('await _repository.add(normalized)'));
    expect(repository, contains("from('restaurant_favorites')"));
    expect(repository, contains(".eq('user_id', _userId)"));
    expect(migration, contains('alter table public.restaurant_favorites enable row level security'));
  });
}
