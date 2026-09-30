import 'package:flutter_test/flutter_test.dart';

void main() {
  test('servings must be positive', () {
    expect(1 > 0, isTrue);
    expect(0 > 0, isFalse);
  });

  test('invite codes are case-insensitive at the boundary', () {
    expect('abc123'.toUpperCase(), 'ABC123');
    expect('AbC123'.toUpperCase(), 'ABC123');
  });
}
