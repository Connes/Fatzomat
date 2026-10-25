import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/today_plan.dart';

void main() {
  test('ChatGPT restaurant search defines versioned JSON and required fields', () {
    final source = File('lib/features/food_modes/chatgpt_restaurant_page.dart').readAsStringSync();
    expect(source, contains("'schema_version': 1"));
    expect(source, contains("'type': 'fatzomat_restaurant_suggestion'"));
    for (final field in ['name', 'cuisine', 'address', 'phone', 'website', 'opening_hours']) {
      expect(source, contains("'$field'"));
    }
    expect(source, contains('in der Nähe des folgenden Ausgangspunkts'));
    expect(source, contains('ausschließlich den offiziellen Namen des Restaurants'));
    expect(source, contains('Der Ort gehört ausschließlich in das Feld address'));
    expect(source, contains('AUTOMATISCH in derselben Antwort'));
    expect(source, contains('herunterladbare Datei als ChatGPT-Dateianhang'));
    expect(source, contains('Warte nicht darauf, dass ich die Datei zusätzlich anfordere'));
    expect(source, contains('direkten Download-Link bereit'));
    expect(source, contains('steakhouse_tango_import.json'));
    expect(source, contains('FilePicker.pickFiles'));
    expect(source, contains('Unbekanntes JSON-Format'));
    expect(source, contains('Future<void> _useRestaurant() async {'));
    final useRestaurant = source.substring(source.indexOf('Future<void> _useRestaurant() async {'), source.indexOf('Widget _detail('));
    expect(useRestaurant, isNot(contains('showDialog')));
    expect(source, contains('Als heutigen Vorschlag übernehmen'));
    expect(source, contains('if (navigator.canPop()) {\n        navigator.pop(true);\n      }'));
    expect(source, isNot(contains('widget.onNavigateToToday?.call();')));
  });

  test('ChatGPT restaurant launch is blocked until location permission is granted', () {
    final source = File('lib/features/food_modes/chatgpt_restaurant_page.dart').readAsStringSync();
    expect(source, contains('Geolocator.requestPermission()'));
    expect(source, contains('Geolocator.openAppSettings()'));
    expect(source, contains("label: const Text('Systemeinstellungen öffnen')"));
    expect(source, contains("label: const Text('Berechtigung prüfen und fortfahren')"));
    expect(source, contains('_waitingForLocationSettings'));
    expect(source, contains('!_waitingForLocationSettings &&\n          _locationController.text.trim().isNotEmpty'));
    expect(source, contains('Ohne Standortfreigabe kann Fatzomat keine Restaurants in deiner Nähe suchen.'));
  });

  test('startup defers location permission until the restaurant flow needs it', () {
    final launch = File('lib/core/launch_page.dart').readAsStringSync();
    final restaurant = File('lib/features/food_modes/chatgpt_restaurant_page.dart').readAsStringSync();

    expect(launch, isNot(contains('Geolocator.requestPermission()')));
    expect(launch, isNot(contains("'fatzomat_location_permission_requested'")));
    expect(restaurant, contains('Geolocator.requestPermission()'));
    expect(restaurant, contains('Geolocator.checkPermission()'));
  });

  test('ChatGPT restaurant search is an additional option on dine-out page', () {
    final source = File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();
    expect(source, contains("import 'chatgpt_restaurant_page.dart';"));
    expect(source, isNot(contains("const Text('Mit ChatGPT suchen')")));
    expect(source, contains('_openChatGptForCuisine(context, option.label)'));
    expect(source, contains('if (widget.mode == FoodMode.dineOut)'));
    expect(source, isNot(contains('DiscoveryPage(')));
    expect(source, contains('initialCuisine: cuisine'));
    expect(source, contains('autoOpenChatGpt: true'));
  });

  test('versioned ChatGPT payload is exposed as restaurant data in TodayPlan', () {
    final plan = TodayPlan(
      id: 'plan-1',
      decisionType: 'dine_out',
      decisionValue: jsonEncode({
        'schema_version': 1,
        'type': 'fatzomat_restaurant_suggestion',
        'restaurant': {
          'name': 'Test Taverne',
          'cuisine': 'Griechisch',
          'address': 'Hauptstraße 1, 75172 Pforzheim',
          'phone': null,
          'website': 'https://example.com',
          'opening_hours': 'Mo-Fr 11:00-22:00',
        },
      }),
      status: 'planned',
      servings: 2,
      name: 'Heute',
    );

    expect(plan.restaurantName, 'Test Taverne');
    expect(plan.restaurantAddress, 'Hauptstraße 1, 75172 Pforzheim');
    expect(plan.restaurantCuisine, 'Griechisch');
    expect(plan.restaurantWebsite, 'https://example.com');
    expect(plan.restaurantOpeningHours, 'Mo-Fr 11:00-22:00');
  });

  test('legacy flat restaurant decisions remain supported', () {
    final plan = TodayPlan(
      id: 'plan-2',
      decisionType: 'dine_out',
      decisionValue: jsonEncode({
        'name': 'Alte Auswahl',
        'address': 'Marktplatz 2',
        'phone': '01234',
      }),
      status: 'planned',
      servings: 2,
      name: 'Heute',
    );

    expect(plan.restaurantName, 'Alte Auswahl');
    expect(plan.restaurantAddress, 'Marktplatz 2');
    expect(plan.restaurantPhone, '01234');
  });

  test('location lookup has a bounded wait and a clear retryable timeout state', () {
    final source = File('lib/features/food_modes/chatgpt_restaurant_page.dart').readAsStringSync();
    expect(source, contains("Geolocator.getCurrentPosition().timeout("));
    expect(source, contains('const Duration(seconds: 15)'));
    expect(source, contains('on TimeoutException'));
    expect(source, contains('Der Standort konnte nicht rechtzeitig ermittelt werden.'));
    expect(source, contains('_waitingForLocationSettings = false;'));
    expect(source, contains("label: const Text('Berechtigung prüfen und fortfahren')"));
  });
}
