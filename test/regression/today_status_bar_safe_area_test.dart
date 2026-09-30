import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/core/widgets/together_background.dart';

void main() {
  testWidgets('Today background keeps the real top safe area outside the artwork',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(viewPadding: EdgeInsets.only(top: 42)),
        child: const MaterialApp(
          home: SizedBox.expand(
            child: TogetherBackground(
              type: TogetherBackgroundType.home,
              respectTopSafeArea: true,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.top, 42);
    expect(positioned.left, 0);
    expect(positioned.right, 0);
    expect(positioned.bottom, 0);
  });

  testWidgets('default background behavior remains edge-to-edge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.expand(
          child: TogetherBackground(
            type: TogetherBackgroundType.home,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.top, 0);
  });
}
