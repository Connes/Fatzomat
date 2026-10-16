import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  String read(String relative) => File('$root/$relative').readAsStringSync();

  test('surprise roulette uses the three category images as moving slot reels', () {
    final page = read('lib/features/shared/surprise_mode_roulette_page.dart');

    expect(page, contains('AnimationController.unbounded'));
    expect(page, contains('_ConstantVelocitySimulation'));
    expect(page, contains('Curves.easeOutQuart'));
    expect(page, contains('icon_cooking.png'));
    expect(page, contains('icon_delivery.png'));
    expect(page, contains('icon_restaurant.png'));
    expect(page, contains('class _CasinoReel'));
    expect(page, contains("'FATZOMAT'"));
    expect(page, isNot(contains('ROYAL JACKPOT')));
    expect(page, isNot(contains('DER ZUFALL HAT ENTSCHIEDEN')));
    expect(page, isNot(contains('Euer Abend steht fest.')));
    expect(page, contains("'NOCHMAL DREHEN'"));
    expect(page, isNot(contains('_labels[mode]!')));
    expect(page, contains('Color(0xFF19030A)'));
    expect(page, contains('borderRadius: BorderRadius.circular(28)'));
    expect(page, contains('backgroundColor: _deepRed'));
    expect(page, contains('foregroundColor: _gold'));
    expect(page, isNot(contains('AnimatedSwitcher')));
    expect(page, isNot(contains('Timer(')));
  });

  test('all three reels land on the same selected category before continuing', () {
    final page = read('lib/features/shared/surprise_mode_roulette_page.dart');

    expect(page, contains('math.Random().nextInt(_modes.length)'));
    expect(page, contains('final alignment ='));
    expect(page, contains('Stop reels in sequence'));
    expect(page, contains('final startedAt = DateTime.now()'));
    expect(page, contains('final remainingMs = 900 - elapsed.inMilliseconds'));
    expect(page, contains('setState(() => _stoppedReels = index + 1)'));
    expect(page, isNot(contains('Future.wait(stops)')));
    expect(page, contains('Navigator.pop(context, result)'));
  });
}
