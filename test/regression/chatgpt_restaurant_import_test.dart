import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatGPT restaurant search defines versioned JSON and required fields', () {
    final source = File('lib/features/food_modes/chatgpt_restaurant_page.dart').readAsStringSync();
    expect(source, contains("'schema_version': 1"));
    expect(source, contains("'type': 'fatzomat_restaurant_suggestion'"));
    for (final field in ['name', 'cuisine', 'address', 'phone', 'website', 'opening_hours']) {
      expect(source, contains("'$field'"));
    }
    expect(source, contains('radius of 10 kilometers'));
    expect(source, contains('FilePicker.platform.pickFiles'));
    expect(source, contains('Unbekanntes JSON-Format'));
    expect(source, contains('Als heutigen Vorschlag übernehmen'));
  });

  test('ChatGPT restaurant search is an additional option on dine-out page', () {
    final source = File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();
    expect(source, contains("import 'chatgpt_restaurant_page.dart';"));
    expect(source, contains("const Text('Mit ChatGPT suchen')"));
    expect(source, contains('if (widget.mode == FoodMode.dineOut)'));
    expect(source, contains('DiscoveryPage('));
  });
}
