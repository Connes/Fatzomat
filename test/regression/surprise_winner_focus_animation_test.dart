import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('surprise winner appears in a centered popup over the roulette', () {
    final source = File(
      'lib/features/shared/surprise_mode_roulette_page.dart',
    ).readAsStringSync();

    expect(source, contains('ColoredBox('));
    expect(source, contains('Center('));
    expect(source, contains('constraints.maxHeight * .68'));
    expect(source, contains('borderRadius: BorderRadius.circular(30)'));
    expect(source, contains('_winnerEntrance.forward(from: 0)'));
    expect(source, contains('_winnerPulse.repeat(reverse: true)'));
    expect(source, contains('final pulse = 1 + (_winnerPulse.value * .028)'));
    expect(source, contains('_winnerEntrance.reset()'));
    expect(source, contains('_winnerPulse.reset()'));
  });
}
