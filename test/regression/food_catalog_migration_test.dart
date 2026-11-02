import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Onboarding-Kategorien entsprechen den kanonischen Datenbankkategorien', () {
    final source = File('lib/core/constants.dart').readAsStringSync();

    expect(source, contains("'Meeresfrüchte'"));
    expect(source, contains("'Milchprodukte & Eier'"));
    expect(source, contains("'Gewürze & Kräuter'"));
    expect(source, contains("'Pflanzliche Alternativen'"));
    expect(source, isNot(contains("'Milchprodukte',")));
    expect(source, isNot(contains("'Gewürze',")));
  });

  test('Lebensmittelkatalog-Migration konsolidiert Varianten und bewahrt Referenzen', () {
    final source = File('supabase/migrations/20261102090000_refine_onboarding_food_catalog.sql').readAsStringSync();

    expect(source, contains("('chicken_thigh', 'chicken_breast')"));
    expect(source, contains("('greek_yogurt', 'yogurt')"));
    expect(source, contains("('bratwurst', 'sausage')"));
    expect(source, contains('insert into public.user_food_preferences'));
    expect(source, contains('update public.recipe_ingredients'));
    expect(source, contains("'Gemischtes Hackfleisch'"));
    expect(source, contains("'Pflanzliche Alternativen'"));
    expect(source, contains("'Kresse'"));
    expect(source, contains("'Meeresfrüchte'"));
    expect(source, contains("'italian_herbs'"));
    expect(source, contains("'herbes_de_provence'"));
    expect(source, contains("'garam_masala'"));
  });

  test('Onboarding-Seed hat für Mango, Pfirsich und Kiwi vollständige Spaltenwerte', () {
    final source = File('supabase/migrations/202609140001_onboarding_and_custom_foods.sql').readAsStringSync();

    expect(source, contains("('mango','Mango','Obst','Stück')"));
    expect(source, contains("('peach','Pfirsich','Obst','Stück')"));
    expect(source, contains("('kiwi','Kiwi','Obst','Stück')"));
  });
}
