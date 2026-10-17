import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Heute ist eine reduzierte Tageskarte', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(shell, contains('int index = 0;'));
    expect(shell, contains('TodayPage('));
    expect(shell, contains('resetToTodaySignal: _todayResetSignal'));
    expect(shell, contains("label: 'Heute'"));
    expect(shell, isNot(contains("label: 'Start'")));
    expect(shell, isNot(contains('const HomePage()')));

    expect(today, contains('backgroundType: TogetherBackgroundType.home'));
    expect(today, contains('respectTopSafeArea: true'));
    expect(today, contains('statusBarIconBrightness: Brightness.dark'));
    expect(today, contains('statusBarBrightness: Brightness.light'));
    expect(today, contains("'Wir kochen'"));
    expect(today, contains("'Wir bestellen'"));
    expect(today, contains("'Wir gehen essen'"));
    expect(today, contains("'Überrasch mich'"));
    expect(today, contains("'Entscheide Du'"));
    expect(today, isNot(contains("'Entscheidung ändern'")));
    expect(today, contains("Text('Entfernen')"));
    expect(today, contains("Text('Teilen')"));
    expect(today, contains("'HEUTE BESTELLEN'"));
    expect(today, contains("'HEUTE KOCHEN'"));
    expect(today, contains("'HEUTE ESSEN GEHEN'"));
    expect(today, contains("'order' => plan.decisionValue?.trim().isNotEmpty == true"));
    expect(today, contains("if (plan.decisionType != 'order') ...["));
    expect(today, contains("const SizedBox(height: 12),\n                      Text(\n                        title,"));
    expect(today, isNot(contains("label: const Text('Lieferdienste')")));
    expect(today, contains("if (plan.decisionType == 'order')"));
    expect(today, contains('DeliveryServicesPage'));
    expect(today, contains('FoodChoiceAssetService.assetFor('));
    expect(today, contains("onOpenOrder: plan!.decisionType == 'order' && plan!.status != 'cooked'"));
    expect(today, contains("onTap: plan.status == 'cooked'"));
    expect(today, contains('? onOpenOrder'));
    expect(today, contains("plan.restaurantCuisine"));
    expect(today, isNot(contains('RestaurantDetailPage')));
    final restaurantDetails = File('lib/features/shared/restaurant_details_dialog.dart').readAsStringSync();
    expect(restaurantDetails, contains('Für dieses Restaurant sind keine weiteren Angaben gespeichert.'));
    expect(today, contains('Als erledigt markieren'));
    final foodMode = File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();
    expect(foodMode, contains("'fatzomat_pending_restaurant_import_cuisine', cuisine"));
    expect(foodMode, contains('initialCuisine: cuisine'));
    expect(foodMode, contains('autoOpenChatGpt: true'));
    expect(today, contains("assets/together/clean/icons/icon_cooking.png"));
    expect(today, contains("assets/together/clean/icons/icon_delivery.png"));
    expect(today, contains("assets/together/clean/icons/icon_restaurant.png"));
    expect(today, contains("assets/together/clean/icons/icon_surprise.png"));
    // "Entscheide Du" is now a durable message, not a DecisionRequest lifecycle.
    expect(today, contains("type: 'ask',"));
    expect(today, contains('planDate: _selectedDate'));
    expect(today, isNot(contains('activeDecisionRequestCreatedByMe')));
    expect(today, isNot(contains('createDecisionRequest(assignedTo: partner)')));
    expect(today, contains("table: 'personal_today_plans'"));

    expect(today, isNot(contains("'Was essen wir heute?'")));
    expect(today, isNot(contains("'HEUTE GIBT’S'")));
    expect(today, isNot(contains("'Gemeinsam entschieden'")));
    expect(today, isNot(contains("'Rezept ansehen'")));
    expect(today, isNot(contains("'Als Nächstes'")));
    expect(today, isNot(contains("'Weitere Möglichkeiten'")));
  });
}
