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
    expect(page, contains("'cuisine': widget.preference"));
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
  test('connection display name is captured and used for collaboration identity', () {
    final migration = File('supabase/migrations/20261008200000_connection_display_names.sql').readAsStringSync();
    final page = File('lib/features/shared/connection_page.dart').readAsStringSync();
    final repository = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();

    expect(migration, contains('display_name text'));
    expect(migration, contains('create_connection(p_display_name text)'));
    expect(migration, contains('join_connection(p_code text, p_display_name text)'));
    expect(migration, contains('insert into public.profiles(id, display_name)'));
    expect(migration, contains('connection_member_display_name'));
    expect(page, contains('Dein Name für diese Verbindung'));
    expect(page, contains("repo.createConnection(name)"));
    expect(page, contains("repo.joinConnection(value, name)"));
    expect(repository, contains("'p_display_name': displayName.trim()"));
  });

}
