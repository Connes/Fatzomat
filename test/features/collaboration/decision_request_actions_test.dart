import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/decision_request.dart';

void main() {
  final base = {
    'id': 'req-1',
    'connection_id': 'conn-1',
    'created_by': 'user-a',
    'assigned_to': 'user-b',
    'decision_mode': null,
    'result_type': null,
    'result_id': null,
    'created_at': '2026-09-15T10:00:00Z',
    'resolved_at': null,
  };

  test('pending and accepted requests are active', () {
    expect(DecisionRequest.fromMap({...base, 'status': 'pending'}).isPending, isTrue);
    expect(DecisionRequest.fromMap({...base, 'status': 'accepted'}).isPending, isFalse);
  });

  test('resolved and cancelled requests are not pending', () {
    expect(DecisionRequest.fromMap({...base, 'status': 'resolved'}).isResolved, isTrue);
    expect(DecisionRequest.fromMap({...base, 'status': 'cancelled'}).isCancelled, isTrue);
  });
}
