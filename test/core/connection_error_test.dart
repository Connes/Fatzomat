import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/app_exception.dart';
import '../../lib/core/error_text.dart';

void main() {
  test('missing connection gets a specific user-facing message', () {
    expect(
      friendlyError(const ConnectionRequiredException()),
      'Verbinde zuerst eine zweite Person, um diese Funktion zu nutzen.',
    );
  });

  test('raw connection RPC error is not turned into a generic network error', () {
    expect(
      friendlyError(Exception('Keine Verbindung zu einer zweiten Person vorhanden.')),
      'Verbinde zuerst eine zweite Person, um diese Funktion zu nutzen.',
    );
  });
}
