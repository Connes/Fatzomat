import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Das Heute-Navigationssymbol setzt immer das aktuelle Datum', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(shell, contains('final ValueNotifier<int> _todayResetSignal'));
    expect(shell, contains('if (value == 0)'));
    expect(shell, contains('_todayResetSignal.value++'));
    expect(shell, contains('resetToTodaySignal: _todayResetSignal'));

    expect(today, contains('final ValueListenable<int>? resetToTodaySignal'));
    expect(today, contains('widget.resetToTodaySignal?.addListener(_resetToToday)'));
    expect(today, contains('void _resetToToday()'));
    expect(today, contains('final today = _dateOnly(DateTime.now())'));
    expect(today, contains('_selectedDate = today'));
    expect(today, contains('load();'));
    expect(today, contains('widget.resetToTodaySignal?.removeListener(_resetToToday)'));
  });
}
