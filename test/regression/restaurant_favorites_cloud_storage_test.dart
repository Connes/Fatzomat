import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant favorites use Supabase globally and quarantine corrupt migration data', () {
    final source = File('lib/data/repositories/restaurant_favorites_repository.dart').readAsStringSync();
    expect(source, contains("from('restaurant_favorites')"));
    expect(source, isNot(contains(".eq('user_id', _userId)")));
    expect(source, contains('_migrateLegacyFavorites'));
    expect(source, contains('preferences.remove(_legacyStorageKey)'));
    expect(source, contains('_legacyCorruptBackupPrefix'));
    expect(source, contains('preferences.setString(backupKey, raw)'));
    expect(source, contains('preferences.setString(_legacyStorageKey'), isFalse);
  });

  test('restaurant favorites are globally readable and manageable by authenticated users', () {
    final migration = File('supabase/migrations/20261029120000_global_restaurant_favorites.sql').readAsStringSync();
    expect(migration, contains('for select to authenticated'));
    expect(migration, contains('using (true)'));
    expect(migration, contains('for update to authenticated'));
    expect(migration, contains('for delete to authenticated'));
    expect(migration, contains('restaurant_favorites_global_identity_idx'));
    expect(migration, contains('restaurant_favorites_notify_delete'));
    expect(migration, isNot(contains('restaurant_favorites_notify_update')));
  });
}
