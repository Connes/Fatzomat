import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Onboarding-Kategorien entsprechen den kanonischen Datenbankkategorien', () {
    final source = File('lib/core/constants.dart').readAsStringSync();

    expect(source, contains("'Meeresfrüchte'"));
    expect(source, contains("'Milchprodukte & Eier'"));
    expect(source, contains("'Gewürze & Kräuter'"));
    expect(source, contains("'Getreide & Beilagen'"));
    expect(source, isNot(contains("'Pflanzliche Alternativen'")));
    expect(source, isNot(contains("'Sonstiges'")));
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
    expect(source, contains("'Kresse'"));
    expect(source, contains("'Meeresfrüchte'"));
    expect(source, contains("'Chilischote'"));
    expect(source, contains("'coconut_milk'"));
    expect(source, contains("'sesame'"));
    expect(source, contains("'Getreide & Beilagen'"));
    expect(source, contains("'italian_herbs'"));
    expect(source, contains("'herbes_de_provence'"));
    expect(source, contains("'garam_masala'"));
  });

  test('Legacy-Onboarding-IDs werden in den kanonischen Katalog überführt', () {
    final source = File('supabase/migrations/20261102120000_consolidate_legacy_onboarding_foods.sql').readAsStringSync();

    expect(source, contains("('onb_hähnchen', 'chicken_breast')"));
    expect(source, contains("('onb_beef_steak', 'ground_beef')"));
    expect(source, contains("('onb_garnelen', 'shrimp')"));
    expect(source, contains("('onb_champignons', 'mushrooms')"));
    expect(source, contains("('onb_griechischer_joghurt', 'yogurt')"));
    expect(source, contains("('onb_joghurt', 'yogurt')"));
    expect(source, contains("('onb_mango', 'mango')"));
    expect(source, contains("('onb_pfirsich', 'peach')"));
    expect(source, contains("('onb_bohnen', 'green_beans')"));
    expect(source, contains('insert into public.user_food_preferences'));
    expect(source, contains('update public.recipe_ingredients'));
    expect(source, contains('raise exception'));
    expect(source, contains("set category = 'Meeresfrüchte'"));
    expect(source, contains("where created_by is null"));
  });

  test('Onboarding-Seed hat für Mango, Pfirsich und Kiwi vollständige Spaltenwerte', () {
    final source = File('supabase/migrations/202609140001_onboarding_and_custom_foods.sql').readAsStringSync();

    expect(source, contains("('mango','Mango','Obst','Stück')"));
    expect(source, contains("('peach','Pfirsich','Obst','Stück')"));
    expect(source, contains("('kiwi','Kiwi','Obst','Stück')"));
  });
}
