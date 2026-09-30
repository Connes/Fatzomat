import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/data/models/decision_request.dart';
import 'package:food_app_mvp/features/shared/decision_request_page.dart';

void main() {
  testWidgets('decision request exposes all four approved choices', (tester) async {
    final request = DecisionRequest.fromMap({
      'id': 'req-v78',
      'connection_id': 'conn-v78',
      'created_by': 'user-a',
      'assigned_to': 'user-b',
      'status': 'pending',
      'decision_mode': null,
      'result_type': null,
      'result_id': null,
      'created_at': '2026-09-16T10:00:00Z',
      'resolved_at': null,
    });

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(home: DecisionRequestPage(request: request)),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Wir kochen'), findsOneWidget);
    expect(find.bySemanticsLabel('Wir bestellen'), findsOneWidget);
    expect(find.bySemanticsLabel('Wir gehen essen'), findsOneWidget);
    expect(find.bySemanticsLabel('Überrasch mich'), findsOneWidget);

    semantics.dispose();
  });
}
