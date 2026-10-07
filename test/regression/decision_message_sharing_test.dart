import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V85 supports sharing the current personal Today decision at any time', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final repo = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();
    final model = File('lib/data/models/decision_share.dart').readAsStringSync();
    final notification = File('lib/data/models/app_notification.dart').readAsStringSync();
    final page = File('lib/features/shared/decision_share_page.dart').readAsStringSync();
    final migration = File('supabase/migrations/20260925070000_decision_messages_and_sharing.sql').readAsStringSync();
    final fixMigration = File('supabase/migrations/20260925120000_fix_decision_share_rpc.sql').readAsStringSync();
    final acceptMigration = File('supabase/migrations/20260927100000_accept_decision_share_personally.sql').readAsStringSync();
    final rejectMigration = File('supabase/migrations/20261007091500_reject_decision_share.sql').readAsStringSync();
    final pushService = File('lib/core/push_notification_service.dart').readAsStringSync();

    expect(today, contains("sendDecisionMessage("));
    expect(today, contains('decisionType: plan!.decisionType'));
    expect(today, contains('decisionValue: plan!.decisionValue'));
    expect(today, contains('decisionName: plan!.displayTitle'));
    expect(today, contains("label: const Text('Entscheidung teilen')"));
    expect(repo, contains('Future<DecisionShare?> decisionShare'));
    expect(repo, contains('pendingDecisionShareForToday'));
    expect(repo, contains('rejectDecisionShare'));
    expect(repo, contains('PGRST202'));
    expect(repo, contains("'p_message_type': type"));
    expect(model, contains('decisionName'));
    expect(model, contains('imageUrl'));
    expect(notification, contains('decisionShareId'));
    expect(page, contains('Entscheidung geteilt'));
    expect(page, contains('Entscheide Du'));
    expect(page, contains('Deine verbundene Person möchte, dass du heute die Essensentscheidung triffst.'));
    expect(page, contains("Text(share.isAsk ? \"Los geht's\" : 'Übernehmen')"));
    expect(page, contains('acceptDecisionShare(share.id)'));
    expect(page, contains('A shared recipe'));
    expect(page, contains('belongs to the sender, so a direct client-side INSERT into'));
    expect(page, contains('creates an independent recipe copy when necessary'));
    expect(repo, contains("'accept_decision_share'"));
    expect(repo, contains("'reject_decision_share'"));
    expect(pushService, contains("const TodayPage()"));
    expect(pushService, isNot(contains('DecisionSharePage')));
    expect(page, contains('MaterialPageRoute(builder: (_) => const TodayPage())'));
    expect(page, contains('pushReplacement'));
    expect(page, contains('if (widget.share.isAsk)'));
    expect(page, contains('// \"Entscheide Du\" is only a request/message.'));
    expect(page, contains('return;'));

    expect(migration, contains("if p_message_type = 'share' then"));
    expect(fixMigration, contains('p_decision_type text default null'));
    expect(fixMigration, contains('p_decision_value text default null'));
    expect(fixMigration, contains('p_recipe_id uuid default null'));
    expect(fixMigration, contains('decision_label := coalesce'));
    expect(acceptMigration, contains('create or replace function public.accept_decision_share'));
    expect(acceptMigration, contains('security definer'));
    expect(acceptMigration, contains('accepted_recipe_id'));
    expect(acceptMigration, contains('public.set_personal_today_plan'));
    expect(acceptMigration, contains('public.set_personal_today_decision'));
    expect(rejectMigration, contains('create or replace function public.reject_decision_share'));
    expect(rejectMigration, contains('rejected_at'));
    expect(rejectMigration, contains('rejected_by'));
  });
}
