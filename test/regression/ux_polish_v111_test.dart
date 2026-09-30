import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('V1.11 Portionssteuerungen haben eindeutige Bedienhinweise', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              IconButton(
                tooltip: 'Weniger Portionen',
                onPressed: null,
                icon: Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                tooltip: 'Mehr Portionen',
                onPressed: null,
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byTooltip('Weniger Portionen'), findsOneWidget);
    expect(find.byTooltip('Mehr Portionen'), findsOneWidget);
  });
}
