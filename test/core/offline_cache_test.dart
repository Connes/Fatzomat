import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app_mvp/data/cache/offline_cache.dart';
import '../test_shared_preferences.dart';

void main() {
  initTestSharedPreferences();

  test('stores and reads non-sensitive JSON cache', () async {
    final prefs = SharedPreferencesAsync();
    final cache = OfflineCache(prefs: prefs);
    await cache.writeFoods([
      {'id': 'apple', 'name': 'Apfel', 'category': 'Obst'},
    ]);

    final result = await cache.readFoods();
    expect(result.single['id'], 'apple');
    expect(result.single['name'], 'Apfel');
  });
}
