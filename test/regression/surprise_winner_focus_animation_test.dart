import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('surprise winner takes focus while the roulette fades away', () {
    final source = File(
      'lib/features/shared/surprise_mode_roulette_page.dart',
    ).readAsStringSync();

    expect(source, contains("ValueKey('roulette-hidden')"));
    expect(source, contains("ValueKey('roulette-visible')"));
    expect(source, contains('duration: const Duration(milliseconds: 520)'));
    expect(source, contains('_winnerEntrance.forward(from: 0)'));
    expect(source, contains('_winnerPulse.repeat(reverse: true)'));
    expect(source, contains('final pulse = 1 + (_winnerPulse.value * .028)'));
    expect(source, contains('_winnerEntrance.reset()'));
    expect(source, contains('_winnerPulse.reset()'));
  });
}
