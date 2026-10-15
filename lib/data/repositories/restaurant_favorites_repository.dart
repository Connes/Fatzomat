import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores personal restaurant favorites independently from daily decisions.
class RestaurantFavoritesRepository {
  static const _storageKey = 'fatzomat_restaurant_favorites_v1';

  Future<List<Map<String, dynamic>>> all() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => (item['name']?.toString().trim() ?? '').isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
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
    final preferences = await SharedPreferences.getInstance();
    final favorites = (await all()).toList();
    final key = _identity(restaurant);
    if (favorites.any((item) => _identity(item) == key)) return false;
    favorites.add({
      'name': name,
      'cuisine': _nullable(restaurant['cuisine']),
      'address': _nullable(restaurant['address']),
      'phone': _nullable(restaurant['phone']),
      'website': _nullable(restaurant['website']),
      'opening_hours': _nullable(restaurant['opening_hours']),
    });
    await preferences.setString(_storageKey, jsonEncode(favorites));
    return true;
  }

  Future<void> remove(Map<String, dynamic> restaurant) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _identity(restaurant);
    final favorites = (await all()).where((item) => _identity(item) != key).toList();
    await preferences.setString(_storageKey, jsonEncode(favorites));
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
