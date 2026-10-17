import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home decision button uses a bounded, single-line responsive content row', () {
    final source = File('lib/features/home/home_page.dart').readAsStringSync();
    expect(source, contains('const ctaHeight = 72.0;'));
    expect(source, contains('final welcomeHeight = 24.0 + 14.0;'));
    expect(source, contains('final groupHeight = welcomeHeight + gridHeight + ctaGap + ctaHeight;'));
  });
}
