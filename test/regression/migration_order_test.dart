import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supabase migration timestamps are unique', () {
    final files = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .where((name) => RegExp(r'^\d{14}_.*\.sql$').hasMatch(name))
        .toList();
    final timestamps = files.map((name) => name.substring(0, 14)).toList();
    expect(timestamps.length, timestamps.toSet().length);
  });

  test('date-aware plan updates preserve checked shopping rows', () {
    final migration = File(
      'supabase/migrations/20261010100000_date_aware_personal_planning.sql',
    ).readAsStringSync();

    expect(migration, contains('UPDATE public.shopping_items si'));
    expect(migration, contains("AND si.source = 'recipe'"));
    expect(migration, contains('NOT EXISTS'));
    expect(
      migration,
      contains("ELSE\n    DELETE FROM public.shopping_items\n    WHERE personal_today_plan_id = pid AND source = 'recipe'"),
    );
  });

  test('date-aware planning defaults missing recipe servings safely', () {
    final planningMigration = File(
      'supabase/migrations/20261010100000_date_aware_personal_planning.sql',
    ).readAsStringSync();
    final servingsMigration = File(
      'supabase/migrations/20261010103000_update_personal_plan_servings.sql',
    ).readAsStringSync();

    expect(
      planningMigration,
      contains('greatest(coalesce(r.servings, 1), 1) INTO base_servings'),
    );
    expect(
      servingsMigration,
      contains('greatest(coalesce(servings, 1), 1) INTO base_servings'),
    );
  });
}
