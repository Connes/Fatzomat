import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant details open the address in navigation without showing distance', () {
    final detailSource =
        File('lib/features/food_modes/restaurant_detail_page.dart').readAsStringSync();

    expect(detailSource, contains("Uri.https('www.google.com', '/maps/dir/'"));
    expect(detailSource, contains("'destination': addressParts.join(', ')"));
    expect(detailSource, contains('onTap: addressUri == null ? null : () => _open(context, addressUri)'));
    expect(detailSource, isNot(contains('formattedDistance')));
  });

  test('restaurant discovery does not display or persist distance', () {
    final source =
        File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();

    expect(source, isNot(contains("'distance_km': result.distanceKm")));
    expect(source, isNot(contains('Text(result.formattedDistance)')));
  });

  test('ChatGPT restaurant prompt does not mention distance or a radius', () {
    final source =
        File('lib/features/food_modes/chatgpt_restaurant_page.dart').readAsStringSync();

    expect(source, isNot(contains('10-km-Radius')));
    expect(source, isNot(contains('Entfernung')));
    expect(source, isNot(contains('distance')));
  });
}
