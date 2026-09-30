import 'package:flutter_test/flutter_test.dart';

double scale(double quantity, int baseServings, int targetServings) {
  return quantity * targetServings / baseServings;
}

void main() {
  test('scales recipe quantities deterministically', () {
    expect(scale(200, 2, 4), 400);
    expect(scale(0.5, 4, 2), 0.25);
  });

  test('keeps quantity when servings stay equal', () {
    expect(scale(3, 3, 3), 3);
  });
}
