import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/food_mode.dart';
import 'package:food_app_mvp/core/services/food_choice_asset_service.dart';

void main() {
  test('alle Food-Choice-Assets exist', () {
    for (final mode in FoodMode.values) {
      for (final path in FoodChoiceAssetService.choicesFor(mode).values) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing asset: $path',
        );
      }
    }
    expect(
      File('assets/together/clean/icons/icon_surprise.png').existsSync(),
      isTrue,
    );
  });
}
