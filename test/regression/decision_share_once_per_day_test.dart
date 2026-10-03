import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Decision sharing is limited to once per day and accepted shares are not shareable again', () {
    final migration = File('supabase/migrations/20260927193001_decision_share_once_per_day.sql').readAsStringSync();
    final repo = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final model = File('lib/data/models/today_plan.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final shareModel = File('lib/data/models/decision_share.dart').readAsStringSync();

    expect(migration, contains('uq_decision_shares_one_share_per_sender_day'));
    expect(migration, contains("ds.plan_date = current_date"));
    expect(migration, contains('Sie kann nur einmal geteilt werden.'));
    expect(migration, contains('source_plan_id'));
    expect(repo, contains(".eq('message_type', 'share')"));
    expect(repo, contains("map['is_shared'] = share != null"));
    expect(model, contains('final bool isShared;'));
    expect(model, contains('final bool isSharedAccepted;'));
    expect(today, contains("onShare: plan!.status == 'cooked' || plan!.isShared ? null : _shareTodayDecision"));
    expect(today, contains('Entscheidung bereits geteilt'));
    expect(today, contains('Entscheidung übernommen'));
    expect(shareModel, contains('acceptedAt'));
  });
}