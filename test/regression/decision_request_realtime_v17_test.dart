import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V17 keeps the incoming decision request live on the decision page', () {
    final page = File('lib/features/shared/decision_request_page.dart').readAsStringSync();

    expect(page, contains("table: 'decision_requests'"));
    expect(page, contains("column: 'id'"));
    expect(page, contains("value: widget.request.id"));
    expect(page, contains('_refreshRequest()'));
    expect(page, contains('removeChannel(_decisionRequestChannel!)'));
    expect(page, contains('onPostgresChanges'));
    expect(page, contains('WidgetsBindingObserver'));
    expect(page, contains('didChangeAppLifecycleState'));
    expect(page, contains('AppLifecycleState.resumed'));
    expect(page, contains('_refreshGeneration'));
    expect(page, contains('generation != _refreshGeneration'));
  });

  test('V17 scopes notification realtime updates to the signed-in user', () {
    final page = File('lib/features/settings/notifications_page.dart').readAsStringSync();

    expect(page, contains("column: 'user_id'"));
    expect(page, contains('client.auth.currentUser!.id'));
  });
}

