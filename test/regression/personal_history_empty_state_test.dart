import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Personal history empty state has readable branded contrast', () {
    final page = File('lib/features/settings/personal_history_page.dart').readAsStringSync();

    expect(page, contains('color: AppDesign.iconGold'));
    expect(page, contains('color: AppDesign.surface.withValues(alpha: 0.97)'));
    expect(page, contains('Theme.of(context).textTheme.headlineSmall'));
    expect(page, contains('color: AppDesign.text'));
    expect(page, contains('TextAlign.center'));
  });
}
