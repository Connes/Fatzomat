import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/connection_info.dart';
import '../models/decision_request.dart';
import '../models/decision_share.dart';
import '../models/recipe_suggestion.dart';
import '../models/shopping_item.dart';
import '../services/recipe_image_service.dart';

class CollaborationRepository {
  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;
  CollaborationRepository({SupabaseClient? client}) : _client = client;

  Future<String?> connectionCode() async {
    final info = await connectionInfo();
    return info?.code;
  }

  Future<ConnectionInfo?> connectionInfo() async {
    final rows = await client.rpc('connection_info');
    if (rows is! List || rows.isEmpty) return null;
    return ConnectionInfo.fromMap(Map<String, dynamic>.from(rows.first as Map));
  }


  Future<String?> connectionPartnerId() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final connectionId = await client.rpc('current_connection_id');
    if (connectionId == null) return null;
    final rows = await client
        .from('connection_members')
        .select('user_id')
        .eq('connection_id', connectionId.toString())
        .neq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['user_id']?.toString();
  }

  Future<DecisionRequest> createDecisionRequest({required String assignedTo}) async {
    final result = await client.rpc('create_decision_request', params: {
      'p_assigned_to': assignedTo,
    });
    return DecisionRequest.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<DecisionRequest?> activeDecisionRequestForMe() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await client
        .from('decision_requests')
        .select('id,connection_id,created_by,assigned_to,status,decision_mode,result_type,result_id,created_at,resolved_at')
        .eq('assigned_to', userId)
        .inFilter('status', ['pending', 'accepted'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : DecisionRequest.fromMap(Map<String, dynamic>.from(row));
  }

  Future<DecisionRequest?> pendingDecisionRequestForMe() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await client
        .from('decision_requests')
        .select('id,connection_id,created_by,assigned_to,status,decision_mode,result_type,result_id,created_at,resolved_at')
        .eq('assigned_to', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : DecisionRequest.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> acceptDecisionRequest(String requestId) async {
    final result = await client.rpc('accept_decision_request', params: {'p_request_id': requestId});
    if (result != true) {
      throw Exception('Die Entscheidungsanfrage ist nicht mehr offen.');
    }
  }

  Future<void> resolveDecisionRequest({
    required String requestId,
    required String decisionMode,
    required String resultType,
    required String resultId,
    int? servings,
  }) async {
    await client.rpc('resolve_decision_request', params: {
      'p_request_id': requestId,
      'p_decision_mode': decisionMode,
      'p_result_type': resultType,
      'p_result_id': resultId,
      'p_servings': servings,
    });
  }

  Future<DecisionRequest?> latestResolvedDecisionRequestCreatedByMe() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await client
        .from('decision_requests')
        .select('id,connection_id,created_by,assigned_to,status,decision_mode,result_type,result_id,created_at,resolved_at')
        .eq('created_by', userId)
        .eq('status', 'resolved')
        .gte('resolved_at', DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String())
        .order('resolved_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : DecisionRequest.fromMap(Map<String, dynamic>.from(row));
  }

  Future<DecisionRequest?> activeDecisionRequestCreatedByMe() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await client
        .from('decision_requests')
        .select('id,connection_id,created_by,assigned_to,status,decision_mode,result_type,result_id,created_at,resolved_at')
        .eq('created_by', userId)
        .inFilter('status', ['pending', 'accepted'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : DecisionRequest.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> cancelDecisionRequest(String requestId) async {
    await client.rpc('cancel_decision_request', params: {'p_request_id': requestId});
  }

  Future<void> sendDecisionMessage({
    required String type,
    String? decisionType,
    String? decisionValue,
    String? decisionName,
    String? imageUrl,
    String? recipeId,
    int? servings,
  }) async {
    try {
      // V85.1 accepts the exact Today snapshot. This avoids a second read of
      // personal_today_plans and is the preferred path on current backends.
      await client.rpc('send_decision_message', params: {
        'p_message_type': type,
        'p_decision_type': decisionType,
        'p_decision_value': decisionValue,
        'p_decision_name': decisionName,
        'p_image_url': imageUrl,
        'p_recipe_id': recipeId,
        'p_servings': servings,
      });
    } on PostgrestException catch (error) {
      // Existing installations may have V85 deployed but not V85.1 yet.
      // PostgREST then cannot resolve the seven-parameter function and the
      // generic UI error used to hide that fact. The V85 one-parameter RPC is
      // still valid for both message types, so use it only for a signature /
      // schema-cache miss. Do not mask real validation, RLS or connection
      // errors by falling back.
      final code = error.code?.toUpperCase() ?? '';
      final text = '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'.toLowerCase();
      final signatureUnavailable =
          code == 'PGRST202' ||
          code == '42883' ||
          text.contains('could not find the function') ||
          text.contains('function public.send_decision_message') && text.contains('does not exist');
      if (!signatureUnavailable) rethrow;

      await client.rpc('send_decision_message', params: {
        'p_message_type': type,
      });
    }
  }

  Future<DecisionShare?> decisionShare(String shareId) async {
    final row = await client
        .from('decision_shares')
        .select('id,connection_id,sender_id,recipient_id,message_type,plan_date,source_plan_id,decision_type,decision_value,decision_name,image_url,recipe_id,servings,accepted_at,created_at')
        .eq('id', shareId)
        .maybeSingle();
    return row == null ? null : DecisionShare.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> acceptDecisionShare(String shareId) async {
    final id = shareId.trim();
    if (id.isEmpty) throw StateError('Keine Entscheidungs-ID vorhanden.');
    await client.rpc('accept_decision_share', params: {
      'p_share_id': id,
    });
  }

  Future<bool> disconnectConnection() async {
    final result = await client.rpc('disconnect_connection');
    return result == true;
  }

  Future<String> createConnection() async {
    final result = await client.rpc('create_connection');
    return result.toString();
  }

  Future<void> joinConnection(String code) async {
    await client.rpc('join_connection', params: {'p_code': code.trim()});
  }


  Future<Map<String, dynamic>?> currentSharedRecipePlan() async {
    final rows = await client
        .from('shared_recipe_plans')
        .select('id,recipe_id,status,servings,plan_date,recipes(name,description,image_url,image_path)')
        .eq('plan_date', DateTime.now().toIso8601String().substring(0, 10))
        .neq('status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final result = Map<String, dynamic>.from(rows.first as Map);
    final recipe = result['recipes'];
    if (recipe is Map) {
      final nested = Map<String, dynamic>.from(recipe);
      final path = nested['image_path']?.toString().trim() ?? '';
      if (path.isNotEmpty) {
        final signedUrl = await RecipeImageService(client: client).resolveSignedUrl(path);
        if (signedUrl != null && signedUrl.isNotEmpty) nested['image_url'] = signedUrl;
      }
      result['recipes'] = nested;
    }
    return result;
  }

  Future<List<ShoppingItem>> shoppingItems(String planId) async {
    final rows = await client
        .from('shopping_items')
        .select('id,name,quantity,unit,checked,checked_by,food_id,source,foods(category)')
        .eq('shared_recipe_plan_id', planId)
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
      'shared_recipe_plan_id': planId,
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

  Future<List<AppNotification>> notifications() async {
    const baseColumns =
        'id,type,title,body,recipe_id,shared_recipe_plan_id,decision_request_id,recipe_suggestion_id,read_at,created_at';

    // decision_share_id was introduced with the V85 decision-message
    // migration. Keep the inbox readable when an existing installation has
    // not received that migration yet. Without this fallback, one missing
    // column makes the entire notification screen look like an offline error.
    List<dynamic> rows;
    try {
      rows = await client
          .from('app_notifications')
          .select('$baseColumns,decision_share_id')
          .order('created_at', ascending: false)
          .limit(30);
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      final details = (error.details ?? '').toString().toLowerCase();
      final isMissingDecisionShareColumn =
          (message.contains('decision_share_id') || details.contains('decision_share_id')) &&
          (message.contains('column') || details.contains('column'));
      if (!isMissingDecisionShareColumn) rethrow;

      rows = await client
          .from('app_notifications')
          .select(baseColumns)
          .order('created_at', ascending: false)
          .limit(30);
    }

    return rows
        .map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<DecisionRequest?> decisionRequest(String requestId) async {
    final row = await client
        .from('decision_requests')
        .select('id,connection_id,created_by,assigned_to,status,decision_mode,result_type,result_id,created_at,resolved_at')
        .eq('id', requestId)
        .maybeSingle();
    return row == null ? null : DecisionRequest.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> markAllNotificationsRead() async {
    await client
        .from('app_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .isFilter('read_at', null);
  }

  Future<RecipeSuggestion> suggestRecipe(String recipeId) async {
    final result = await client.rpc('create_recipe_suggestion', params: {
      'p_recipe_id': recipeId,
    });
    return RecipeSuggestion.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<RecipeSuggestion?> recipeSuggestion(String suggestionId) async {
    final row = await client
        .from('recipe_suggestions')
        .select('id,connection_id,recipe_id,suggested_by,suggested_to,status,created_at,responded_at')
        .eq('id', suggestionId)
        .maybeSingle();
    return row == null ? null : RecipeSuggestion.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<RecipeSuggestion>> receivedRecipeSuggestions({bool pendingOnly = false}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const [];
    var query = client
        .from('recipe_suggestions')
        .select('id,connection_id,recipe_id,suggested_by,suggested_to,status,created_at,responded_at')
        .eq('suggested_to', userId);
    if (pendingOnly) query = query.eq('status', 'pending');
    final rows = await query.order('created_at', ascending: false).limit(50);
    return rows.map((row) => RecipeSuggestion.fromMap(Map<String, dynamic>.from(row))).toList(growable: false);
  }

  Future<List<RecipeSuggestion>> sentRecipeSuggestions() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await client
        .from('recipe_suggestions')
        .select('id,connection_id,recipe_id,suggested_by,suggested_to,status,created_at,responded_at')
        .eq('suggested_by', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((row) => RecipeSuggestion.fromMap(Map<String, dynamic>.from(row))).toList(growable: false);
  }

  Future<RecipeSuggestion> respondToRecipeSuggestion(String suggestionId, {required bool accept}) async {
    final result = await client.rpc('respond_to_recipe_suggestion', params: {
      'p_suggestion_id': suggestionId,
      'p_accept': accept,
    });
    return RecipeSuggestion.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<String> shareRecipeForToday(String recipeId, {int? servings}) async {
    final result = await client.rpc('share_recipe_for_today', params: {
      'p_recipe_id': recipeId,
      'p_servings': servings,
    });
    final id = result?.toString() ?? '';
    if (id.isEmpty) throw StateError('Die gemeinsame Mahlzeit konnte nicht festgelegt werden.');
    return id;
  }

  Future<bool> updateSharedRecipePlanServings(String planId, int servings) async {
    final result = await client.rpc('update_shared_recipe_plan_servings', params: {'p_plan_id': planId, 'p_servings': servings});
    return result == true;
  }

  Future<bool> removeSharedRecipePlan(String planId) async {
    final result = await client.rpc('cancel_shared_recipe_plan', params: {'p_plan_id': planId});
    return result == true;
  }

  Future<String> replaceSharedRecipePlan(String planId, String recipeId, {int? servings}) async {
    final result = await client.rpc('replace_shared_recipe_plan', params: {
      'p_plan_id': planId,
      'p_recipe_id': recipeId,
      'p_servings': servings,
    });
    return result.toString();
  }

  Future<bool> updateSharedRecipeStatus(String planId, String status) async {
    final result = await client.rpc('update_shared_recipe_status', params: {'p_plan_id': planId, 'p_status': status});
    return result == true;
  }

  Future<void> markNotificationRead(String id) async {
    await client.from('app_notifications').update({'read_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<int> unreadCount() async {
    final rows = await client.from('app_notifications').select('id').isFilter('read_at', null);
    return (rows as List).length;
  }

}
