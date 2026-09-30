import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight cache for non-sensitive, last-known application data.
/// It is not a source of truth and must never be used for authorization.
class OfflineCache {
  static const _foodsKey = 'cache.foods.v1';
  static const _todayKey = 'cache.today_plan.v1';
  static const _pendingTodayDecisionKey = 'cache.pending_today_decision.v1';
  SharedPreferencesAsync? _prefs;

  OfflineCache({SharedPreferencesAsync? prefs}) : _prefs = prefs;

  SharedPreferencesAsync get _preferences => _prefs ??= SharedPreferencesAsync();

  Future<void> writeFoods(List<Map<String, dynamic>> foods) =>
      _write(_foodsKey, foods);

  Future<List<Map<String, dynamic>>> readFoods() async {
    final value = await _preferences.getString(_foodsKey);
    if (value == null) return const [];
    return _decodeList(value);
  }

  Future<void> writeToday(Map<String, dynamic>? plan) async {
    if (plan == null) {
      await _preferences.remove(_todayKey);
      return;
    }
    await _write(_todayKey, plan);
  }

  Future<Map<String, dynamic>?> readToday() async {
    final value = await _preferences.getString(_todayKey);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _preferences.remove(_foodsKey);
    await _preferences.remove(_todayKey);
    await _preferences.remove(_pendingTodayDecisionKey);
  }
  Future<void> writePendingTodayDecision(Map<String, dynamic> decision) =>
      _write(_pendingTodayDecisionKey, decision);

  Future<Map<String, dynamic>?> readPendingTodayDecision() async {
    final value = await _preferences.getString(_pendingTodayDecisionKey);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingTodayDecision() =>
      _preferences.remove(_pendingTodayDecisionKey);


  Future<void> _write(String key, Object value) =>
      _preferences.setString(key, jsonEncode(value));

  List<Map<String, dynamic>> _decodeList(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
