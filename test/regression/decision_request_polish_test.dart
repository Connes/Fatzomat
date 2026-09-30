import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V85 uses a lightweight decision message instead of a request lifecycle', () {
    final home = File('lib/features/home/home_page.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final repo = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();
    final migration = File('supabase/migrations/20260925070000_decision_messages_and_sharing.sql').readAsStringSync();
    final fixMigration = File('supabase/migrations/20260925120000_fix_decision_share_rpc.sql').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.31+243'));
    expect(home, contains("sendDecisionMessage(type: 'ask')"));
    expect(home, contains("'Entscheide Du'"));
    expect(home, isNot(contains("sendDecisionMessage(type: 'share')")));
    expect(home, isNot(contains('activeDecisionRequestCreatedByMe')));
    expect(today, contains("sendDecisionMessage(type: 'ask')"));
    expect(today, contains('sendDecisionMessage('));
    expect(today, contains('decisionType: plan!.decisionType'));
    expect(today, contains('decisionValue: plan!.decisionValue'));
    expect(today, contains('decisionName: plan!.displayTitle'));
    expect(today, contains("'Entscheidung teilen'"));
    expect(repo, contains('Future<void> sendDecisionMessage'));
    expect(repo, contains('PGRST202'));
    expect(repo, contains("'p_message_type': type"));
    expect(migration, contains('create table if not exists public.decision_shares'));
    expect(migration, contains("message_type in ('ask','share')"));
    expect(migration, contains('send_decision_message'));
    expect(migration, contains('personal_today_plans'));
    expect(fixMigration, contains('p_decision_type text default null'));
    expect(fixMigration, contains('p_decision_value text default null'));
    expect(fixMigration, contains('p_recipe_id uuid default null'));
  });
}
