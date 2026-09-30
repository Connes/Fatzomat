import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/error_text.dart';
import 'package:food_app_mvp/core/app_exception.dart';

void main() {
  test('maps network failures to a useful retry message', () {
    expect(friendlyError(Exception('SocketException: connection timeout')), contains('Netzwerkfehler'));
  });

  test('maps permission failures', () {
    expect(friendlyError(Exception('PostgrestException 42501')), contains('Keine Berechtigung'));
  });

  test('falls back to a generic actionable message', () {
    expect(friendlyError(Exception('unknown failure')), contains('erneut versuchen'));
  });

  test('keeps current backend error messages actionable', () {
    final error = BackendException('Der ausgewählte Eintrag ist nicht mehr verfügbar.');
    expect(friendlyError(error), contains('nicht mehr verfügbar'));
  });
}
