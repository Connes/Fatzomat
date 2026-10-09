import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_exception.dart';
import '../../core/recipe_collection_events.dart';
import '../models/shopping_item.dart';
import '../models/today_plan.dart';
import '../models/personal_history_entry.dart';
import '../cache/offline_cache.dart';
import '../services/recipe_image_service.dart';

class PersonalTodayRepository {
  final SupabaseClient? _client;
  final OfflineCache? _offlineCache;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  OfflineCache get offlineCache => _offlineCache ?? OfflineCache();

  PersonalTodayRepository({SupabaseClient? client, OfflineCache? offlineCache})
      : _client = client,
        _offlineCache = offlineCache;

  Future<TodayPlan?> todayPlan({DateTime? date}) async {
    final planDate = _dateOnly(date ?? DateTime.now());
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      // The offline cache only represents the current day. Never display that
      // cached decision while browsing a different date.
      if (planDate != _dateOnly(DateTime.now())) return null;
      final cached = await offlineCache.readToday();
      return cached == null ? null : TodayPlan.fromMap(cached);
    }

    await _syncPendingDecision();

    try {
      final rows = await client
          .from('personal_today_plans')
          .select('id,recipe_id,decision_type,decision_value,plan_date,status,servings,created_at,recipes(name,description,servings,image_url,image_path)')
          .eq('user_id', userId)
          .eq('plan_date', planDate)
          .eq('status', 'planned')
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      final map = Map<String, dynamic>.from(rows.first);
      final sentShare = await client
          .from('decision_shares')
          .select('id,accepted_at,cancelled_at')
          .eq('sender_id', userId)
          .eq('source_plan_id', map['id'].toString())
          .eq('message_type', 'share')
          .isFilter('cancelled_at', null)
          .limit(1)
          .maybeSingle();
      final receivedShare = await client
          .from('decision_shares')
          .select('id,accepted_at,accepted_plan_id,cancelled_at')
          .eq('recipient_id', userId)
          .eq('accepted_plan_id', map['id'].toString())
          .eq('message_type', 'share')
          .isFilter('cancelled_at', null)
          .limit(1)
          .maybeSingle();
      final share = sentShare ?? receivedShare;
      map['is_shared'] = share != null;
      map['is_shared_accepted'] = share?['accepted_at'] != null;
      await _resolveNestedRecipeImage(map);
      return TodayPlan.fromMap(map);
    } catch (_) {
      // A single cached plan has no date key, so it is safe only for Today.
      if (planDate == _dateOnly(DateTime.now())) {
        final cached = await offlineCache.readToday();
        if (cached != null) return TodayPlan.fromMap(cached);
      }
      rethrow;
    }
  }

  Future<String> selectRecipeForToday(String recipeId, {int? servings, DateTime? date}) async {
    if (client.auth.currentUser == null) throw const AuthenticationException();
    if (recipeId.trim().isEmpty) throw StateError('Keine Recipe-ID vorhanden.');
    final result = await client.rpc('set_personal_plan_for_date', params: {
      'p_plan_date': _dateOnly(date ?? DateTime.now()),
      'p_decision_type': 'recipe',
      'p_recipe_id': recipeId,
      'p_servings': servings,
    });
    final id = result?.toString() ?? '';
    if (id.isEmpty) throw StateError('Der persönliche Tagesplan konnte nicht gespeichert werden.');
    // Any route can create the personal Today plan. Notify the persistent
    // "Meine Rezepte" tab immediately so it refreshes its "Für dich heute"
    // state without relying on a Realtime round-trip.
    RecipeCollectionEvents.notifyChanged();
    return id;
  }


  Future<String> selectDecision({
    required String type,
    required String value,
    String? recipeId,
    int? servings,
    DateTime? date,
  }) async {
    final normalizedType = type.trim();
    if (!{'recipe', 'order', 'dine_out', 'surprise'}.contains(normalizedType)) {
      throw StateError('Ungültige persönliche Entscheidung.');
    }
    if (normalizedType == 'recipe') {
      if (recipeId == null || recipeId.trim().isEmpty) throw StateError('Keine Recipe-ID vorhanden.');
      return selectRecipeForToday(recipeId, servings: servings, date: date);
    }
    if (value.trim().isEmpty) throw StateError('Die Auswahl darf nicht leer sein.');
    final localDecision = {
      'id': 'offline-${DateTime.now().millisecondsSinceEpoch}',
      'recipe_id': null,
      'decision_type': normalizedType,
      'decision_value': value.trim(),
      'status': 'planned',
      'servings': 2,
      'recipes': const <String, dynamic>{},
    };

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      await offlineCache.writeToday(localDecision);
      await offlineCache.writePendingTodayDecision({
        'decision_type': normalizedType,
        'decision_value': value.trim(),
      });
      return localDecision['id']!.toString();
    }

    if (client.auth.currentUser == null) throw const AuthenticationException();
    try {
      final result = await client.rpc('set_personal_plan_for_date', params: {
        'p_plan_date': _dateOnly(date ?? DateTime.now()),
        'p_decision_type': normalizedType,
        'p_decision_value': value.trim(),
      });
      final id = result?.toString() ?? '';
      if (id.isEmpty) throw StateError('Die persönliche Entscheidung konnte nicht gespeichert werden.');
      await offlineCache.clearPendingTodayDecision();
      return id;
    } catch (_) {
      // Keep real server errors intact. Only a detected offline state gets the local fallback.
      rethrow;
    }
  }

  Future<bool> updateServings(String planId, int servings) async {
    final result = await client.rpc('update_personal_today_plan_servings', params: {
      'p_plan_id': planId,
      'p_servings': servings,
    });
    return result == true;
  }

  Future<bool> removeTodayPlan(String planId) async {
    final result = await client.rpc('cancel_personal_today_plan', params: {'p_plan_id': planId});
    return result == true;
  }

  Future<bool> updateStatus(String planId, String status) async {
    final result = await client.rpc('update_personal_today_status', params: {
      'p_plan_id': planId,
      'p_status': status,
    });
    return result == true;
  }

  Future<String> replaceTodayPlan(String planId, String recipeId, {int? servings}) async {
    final current = await todayPlan();
    if (current == null || current.id != planId) {
      throw StateError('Persönlicher Tagesplan ist nicht mehr verfügbar.');
    }
    return selectRecipeForToday(recipeId, servings: servings);
  }


  Future<List<TodayPlan>> completedTodayPlans() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await client
        .from('personal_today_plans')
        .select('id,recipe_id,decision_type,decision_value,plan_date,status,servings,created_at,recipes(name,description,servings,image_url,image_path)')
        .eq('user_id', userId)
        .eq('plan_date', _dateOnly(DateTime.now()))
        .eq('status', 'cooked')
        .order('updated_at', ascending: false);
    final maps = rows.map((row) => Map<String, dynamic>.from(row)).toList();
    for (final map in maps) {
      await _resolveNestedRecipeImage(map);
    }
    return maps.map(TodayPlan.fromMap).toList(growable: false);
  }

  /// Returns the planned decisions for a specific local calendar date.
  /// Kept separate from [todayPlan] because the database supports multiple
  /// decisions for a date and shopping must include every planned recipe.
  Future<List<TodayPlan>> plannedPlansForDate(DateTime date) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await client
        .from('personal_today_plans')
        .select('id,recipe_id,decision_type,decision_value,plan_date,status,servings,created_at,recipes(name,description,servings,image_url,image_path)')
        .eq('user_id', userId)
        .eq('plan_date', _dateOnly(date))
        .eq('status', 'planned')
        .order('created_at', ascending: true);
    final maps = rows.map((row) => Map<String, dynamic>.from(row)).toList();
    for (final map in maps) {
      await _resolveNestedRecipeImage(map);
    }
    return maps.map(TodayPlan.fromMap).toList(growable: false);
  }

  /// Loads persisted items for multiple selected day plans without changing
  /// their IDs or checked state. Aggregation is deliberately a presentation
  /// concern, so each source row can still be checked independently.
  Future<List<ShoppingItem>> shoppingItemsForPlans(Iterable<String> planIds) async {
    final ids = planIds.toSet().where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) return const [];
    final rows = await client
        .from('shopping_items')
        .select('id,name,quantity,unit,checked,checked_by,food_id,source,personal_today_plan_id,foods(category)')
        .inFilter('personal_today_plan_id', ids)
        .order('name');
    return rows.map((row) => ShoppingItem.fromMap(Map<String, dynamic>.from(row))).toList(growable: false);
  }

  Future<List<PersonalHistoryEntry>> history({int limit = 100}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthenticationException();
    final rows = await client
        .from('personal_decision_history')
        .select('id,recipe_id,plan_id,action,source,created_at,recipes(name,image_url,image_path)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit.clamp(1, 500).toInt());
    final entries = rows.map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    for (final map in entries) {
      await _resolveNestedRecipeImage(map);
    }
    return entries.map(PersonalHistoryEntry.fromMap).toList(growable: false);
  }

  Future<List<ShoppingItem>> shoppingItems(String planId) async {
    final rows = await client
        .from('shopping_items')
        .select('id,name,quantity,unit,checked,checked_by,food_id,source,foods(category)')
        .eq('personal_today_plan_id', planId)
        .order('name');
    return rows.map((row) => ShoppingItem.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<void> setShoppingChecked(String itemId, bool checked) async {
    await client.from('shopping_items').update({
      'checked': checked,
      'checked_by': checked ? client.auth.currentUser?.id : null,
    }).eq('id', itemId);
  }

  Future<ShoppingItem> addShoppingItem({
    required String planId,
    required String name,
    num quantity = 1,
    String unit = '',
  }) async {
    final row = await client.from('shopping_items').insert({
      'personal_today_plan_id': planId,
      'name': name.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'source': 'manual',
    }).select('id,name,quantity,unit,checked,checked_by,food_id,source').single();
    return ShoppingItem.fromMap(Map<String, dynamic>.from(row));
  }

  Future<ShoppingItem> updateShoppingItem({
    required String itemId,
    required String name,
    num quantity = 1,
    String unit = '',
  }) async {
    final row = await client.from('shopping_items').update({
      'name': name.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
    }).eq('id', itemId).select('id,name,quantity,unit,checked,checked_by,food_id,source').single();
    return ShoppingItem.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteShoppingItem(String itemId) async {
    await client.from('shopping_items').delete().eq('id', itemId);
  }


  Future<void> _resolveNestedRecipeImage(Map<String, dynamic> map) async {
    final recipe = map['recipes'];
    if (recipe is! Map) return;
    final nested = Map<String, dynamic>.from(recipe);
    final path = nested['image_path']?.toString().trim() ?? '';
    if (path.isEmpty) return;
    final signedUrl = await RecipeImageService(client: client).resolveSignedUrl(path);
    if (signedUrl != null && signedUrl.isNotEmpty) {
      nested['image_url'] = signedUrl;
    }
    map['recipes'] = nested;
  }

  Future<void> _syncPendingDecision() async {
    final pending = await offlineCache.readPendingTodayDecision();
    if (pending == null) return;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    final type = pending['decision_type']?.toString();
    final value = pending['decision_value']?.toString();
    if (type == null || value == null || value.trim().isEmpty) {
      await offlineCache.clearPendingTodayDecision();
      return;
    }

    await client.rpc('set_personal_today_decision', params: {
      'p_decision_type': type,
      'p_decision_value': value,
    });
    await offlineCache.clearPendingTodayDecision();
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
