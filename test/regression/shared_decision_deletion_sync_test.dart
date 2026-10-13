import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deleting either accepted shared plan deletes its counterpart server-side', () {
    final migration = File(
      'supabase/migrations/20261013153000_sync_shared_decision_deletion.sql',
    ).readAsStringSync();

    expect(migration, contains('create or replace function public.sync_shared_decision_deletion()'));
    expect(migration, contains('before delete on public.personal_today_plans'));
    expect(migration, contains("ds.message_type = 'share'"));
    expect(migration, contains('ds.cancelled_at is null'));
    expect(migration, contains('ds.source_plan_id is not null'));
    expect(migration, contains('ds.accepted_plan_id is not null'));
    expect(migration, contains('ds.source_plan_id = old.id or ds.accepted_plan_id = old.id'));
    expect(migration, contains('set cancelled_at = now()'));
    expect(migration, contains('delete from public.personal_today_plans p'));
    expect(migration, contains('p.id = any(counterpart_plan_ids)'));
    expect(migration, contains('p.id <> old.id'));
    expect(migration, contains('revoke all on function public.sync_shared_decision_deletion() from public, anon, authenticated'));
  });

  test('deletion sync ignores private plans and cancelled or unaccepted shares', () {
    final migration = File(
      'supabase/migrations/20261013153000_sync_shared_decision_deletion.sql',
    ).readAsStringSync();

    expect(migration, contains("ds.cancelled_at is null"));
    expect(migration, contains('ds.source_plan_id is not null'));
    expect(migration, contains('ds.accepted_plan_id is not null'));
    expect(migration, contains('ds.source_plan_id = old.id or ds.accepted_plan_id = old.id'));
  });
}
