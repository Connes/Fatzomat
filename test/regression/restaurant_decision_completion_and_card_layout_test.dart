import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant completion updates status and refreshes Today', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final start = source.indexOf("extraActionLabel: 'Als erledigt markieren'");
    final end = source.indexOf('onOpenRecipe:', start);
    final action = source.substring(start, end);
    expect(action, contains("repo.updateStatus(plan!.id, 'cooked')"));
    expect(action, isNot(contains('repo.removeTodayPlan(plan!.id)')));
    expect(action, contains('await load()'));
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
