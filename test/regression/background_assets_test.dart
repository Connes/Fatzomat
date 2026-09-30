import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('V86 ships a dedicated background asset for every non-home screen group', () async {
    const assets = <String>[
      'recipes_background.png',
      'recipe_detail_background.png',
      'today_background.png',
      'decision_background.png',
      'decision_result_background.png',
      'notifications_background.png',
      'notification_detail_background.png',
      'profile_background.png',
      'profile_edit_background.png',
      'settings_background.png',
      'help_background.png',
      'legal_background.png',
      'login_background.png',
      'register_background.png',
      'password_reset_background.png',
      'error_background.png',
      'offline_background.png',
      'empty_background.png',
      'search_background.png',
      'filter_background.png',
      'share_background.png',
      'about_background.png',
      'update_background.png',

    ];

    for (final asset in assets) {
      final data = await rootBundle.load('assets/together/clean/background/$asset');
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }

    expect(assets, isNot(contains('home_photo_background.png')));
    expect(assets.length, 23);
  });
}
