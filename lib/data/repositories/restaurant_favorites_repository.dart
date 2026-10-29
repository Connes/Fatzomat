import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores each user's restaurant favorites in Supabase so they follow the
/// account across devices. SharedPreferences is used only for one-time
/// migration of favorites created by older app versions.
class RestaurantFavoritesRepository {
  static const _legacyStorageKey = 'fatzomat_restaurant_favorites_v1';
  static const _legacyCorruptBackupPrefix = '${_legacyStorageKey}_corrupt_backup_';

  final SupabaseClient? _client;
  SupabaseClient get client => _client ?? Supabase.instance.client;

  RestaurantFavoritesRepository({SupabaseClient? client}) : _client = client;

  String get _userId => client.auth.currentUser?.id ??
      (throw StateError('Bitte melde dich an, um Restaurantfavoriten zu verwenden.'));

  Future<List<Map<String, dynamic>>> all() async {
    await _migrateLegacyFavorites();
    final rows = await client
        .from('restaurant_favorites')
        .select('id,user_id,name,cuisine,address,phone,website,opening_hours')
        .order('name');
    return (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  bool canManage(Map<String, dynamic> restaurant) =>
      restaurant['user_id']?.toString() == _userId;

  Future<bool> contains(Map<String, dynamic> restaurant) async {
    final key = _identity(restaurant);
    if (key.isEmpty) return false;
    final favorites = await all();
    return favorites.any((item) => _identity(item) == key);
  }

  Future<bool> add(Map<String, dynamic> restaurant) async {
    final name = restaurant['name']?.toString().trim() ?? '';
    if (name.isEmpty) throw ArgumentError('Ein Restaurantname ist erforderlich.');
    await _migrateLegacyFavorites();
    return _insertFavorite({
      'user_id': _userId,
      'name': name,
      'cuisine': _nullable(restaurant['cuisine']),
      'address': _nullable(restaurant['address']),
      'phone': _nullable(restaurant['phone']),
      'website': _nullable(restaurant['website']),
      'opening_hours': _nullable(restaurant['opening_hours']),
    });
  }

  /// The database's normalized unique index is the final authority when
  /// separate screens or requests try to add the same favorite concurrently.
  Future<bool> _insertFavorite(Map<String, dynamic> row) async {
    try {
      await client.from('restaurant_favorites').insert(row);
      return true;
    } on PostgrestException catch (error) {
      if (error.code == '23505') return false;
      rethrow;
    }
  }

  Future<void> remove(Map<String, dynamic> restaurant) async {
    final key = _identity(restaurant);
    if (key.isEmpty) return;
    final favorites = await all();
    final match = favorites.where((item) => _identity(item) == key);
    if (match.isEmpty || match.first['user_id']?.toString() != _userId) return;
    await client
        .from('restaurant_favorites')
        .delete()
        .eq('user_id', _userId)
        .eq('id', match.first['id'].toString());
  }

  Future<void> _migrateLegacyFavorites() async {
    final userId = _userId;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_legacyStorageKey);
    if (raw == null || raw.trim().isEmpty) return;

    // Keep the legacy value until every row has been safely uploaded. This
    // makes an interrupted migration retryable without silently losing data.
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      // Preserve the corrupt legacy payload for diagnosis instead of making
      // every future favorites read fail or silently discarding the bytes.
      final backupKey = '$_legacyCorruptBackupPrefix${DateTime.now().millisecondsSinceEpoch}';
      await preferences.setString(backupKey, raw);
      await preferences.remove(_legacyStorageKey);
      return;
    }
    if (decoded is! List) {
      final backupKey = '$_legacyCorruptBackupPrefix${DateTime.now().millisecondsSinceEpoch}';
      await preferences.setString(backupKey, raw);
      await preferences.remove(_legacyStorageKey);
      return;
    }

    final rows = await client
        .from('restaurant_favorites')
        .select('name,address')
        ;
    final existing = (rows as List)
        .whereType<Map>()
        .map((row) => _identity(Map<String, dynamic>.from(row)))
        .toSet();

    for (final item in decoded.whereType<Map>()) {
      final restaurant = Map<String, dynamic>.from(item);
      final name = restaurant['name']?.toString().trim() ?? '';
      if (name.isEmpty || !existing.add(_identity(restaurant))) continue;
      await _insertFavorite({
        'user_id': userId,
        'name': name,
        'cuisine': _nullable(restaurant['cuisine']),
        'address': _nullable(restaurant['address']),
        'phone': _nullable(restaurant['phone']),
        'website': _nullable(restaurant['website']),
        'opening_hours': _nullable(restaurant['opening_hours']),
      });
    }
    await preferences.remove(_legacyStorageKey);
  }

  String _identity(Map<String, dynamic> restaurant) {
    final name = (restaurant['name']?.toString() ?? '').trim().toLowerCase();
    final address = (restaurant['address']?.toString() ?? '').trim().toLowerCase();
    return '$name|$address';
  }

  String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
