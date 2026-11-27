import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/flow_guard.dart';

void main() {
  setUp(() => FlowGuard.instance.complete());

  test('a new path cannot overwrite an active path', () {
    FlowGuard.instance.beginIfIdle(id: 'cook', label: 'Wir kochen heute');
    FlowGuard.instance.beginIfIdle(id: 'order', label: 'Wir bestellen heute');

    expect(FlowGuard.instance.isActive, isTrue);
    expect(FlowGuard.instance.activeId, 'cook');
    expect(FlowGuard.instance.activeLabel, 'Wir kochen heute');
  });

  test('a path ends only when explicitly completed', () {
    FlowGuard.instance.beginIfIdle(id: 'cook', label: 'Wir kochen heute');
    expect(FlowGuard.instance.isActive, isTrue);

    FlowGuard.instance.complete();

    expect(FlowGuard.instance.isActive, isFalse);
    expect(FlowGuard.instance.activeId, isNull);
    expect(FlowGuard.instance.activeLabel, isNull);
  });

  testWidgets('abandon confirmation keeps the path or clears it', (tester) async {
    FlowGuard.instance.beginIfIdle(id: 'cook', label: 'Wir kochen heute');
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => FlowGuard.instance.confirmAbandon(
                context,
                destination: 'Rezepte',
              ),
              child: const Text('Tab wechseln'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Tab wechseln'));
    await tester.pumpAndSettle();
    expect(find.text('Bearbeitungspfad verlassen?'), findsOneWidget);
    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(FlowGuard.instance.isActive, isTrue);

    await tester.tap(find.text('Tab wechseln'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pfad verlassen'));
    await tester.pumpAndSettle();
    expect(FlowGuard.instance.isActive, isFalse);
  });

  testWidgets('system/app-bar back cannot pop a flow root without confirmation', (tester) async {
    FlowGuard.instance.beginIfIdle(id: 'cook', label: 'Wir kochen heute');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => FlowExitGuard(
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Kochpfad')),
                    body: const Center(child: Text('Aktiver Pfad')),
                  ),
                ),
              ),
            ),
            child: const Text('Pfad öffnen'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Pfad öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Aktiver Pfad'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Bearbeitungspfad verlassen?'), findsOneWidget);
    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Aktiver Pfad'), findsOneWidget);
    expect(FlowGuard.instance.isActive, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pfad verlassen'));
    await tester.pumpAndSettle();
    expect(find.text('Aktiver Pfad'), findsNothing);
    expect(FlowGuard.instance.isActive, isFalse);
  });
}
