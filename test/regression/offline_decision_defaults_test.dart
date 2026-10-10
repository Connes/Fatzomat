import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline non-recipe decisions default to one serving', () {
    final repository = File(
      'lib/data/repositories/personal_today_repository.dart',
    ).readAsStringSync();

    final decisionStart = repository.indexOf('final localDecision = {');
    final decisionEnd = repository.indexOf('};', decisionStart);
    expect(decisionStart, isNonNegative);
    expect(decisionEnd, greaterThan(decisionStart));

    final localDecision = repository.substring(decisionStart, decisionEnd);
    expect(localDecision, contains("'servings': 1"));
    expect(localDecision, isNot(contains("'servings': 2")));
  });
}
