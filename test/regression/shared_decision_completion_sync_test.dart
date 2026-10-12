import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared decision completion propagates to the linked plan on the other device', () {
    final migration = File(
      'supabase/migrations/20261012160000_sync_shared_decision_completion.sql',
    ).readAsStringSync();

    expect(migration, contains('create or replace function public.sync_shared_decision_completion()'));
    expect(migration, contains("new.status = 'cooked'"));
    expect(migration, contains('ds.source_plan_id = new.id or ds.accepted_plan_id = new.id'));
    expect(migration, contains('set status = \'cooked\''));
    expect(migration, contains('and status = \'planned\''));
    expect(migration, contains('after update of status on public.personal_today_plans'));
  });
}
