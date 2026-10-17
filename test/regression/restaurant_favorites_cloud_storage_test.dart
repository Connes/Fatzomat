import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant favorites use Supabase and only read local storage for migration', () {
    final source = File('lib/data/repositories/restaurant_favorites_repository.dart').readAsStringSync();
    expect(source, contains("from('restaurant_favorites')"));
    expect(source, contains(".eq('user_id', _userId)"));
    expect(source, contains('_migrateLegacyFavorites'));
    expect(source, contains('preferences.remove(_legacyStorageKey)'));
    expect(source, isNot(contains('preferences.setString')));
  });

  test('restaurant favorites table is account-scoped by row-level security', () {
    final migration = File('supabase/migrations/20261017120000_cloud_restaurant_favorites.sql').readAsStringSync();
    expect(migration, contains('alter table public.restaurant_favorites enable row level security'));
    expect(migration, contains('using (user_id = (select auth.uid()))'));
    expect(migration, contains('with check (user_id = (select auth.uid()))'));
    expect(migration, contains('restaurant_favorites_user_identity_idx'));
  });
}
