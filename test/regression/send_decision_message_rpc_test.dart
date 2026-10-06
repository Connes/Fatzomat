import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('send_decision_message handles ask without touching current_plan', () {
    final migration = File(
      'supabase/migrations/20261006174754_fix_send_decision_message_ask_record.sql',
    ).readAsStringSync();

    expect(migration, contains("if p_message_type = 'share' then"));
    expect(migration, contains('else'));
    expect(
      migration,
      contains(
        "insert into public.decision_shares(\n      connection_id,sender_id,recipient_id,message_type,plan_date",
      ),
    );
    expect(
      migration,
      contains("values (\n      cid,uid,partner,'ask',current_date"),
    );
  });
}
