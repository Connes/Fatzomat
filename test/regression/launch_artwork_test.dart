import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launch artwork crops embedded side edges without changing its layout', () {
    final source = File('lib/core/launch_page.dart').readAsStringSync();

    expect(source, contains('child: ClipRect('));
    expect(source, contains('child: Transform.scale('));
    expect(source, contains('scaleX: 1.04'));
    expect(source, contains("Image.asset(\n                'assets/branding/launch_vegetables.png'"));
    expect(source, contains('fit: BoxFit.cover'));
    expect(source, contains('alignment: Alignment.topCenter'));
  });
}
