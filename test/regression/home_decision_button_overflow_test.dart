import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home decision button uses a compact text-only responsive button', () {
    final source = File('lib/features/home/home_page.dart').readAsStringSync();
    expect(source, contains('const ctaHeight = 56.0;'));
    expect(source, isNot(contains('Icons.people_alt_rounded')));
    expect(source, contains('final welcomeHeight = 24.0 + 14.0;'));
    expect(source, contains('final groupHeight = welcomeHeight + gridHeight + ctaGap + ctaHeight;'));
  });
}
