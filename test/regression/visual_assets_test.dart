import 'dart:async';
import 'dart:io';\nimport 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/core/launch_page.dart';
import 'package:food_app_mvp/features/home/home_page.dart';
import 'package:food_app_mvp/core/startup_page.dart';

void main() {
  const homeBackground =
      'assets/together/clean/background/home_photo_background.png';
  const cards = [
    'assets/together/clean/icons/icon_cooking.png',
    'assets/together/clean/icons/icon_delivery.png',
    'assets/together/clean/icons/icon_restaurant.png',
    'assets/together/clean/icons/icon_surprise.png',
  ];

  test('launch screen waits at least four seconds before continuing', () {
    expect(kLaunchMinimumDuration, const Duration(seconds: 4));
    expect(kLaunchTransitionDuration, const Duration(milliseconds: 350));
  });

  test('launch readiness waits for startup data when it is slower', () async {
    final startup = Completer<StartupLoadResult>();
    final minimum = Completer<void>();

    var completed = false;
    final future = waitForLaunchReadiness(
      startup: startup.future,
      minimumDuration: const Duration(seconds: 4),
      delay: (_) => minimum.future,
    ).then((_) => completed = true);

    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    minimum.complete();
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    startup.complete(const StartupLoadResult(onboardingCompleted: true));
    await future;
    expect(completed, isTrue);
  });

  test('launch readiness waits for the minimum duration when data is faster', () async {
    final minimum = Completer<void>();
    var completed = false;

    final future = waitForLaunchReadiness(
      startup: Future<StartupLoadResult>.value(
        const StartupLoadResult(onboardingCompleted: true),
      ),
      minimumDuration: const Duration(seconds: 4),
      delay: (_) => minimum.future,
    ).then((_) => completed = true);

    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    minimum.complete();
    await future;
    expect(completed, isTrue);
  });

  test('Schmackofatz launcher icon is the approved branding asset', () async {
    final data = await rootBundle.load('assets/branding/app_icon.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1024);
    expect(frame.image.height, 1024);
    frame.image.dispose();
    codec.dispose();

    final launcherConfig = await File('flutter_launcher_icons.yaml').readAsString();
    expect(launcherConfig, contains('image_path: assets/branding/app_icon.png'));
  });

  test('approved home background is a valid image', () async {
    final data = await rootBundle.load(homeBackground);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 940);
    expect(frame.image.height, 1672);
    frame.image.dispose();
    codec.dispose();
  });

  test('all four approved choice card PNGs are valid and consistent', () async {
    for (final asset in cards) {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 540, reason: asset);
      expect(frame.image.height, 480, reason: asset);
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets('home exposes all four choices as accessible buttons',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    expect(find.bySemanticsLabel('Wir kochen'), findsOneWidget);
    expect(find.bySemanticsLabel('Wir bestellen'), findsOneWidget);
    expect(find.bySemanticsLabel('Wir gehen essen'), findsOneWidget);
    expect(find.bySemanticsLabel('Überrasch mich'), findsOneWidget);
    semantics.dispose();
  });
}
