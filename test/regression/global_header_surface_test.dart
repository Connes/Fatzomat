import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gemeinsame AppBar verwendet die Surface-Farbe der Bottom Navigation', () {
    final appBar = File('lib/core/widgets/together_scaffold.dart').readAsStringSync();
    final design = File('lib/core/app_design.dart').readAsStringSync();

    // NavigationBar uses AppDesign.surface in the central theme.
    expect(design, contains('backgroundColor: surface,'));

    // TogetherAppBar reuses the same central surface color instead of
    // introducing a second header color.
    expect(appBar, contains('backgroundColor: backgroundColor ?? AppDesign.surface'));
    expect(appBar, contains('statusBarColor: AppDesign.surface'));
  });

  test('Today behält das Datum, andere Hauptseiten erhalten keine Today-Datumslogik', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final shell = File('lib/core/app_shell.dart').readAsStringSync();

    expect(today, contains('_todayDateLabel()'));
    expect(today, contains('_todayAppBar()'));
    expect(today, contains('statusBarColor: AppDesign.surface'));
    expect(shell, isNot(contains('_todayDateLabel')));
    expect(shell, isNot(contains('todayDate')));
  });
}
