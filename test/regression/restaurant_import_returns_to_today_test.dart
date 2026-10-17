import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant import returns to Today when it is the root route', () {
    final restaurantPage = File(
      'lib/features/food_modes/chatgpt_restaurant_page.dart',
    ).readAsStringSync();

    expect(restaurantPage, contains('AppShell(initialDate: widget.planDate)'));
    expect(restaurantPage, contains('navigator.pushAndRemoveUntil<void>('));
    expect(restaurantPage, contains('navigator.pop(true);'));
  });
}
