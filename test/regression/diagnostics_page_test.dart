import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V1.6.7 updates the diagnostics release version', () {
    // Keep this regression intentionally file-based so it does not require
    // a live Supabase connection.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: 1.13.37+249'));
  });
}
