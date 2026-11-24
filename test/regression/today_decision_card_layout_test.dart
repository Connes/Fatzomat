import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today decision card uses separate header, flexible content and fixed actions', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final cardStart = source.indexOf('class _TodayResultCard');
    final headerStart = source.indexOf('class _TodayDecisionCardHeader');
    final contentStart = source.indexOf('class _TodayDecisionCardContent');
    final actionsStart = source.indexOf('class _TodayDecisionCardActions');
    expect(cardStart, isNonNegative);
    expect(headerStart, greaterThan(cardStart));
    expect(contentStart, greaterThan(headerStart));
    expect(actionsStart, greaterThan(contentStart));

    final card = source.substring(cardStart, headerStart);
    final header = source.substring(headerStart, contentStart);
    final content = source.substring(contentStart, actionsStart);
    final actions = source.substring(actionsStart);

    expect(card, contains('height: _todayDecisionCardHeight(context)'));
    expect(card, contains('_TodayDecisionCardHeader('));
    expect(card, contains('Expanded('));
    expect(card, contains('_TodayDecisionCardContent('));
    expect(card, contains('_TodayDecisionCardActions('));
    expect(card, contains('final compactScale = (screenHeight / 760).clamp(0.82, 1.0).toDouble()'));
    expect(card, contains('final imageHeight = (width >= 700 ? 180.0 : 148.0) * compactScale'));
    expect(card, contains('compactScale: compactScale'));
    expect(card, contains('height: imageHeight'));
    expect(header, contains('modeLabel'));
    expect(header, contains('child: image'));
    expect(header, contains('onEditDecision'));
    expect(header, contains('Icons.edit_outlined'));
    expect(content, contains('categoryLabel'));
    expect(content, contains('onTap: onTitleTap'));
    expect(header, isNot(contains('onTap:')));
    expect(content, contains('crossAxisAlignment: CrossAxisAlignment.stretch'));
    expect(content, contains('menuCourses'));
    expect(content, contains('compactScale'));
    expect(content, contains('onOpenCourse'));
    expect(content, contains('centerSelection'));
    expect(content, contains('supportingLines'));
    expect(content, contains('for (final line in supportingLines)'));
    expect(content, contains('fontSize: 14 * compactScale'));
    expect(content, contains('FittedBox('));
    expect(content, contains('fit: BoxFit.scaleDown'));
    expect(content, contains('softWrap: false'));
    expect(content, contains('maxLines: 1'));
    expect(content, contains('Center('));
    expect(card, contains('plan.restaurantAddress'));
    expect(card, contains('plan.restaurantCity'));
    expect(content, contains('today_menu_course_'));
    expect(content, contains('recipe_id'));
    expect(content, contains('Vorspeise'));
    expect(content, contains('Nachtisch'));
    expect(content, contains('maxLines: 2'));
    expect(content, contains('TextOverflow.ellipsis'));
    expect(actions, contains('height: 43'));
    expect(actions, contains('minimumSize: const Size(0, 43)'));
    expect(actions, contains('tapTargetSize: MaterialTapTargetSize.shrinkWrap'));
    expect(actions, contains('Container(width: 1, height: 43'));
    expect(actions, contains('visualDensity: VisualDensity.compact'));
  });

  test('Today decision choices and partner action have separate surfaces', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final start = source.indexOf('class _TodayDecisionCard extends StatelessWidget');
    final end = source.indexOf('class _TodayResultCard extends StatelessWidget', start);
    expect(start, isNonNegative);
    expect(end, greaterThan(start));
    final card = source.substring(start, end);

    expect(card, contains('The four decision modes live together in their own surface.'));
    expect(card, contains('GridView.count('));
    expect(card, contains('The partner-decision action is visually separated from the grid.'));
    expect(card, contains("'Entscheide Du'"));
    expect(card, contains('const SizedBox(height: 12)'));
    expect(source, contains('gridHeight + 16 + 76 + 20 + 8 + 28'));
  });
}
