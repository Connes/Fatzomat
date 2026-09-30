import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declined recipe notifications reopen with a durable status instead of loading the recipe', () {
    final page = File('lib/features/recipes/recipe_share_request_page.dart').readAsStringSync();
    final notifications = File('lib/features/settings/notifications_page.dart').readAsStringSync();

    expect(page, contains('if (!loadedSuggestion.isDeclined)'));
    expect(page, contains("title: 'Rezept bereits abgelehnt'"));
    expect(page, contains('Dieses Rezept wurde von dir bereits abgelehnt.'));
    expect(page, contains('Die Anfrage ist abgeschlossen.'));
    expect(page, contains('_RecipeShareStatusContent'));
    expect(page, contains('suggestion?.isDeclined == true'));
    expect(notifications, contains('RecipeShareRequestPage(suggestionId: item.recipeSuggestionId!)'));
  });
}
