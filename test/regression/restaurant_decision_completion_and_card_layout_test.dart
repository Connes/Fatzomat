import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant completion updates status and refreshes Today', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final start = source.indexOf('onCompleteVisit: () => _completeRestaurantVisit(plan!)');
    final end = source.indexOf('onOpenRecipe:', start);
    final action = source.substring(start, end);
    expect(action, contains('_completeRestaurantVisit(plan!)'));
    expect(action, isNot(contains('repo.removeTodayPlan(plan!.id)')));
    expect(action, isNot(contains("repo.updateStatus(plan!.id, 'cooked')")));
  });

  test('tapping the selected dine-out restaurant opens its details, not restaurant selection', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final start = source.indexOf('onOpenDecisionTitle: () {');
    final end = source.indexOf('\n                              },', start);
    final action = source.substring(start, end);

    expect(action, contains('showRestaurantDetailsDialog('));
    expect(action, contains('plan!.restaurantData'));
    expect(action, isNot(contains('_openMode(FoodMode.dineOut)')));
  });

  test('Today restaurant details complete directly and expose a centered gold favorite heart', () {
    final dialog = File('lib/features/shared/restaurant_details_dialog.dart').readAsStringSync();
    expect(dialog, contains('onCompleteVisit'));
    expect(dialog, contains("const Text('Erledigt')"));
    expect(dialog, contains('actionsAlignment: MainAxisAlignment.start'));
    expect(dialog, contains('var isCompletingVisit = false'));
    expect(dialog, contains('onPressed: isCompletingVisit'));
    expect(dialog, contains('setDialogState(() => isCompletingVisit = true)'));
    expect(dialog, contains("const Text('Schließen')"));
    expect(dialog, contains('textAlign: TextAlign.center'));
    expect(dialog, contains('Icons.favorite_border_rounded'));
    expect(dialog, contains('Icons.favorite_rounded'));
    expect(dialog, contains('Color(0xFFD4AF37)'));
    expect(dialog, contains('onToggleFavorite'));

    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final start = source.indexOf('Future<bool> _completeRestaurantVisit(');
    final end = source.indexOf('\n  @override\n  Widget build(BuildContext context)', start);
    final completion = source.substring(start, end);
    expect(completion, isNot(contains('showDialog<bool>')));
    expect(completion, contains("repo.updateStatus(selectedPlan.id, 'cooked')"));
    expect(completion, contains('RecipeCollectionEvents.notifyChanged()'));
    expect(source, contains('onToggleFavorite: (currentlyFavorite) async'));
  });

  test('favorite restaurant list uses a gold filled heart', () {
    final source = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();
    expect(source, contains('Icons.favorite_rounded, color: const Color(0xFFD4AF37)'));
    expect(source, contains('onToggleFavorite: (currentlyFavorite) async'));
  });


  test('decision card has fixed header and action sections with flexible content', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final card = source.substring(source.indexOf('class _TodayResultCard'));
    expect(card, contains('height: _todayDecisionCardHeight(context)'));
    expect(card, contains('_TodayDecisionCardHeader('));
    expect(card, contains('Expanded('));
    expect(card, contains('_TodayDecisionCardContent('));
    expect(card, contains('_TodayDecisionCardActions('));
    expect(card, contains('height: 180'));

    final header = source.substring(
      source.indexOf('class _TodayDecisionCardHeader'),
      source.indexOf('class _TodayDecisionCardContent'),
    );
    expect(header, contains('modeLabel'));
    expect(header, contains('child: image'));

    final content = source.substring(
      source.indexOf('class _TodayDecisionCardContent'),
      source.indexOf('class _TodayDecisionCardActions'),
    );
    expect(content, contains('maxLines: 2'));
    expect(content, contains('TextOverflow.ellipsis'));

    final actions = source.substring(source.indexOf('class _TodayDecisionCardActions'));
    expect(actions, contains('height: 58'));
    expect(actions, contains('Container(width: 1, height: 58, color: AppDesign.divider)'));
    expect(actions, contains('Divider(height: 1, thickness: 1, color: AppDesign.divider)'));
  });
}
