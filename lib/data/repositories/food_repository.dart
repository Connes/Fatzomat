import 'package:supabase_flutter/supabase_flutter.dart';

import '../cache/offline_cache.dart';
import '../models/food.dart';

class DuplicateFoodException implements Exception {
  final String name;
  const DuplicateFoodException(this.name);

  @override
  String toString() => 'Das Lebensmittel „$name“ gibt es bereits.';
}

class FoodRepository {
  final SupabaseClient? _client;
  final OfflineCache _cache;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  FoodRepository({SupabaseClient? client, OfflineCache? cache})
      : _client = client,
        _cache = cache ?? OfflineCache();

  String get _userId => client.auth.currentUser?.id ??
      (throw StateError('Keine Supabase-Sitzung vorhanden.'));

  Future<List<Food>> foods() async {
    try {
      final rows = await client
          .from('foods')
          .select('id,name,category,search_terms,aliases,default_unit,dietary_type,allergens,protein_type,created_by')
          .order('category')
          .order('name');
      final models = rows
          .map((row) => Food.fromMap(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      await _cache.writeFoods(models.map((food) => food.toMap()).toList(growable: false));
      return models;
    } catch (_) {
      final cached = await _cache.readFoods();
      if (cached.isEmpty) rethrow;
      return cached.map(Food.fromMap).toList(growable: false);
    }
  }

  Future<Food> addFoodModel({
    required String name,
    required String category,
    required String defaultUnit,
  }) async {
    final normalizedName = name.trim().replaceAll(RegExp(r'\\s+'), ' ');
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Der Name darf nicht leer sein.');
    }

    // Friendly pre-check; the unique database index also protects concurrent inserts.
    final existing = await client
        .from('foods')
        .select('name')
        .not('created_by', 'is', null);
    final duplicate = existing.any((row) =>
        row['name'].toString().trim().replaceAll(RegExp(r'\\s+'), ' ').toLowerCase() ==
        normalizedName.toLowerCase());
    if (duplicate) throw DuplicateFoodException(normalizedName);

    final id =
        'custom_${DateTime.now().microsecondsSinceEpoch}_${_userId.substring(0, 8)}';
    final row = await client.from('foods').insert({
      'id': id,
      'name': normalizedName,
      'category': category,
      'default_unit': defaultUnit.trim().isEmpty ? 'Stück' : defaultUnit.trim(),
      'created_by': _userId,
    }).select(
      'id,name,category,search_terms,aliases,default_unit,dietary_type,allergens,protein_type,created_by',
    ).single();
    final food = Food.fromMap(Map<String, dynamic>.from(row));
    await setPreference(food.id, 'like');
    return food;
  }

  Future<Map<String, String>> preferences() async {
    final rows = await client
        .from('user_food_preferences')
        .select('food_id,preference')
        .eq('user_id', _userId);
    return {
      for (final row in rows)
        row['food_id'].toString(): row['preference'].toString(),
    };
  }

  Future<void> setPreference(String foodId, String preference) async {
    if (!const {'like', 'dislike'}.contains(preference)) {
      throw ArgumentError.value(preference, 'preference');
    }
    await client.from('user_food_preferences').upsert({
      'user_id': _userId,
      'food_id': foodId,
      'preference': preference,
    }, onConflict: 'user_id,food_id');
  }

  Future<void> clearPreference(String foodId) async {
    await client
        .from('user_food_preferences')
        .delete()
        .eq('user_id', _userId)
        .eq('food_id', foodId);
  }
}
