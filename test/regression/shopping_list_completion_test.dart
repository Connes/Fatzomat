import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Einkaufsliste wird beim Kochen atomar geleert und vollständig abhackbar abgeschlossen', () {
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final migration = File('supabase/migrations/202610030001_cooked_clears_personal_shopping.sql').readAsStringSync();

    expect(repository, contains("client.rpc('update_personal_today_status'"));
    expect(repository, isNot(contains("delete()")));
    expect(migration, contains("if p_status = 'cooked' then"));
    expect(migration, contains('delete from public.shopping_items'));
    expect(migration, contains('where personal_today_plan_id = p_plan_id'));
    expect(today, contains("checked == items.length"));
    expect(today, contains("Einkaufsliste erledigt"));
    expect(today, contains("Einkaufsliste vollständig erledigt"));
  });
}
