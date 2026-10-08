import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decision requests resolve into the requester personal TodayPlan', () {
    final migration = File('supabase/migrations/20260920180000_connection_decision_personal_isolation.sql').readAsStringSync();
    expect(migration, contains('target_user := request_row.created_by'));
    expect(migration, contains('insert into public.personal_today_plans'));
    expect(migration, contains("p_result_type not in ('recipe', 'order', 'dine_out', 'surprise')"));
    expect(migration, isNot(contains('share_recipe_for_today')));
    expect(migration, contains("source\n    )\n    values(\n      target_user"));
  });

  test('restaurant selection is concrete and is resolved only after result selection', () {
    final page = File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();
    expect(page, contains('decisionRequestId: widget.decisionRequestId'));
    expect(page, contains('persistPersonalDecision: widget.decisionRequestId == null'));
    expect(page, contains("resultType: order ? 'order' : 'dine_out'"));
    expect(page, contains('final decisionValue = order'));
    expect(page, contains('jsonEncode({'));
    expect(page, contains("'cuisine': result.cuisine"));
    expect(page, isNot(contains("resultType: 'preference'")));
  });

  test('connection creation does not depend on pgcrypto random bytes', () {
    final migration = File('supabase/migrations/20260920182000_connection_code_generation_hardening.sql').readAsStringSync();
    expect(migration, contains('gen_random_uuid()'));
    expect(migration, isNot(contains('gen_random_bytes')));
  });

  test('recipe suggestion creation uses a guarded RPC to avoid recursive RLS', () {
    final migration = File('supabase/migrations/20260920184000_recipe_suggestion_rpc_authorization.sql').readAsStringSync();
    expect(migration, contains('security definer'));
    expect(migration, contains("revoke all on function public.create_recipe_suggestion(uuid)"));
    expect(migration, isNot(contains('create policy "recipe suggestions sender insert"')));
  });
}
