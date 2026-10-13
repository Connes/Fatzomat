import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Decision shares use the selected plan date end-to-end', () {
    final migration = File('supabase/migrations/20261012140000_date_aware_decision_sharing.sql').readAsStringSync();
    final askDateMigration = File('supabase/migrations/20261013190000_date_aware_decide_for_me.sql').readAsStringSync();
    final repository = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();
    final todayPage = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(migration, contains('p_source_plan_id uuid default null'));
    expect(migration, contains('source_plan.plan_date'));
    expect(migration, contains('set_personal_plan_for_date('));
    expect(migration, contains('plan_date >= current_date'));
    expect(migration, isNot(contains('share_row.plan_date <> current_date')));
    expect(repository, contains("'p_source_plan_id': sourcePlanId"));
    expect(repository, contains("'p_plan_date': _dateOnlyIso(planDate ?? DateTime.now())"));
    expect(todayPage, contains("sendDecisionMessage(\n        type: 'ask',\n        planDate: _selectedDate,"));
    expect(askDateMigration, contains('p_plan_date date default current_date'));
    expect(askDateMigration, contains("to_char(p_plan_date, 'DD.MM.YYYY')"));
    expect(askDateMigration, contains("values (cid,uid,partner,'ask',p_plan_date)"));
    expect(repository, contains('pendingDecisionShareForDate(DateTime date)'));
    expect(repository, contains(".eq('plan_date', planDate)"));
    expect(todayPage, contains('pendingDecisionShareForDate(requestedDate)'));
    expect(todayPage, contains('sourcePlanId: plan!.id'));
    expect(todayPage, contains(r'für den $_planDateLabel entschieden.'));
  });
}
