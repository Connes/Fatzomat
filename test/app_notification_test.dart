import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/app_notification.dart';

void main() {
  test('parses unread notification', () {
    final notification = AppNotification.fromMap({
      'id': 'n1',
      'type': 'decision_request',
      'title': 'Du entscheidest heute',
      'body': 'Deine Verbindung hat dir die Entscheidung übergeben.',
      'recipe_id': null,
      'shared_recipe_plan_id': null,
      'decision_request_id': 'r1',
      'recipe_suggestion_id': null,
      'recipe_deletion_request_id': 'delete-request-1',
      'read_at': null,
      'created_at': '2026-09-15T10:00:00Z',
    });

    expect(notification.id, 'n1');
    expect(notification.decisionRequestId, 'r1');
    expect(notification.recipeDeletionRequestId, 'delete-request-1');
    expect(notification.isRead, isFalse);
  });

  test('parses read notification', () {
    final notification = AppNotification.fromMap({
      'id': 'n2',
      'type': 'shared_recipe',
      'title': 'Neues Rezept für heute',
      'body': 'Pasta wurde für euch heute ausgewählt.',
      'recipe_id': 'recipe-1',
      'shared_recipe_plan_id': 'plan-1',
      'decision_request_id': null,
      'recipe_suggestion_id': null,
      'read_at': '2026-09-15T11:00:00Z',
      'created_at': '2026-09-15T10:00:00Z',
    });

    expect(notification.recipeId, 'recipe-1');
    expect(notification.sharedRecipePlanId, 'plan-1');
    expect(notification.isRead, isTrue);
  });
}
