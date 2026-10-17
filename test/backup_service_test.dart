import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/services/backup_service.dart';

void main() {
  test('builds a versioned personal backup without recipes or credentials', () {
    final backup = BackupService.buildPayload(
      preferences: const {'rice': 'like', 'fish': 'dislike'},
      history: const [
        {
          'recipe_id': 'recipe-1',
          'action': 'selected',
          'source': 'today',
          'created_at': '2026-10-17T10:00:00Z',
        },
      ],
    );

    expect(backup['format'], 'schmackofatz_backup');
    expect(backup['version'], 2);
    expect(backup.containsKey('profile'), isFalse);
    expect(backup.containsKey('recipes'), isFalse);
    expect(backup.containsKey('restaurant_favorites'), isFalse);
    expect(backup.containsKey('access_token'), isFalse);
    expect(backup.containsKey('refresh_token'), isFalse);
    expect(backup['preferences'], {'rice': 'like', 'fish': 'dislike'});
    expect((backup['history'] as List), hasLength(1));
  });
}
