import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disconnect deletes the connection itself so both members are removed atomically', () {
    final migration = File(
      'supabase/migrations/20261013170000_disconnect_connection_for_both_members.sql',
    ).readAsStringSync();

    expect(migration, contains('create or replace function public.disconnect_connection()'));
    expect(migration, contains('delete from public.connections c'));
    expect(migration, contains('mine.user_id = auth.uid()'));
    expect(migration, contains('grant execute on function public.disconnect_connection() to authenticated'));
    expect(migration, contains('revoke all on function public.disconnect_connection() from public, anon'));
  });

  test('removing a member or deleting their auth user cleans up the remaining connection', () {
    final migration = File(
      'supabase/migrations/20261013170000_disconnect_connection_for_both_members.sql',
    ).readAsStringSync();

    expect(migration, contains('after delete on public.connection_members'));
    expect(migration, contains('public.cleanup_connection_after_member_removal()'));
    expect(migration, contains('select count(*)'));
    expect(migration, contains(') < 2'));
    expect(migration, contains('delete from public.connections'));
    expect(migration, contains('references auth.users(id) on delete cascade').isFalse);
  });

  test('connection cleanup does not delete personal decision or recipe data', () {
    final migration = File(
      'supabase/migrations/20261013170000_disconnect_connection_for_both_members.sql',
    ).readAsStringSync();

    expect(migration, isNot(contains('delete from public.personal_today_plans')));
    expect(migration, isNot(contains('delete from public.recipes')));
    expect(migration, isNot(contains('delete from public.profiles')));
  });
}
