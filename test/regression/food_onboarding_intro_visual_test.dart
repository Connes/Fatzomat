import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Lebensmittel-Onboarding verwendet die reduzierte Einrichtungsstruktur', () {
    final source = File('lib/features/foods/food_onboarding_page.dart').readAsStringSync();
    final designSource = File('lib/core/app_design.dart').readAsStringSync();
    final setupStart = source.indexOf('final shown = visibleFoods;');
    final introStart = source.indexOf('class _FoodOnboardingIntro extends StatelessWidget');
    expect(setupStart, greaterThanOrEqualTo(0));
    expect(introStart, greaterThan(setupStart));
    final setupSource = source.substring(setupStart, introStart);

    expect(source, contains('backgroundType: TogetherBackgroundType.settings'));
    expect(source, contains('body: SafeArea('));
    expect(source, contains('CustomScrollView('));
    expect(source, contains('SliverFillRemaining('));
    expect(source, isNot(contains('child: SingleChildScrollView(')));

    // The setup page must no longer show the compact top BrandMark header.
    expect(setupSource, isNot(contains('BrandMark(')));
    expect(setupSource, isNot(contains("padding: const EdgeInsets.fromLTRB(20, 18, 20, 8)")));
    expect(setupSource, isNot(contains("Text('Später änderbar'")));

    // The existing add-food action is moved from the former top header into the
    // counts row, exactly where the old "Später änderbar" affordance was.
    expect(setupSource, contains("ValueKey<String>('food_onboarding_add_food_button')"));
    expect(setupSource, contains("tooltip: 'Eigenes Lebensmittel hinzufügen'"));
    final addButtonIndex = setupSource.indexOf("ValueKey<String>('food_onboarding_add_food_button')");
    final countsIndex = setupSource.indexOf('_CountPill(icon: Icons.favorite_rounded');
    expect(addButtonIndex, greaterThan(countsIndex));

    // The existing real app icon is used in the setup card and centered with its title.
    expect(designSource, contains("'assets/branding/app_icon.png'"));
    expect(setupSource, contains("'assets/branding/app_icon.png'"));
    expect(setupSource, contains("ValueKey<String>('food_onboarding_setup_app_logo')"));
    expect(setupSource, contains('crossAxisAlignment: CrossAxisAlignment.center'));
    expect(setupSource, contains('textAlign: TextAlign.center'));
    expect(setupSource, contains("ValueKey<String>('food_onboarding_setup_title')"));
    expect(setupSource, contains("'Kurz einrichten'"));

    // Removed from the setup UI.
    expect(setupSource, isNot(contains("hintText: 'Lebensmittel suchen'")));
    expect(setupSource, isNot(contains('TextField(')));
    expect(setupSource, isNot(contains("label: const Text('Lieblingsrezept speichern')")));
    expect(setupSource, isNot(contains('OutlinedButton.icon(')));

    // The final onboarding action remains.
    expect(source, contains("label: const Text('Auswahl speichern')"));

    // The welcome intro remains available before setup, with the brand centered.
    expect(source, contains('class _FoodOnboardingIntro extends StatelessWidget'));
    expect(source, contains("ValueKey<String>('food_onboarding_brand_logo')"));
    expect(source, contains("ValueKey<String>('food_onboarding_brand_title')"));
    expect(source, contains("'SCHMACKOFATZ'"));
    expect(source, contains('textAlign: TextAlign.center'));
    expect(source, contains("'Willkommen!'"));
    expect(source, contains("ValueKey<String>('food_onboarding_welcome_box')"));
    expect(source, contains("onStart: () => setState(() => showSetup = true)"));
    expect(source, contains('Richte zuerst deine Lebensmittel und Vorlieben ein.'));
    expect(source, contains('passende Essensideen'));
    expect(source, contains('erstellt daraus deine Einkaufsliste'));
    expect(source, contains('Mit Connections kannst du Rezepte und Planung gemeinsam nutzen.'));
    expect(source, isNot(contains('Schmackofatz hilft euch')));
    expect(source, isNot(contains('eure Vorlieben')));

    // No old dedicated branding box/header was reintroduced.
    expect(source, isNot(contains('food_onboarding_brand_box')));
    expect(source, isNot(contains("title: Text('Meine Lebensmittel einrichten')")));
  });

  test('Bestehende Lebensmittel-Einrichtung und Abschlusslogik bleiben erhalten', () {
    final source = File('lib/features/foods/food_onboarding_page.dart').readAsStringSync();

    expect(source, contains('final repository = FoodRepository();'));
    expect(source, contains('await repository.foods();'));
    expect(source, contains('await repository.preferences();'));
    expect(source, contains('ProfileRepository().completeOnboarding(prefs)'));
    expect(source, contains('widget.onCompleted()'));
    expect(source, contains('void choose(String id, String value)'));
    expect(source, contains('prefs[id] = value;'));
    expect(source, contains("tooltip: 'Mag ich'"));
    expect(source, contains("tooltip: 'Mag ich nicht'"));
    expect(source, contains('Future<void> addFood() async'));
    expect(source, contains("tooltip: 'Eigenes Lebensmittel hinzufügen'"));
    expect(source, contains("onPressed: saving ? null : finish"));
  });
}
