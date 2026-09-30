import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/controllers/async_controller.dart';

class _Controller extends AsyncController<String> {
  bool fail = false;
  final List<Completer<String>> pending = [];
  @override
  Future<String?> fetch() async {
    if (fail) throw StateError('boom');
    if (pending.isNotEmpty) return pending.removeAt(0).future;
    return 'ok';
  }
}

void main() {
  test('tracks loading and successful data', () async {
    final controller = _Controller();
    await controller.load();
    expect(controller.loading, isFalse);
    expect(controller.data, 'ok');
    expect(controller.error, isNull);
    controller.dispose();
  });

  test('normalizes controller errors', () async {
    final controller = _Controller()..fail = true;
    await controller.load();
    expect(controller.loading, isFalse);
    expect(controller.error, isNotNull);
    controller.dispose();
  });

  test('keeps the newest load authoritative when an older response arrives later', () async {
    final controller = _Controller();
    final first = Completer<String>();
    final second = Completer<String>();
    controller.pending
      ..add(first)
      ..add(second);

    final firstLoad = controller.load();
    final secondLoad = controller.load();

    second.complete('new');
    await secondLoad;
    first.complete('old');
    await firstLoad;

    expect(controller.data, 'new');
    expect(controller.loading, isFalse);
    controller.dispose();
  });

  test('does not notify after disposal while an in-flight load finishes', () async {
    final controller = _Controller();
    final pending = Completer<String>();
    controller.pending.add(pending);
    var notifications = 0;
    controller.addListener(() => notifications++);

    final load = controller.load();
    expect(notifications, 1); // loading=true notification happened before dispose.
    controller.dispose();

    pending.complete('late');
    await load;

    expect(controller.data, isNull);
    expect(controller.loading, isTrue);
    expect(notifications, 1);
  });

  test('does not publish a stale error after disposal', () async {
    final controller = _Controller();
    final pending = Completer<String>();
    controller.pending.add(pending);

    final load = controller.load();
    controller.dispose();

    pending.completeError(StateError('late failure'));
    await load;

    expect(controller.data, isNull);
    expect(controller.error, isNull);
    expect(controller.loading, isTrue);
  });

  test('only the newest of three overlapping loads may publish state', () async {
    final controller = _Controller();
    final first = Completer<String>();
    final second = Completer<String>();
    final third = Completer<String>();
    controller.pending
      ..add(first)
      ..add(second)
      ..add(third);

    final firstLoad = controller.load();
    final secondLoad = controller.load();
    final thirdLoad = controller.load();

    third.complete('newest');
    await thirdLoad;
    first.complete('oldest');
    await firstLoad;
    second.complete('middle');
    await secondLoad;

    expect(controller.data, 'newest');
    expect(controller.error, isNull);
    expect(controller.loading, isFalse);
    controller.dispose();
  });

  test('a stale failure cannot overwrite a newer successful load', () async {
    final controller = _Controller();
    final first = Completer<String>();
    final second = Completer<String>();
    controller.pending
      ..add(first)
      ..add(second);

    final firstLoad = controller.load();
    final secondLoad = controller.load();

    second.complete('new');
    await secondLoad;
    first.completeError(StateError('old failure'));
    await firstLoad;

    expect(controller.data, 'new');
    expect(controller.error, isNull);
    expect(controller.loading, isFalse);
    controller.dispose();
  });
}
