import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/decision_request.dart';

void main() {
  test('parses a resolved recipe decision', () {
    final request = DecisionRequest.fromMap({
      'id': 'req-1',
      'connection_id': 'conn-1',
      'created_by': 'user-a',
      'assigned_to': 'user-b',
      'status': 'resolved',
      'decision_mode': 'cook',
      'result_type': 'recipe',
      'result_id': 'recipe-1',
      'created_at': '2026-09-15T10:00:00Z',
      'resolved_at': '2026-09-15T10:05:00Z',
    });

    expect(request.isResolved, isTrue);
    expect(request.resultType, 'recipe');
    expect(request.resultId, 'recipe-1');
  });

  test('keeps unresolved requests distinct from resolved requests', () {
    final request = DecisionRequest.fromMap({
      'id': 'req-2',
      'connection_id': 'conn-1',
      'created_by': 'user-a',
      'assigned_to': 'user-b',
      'status': 'accepted',
      'decision_mode': null,
      'result_type': null,
      'result_id': null,
      'created_at': '2026-09-15T10:00:00Z',
      'resolved_at': null,
    });

    expect(request.isResolved, isFalse);
    expect(request.isPending, isFalse);
  });
}
