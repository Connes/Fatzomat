import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/core/widgets/together_background.dart';

void main() {
  test('V86 maps every screen family to one background asset', () {
    final types = TogetherBackgroundType.values;

    expect(types.length, 24);
    expect(
      TogetherBackgroundAssets.assetFor(TogetherBackgroundType.home),
      'assets/together/clean/background/home_photo_background.png',
    );

    final assets = types.map(TogetherBackgroundAssets.assetFor).toList();
    expect(assets.toSet().length, types.length);
    expect(assets.where((asset) => asset.contains('home_photo_background')).length, 1);
  });
}
