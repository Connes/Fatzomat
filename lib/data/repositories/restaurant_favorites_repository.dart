import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores each user's restaurant favorites in Supabase so they follow the
/// account across devices. SharedPreferences is used only for one-time
/// migration of favorites created by older app versions.
class RestaurantFavoritesRepository {
  static const _legacyStorageKey = 'fatzomat_restaurant_favorites_v1';

  final SupabaseClient? _client;
  SupabaseClient get client => _client ?? Supabase.instance.client;

  RestaurantFavoritesRepository({SupabaseClient? client}) : _client = client;

  String get _userId => client.auth.currentUser?.id ??
      (throw StateError('Bitte melde dich an, um Restaurantfavoriten zu verwenden.'));

  Future<List<Map<String, dynamic>>> all() async {
    await _migrateLegacyFavorites();
    final rows = await client
        .from('restaurant_favorites')
        .select('id,name,cuisine,address,phone,website,opening_hours')
        .eq('user_id', _userId)
        .order('name');
    return (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

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
    final key = _identity(restaurant);
    final favorites = await all();
    if (favorites.any((item) => _identity(item) == key)) return false;
    await client.from('restaurant_favorites').insert({
      'user_id': _userId,
      'name': name,
      'cuisine': _nullable(restaurant['cuisine']),
      'address': _nullable(restaurant['address']),
      'phone': _nullable(restaurant['phone']),
      'website': _nullable(restaurant['website']),
      'opening_hours': _nullable(restaurant['opening_hours']),
    });
    return true;
  }

  Future<void> remove(Map<String, dynamic> restaurant) async {
    final key = _identity(restaurant);
    if (key.isEmpty) return;
    final favorites = await all();
    final match = favorites.where((item) => _identity(item) == key);
    if (match.isEmpty) return;
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
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      await preferences.remove(_legacyStorageKey);
      return;
    }

    final rows = await client
        .from('restaurant_favorites')
        .select('name,address')
        .eq('user_id', userId);
    final existing = (rows as List)
        .whereType<Map>()
        .map((row) => _identity(Map<String, dynamic>.from(row)))
        .toSet();

    for (final item in decoded.whereType<Map>()) {
      final restaurant = Map<String, dynamic>.from(item);
      final name = restaurant['name']?.toString().trim() ?? '';
      if (name.isEmpty || !existing.add(_identity(restaurant))) continue;
      await client.from('restaurant_favorites').insert({
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
