import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supabase migration timestamps are unique', () {
    final files = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .where((name) => RegExp(r'^\d{14}_.*\.sql$').hasMatch(name))
        .toList();
    final timestamps = files.map((name) => name.substring(0, 14)).toList();
    expect(timestamps.length, timestamps.toSet().length);
  });
}
