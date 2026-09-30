import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/app_exception.dart';
import 'package:food_app_mvp/core/error_text.dart';

void main() {
  test('normalizes authentication failures', () {
    final error = normalizeAppException(Exception('JWT expired (401)'));
    expect(error, isA<AuthenticationException>());
    expect(friendlyError(error), contains('Sitzung'));
  });

  test('normalizes authorization failures', () {
    expect(normalizeAppException(Exception('permission denied 42501')), isA<AuthorizationException>());
  });

  test('preserves domain exceptions', () {
    const error = ValidationException('Testfehler');
    expect(normalizeAppException(error), same(error));
    expect(friendlyError(error), contains('nicht gültig'));
  });
}
