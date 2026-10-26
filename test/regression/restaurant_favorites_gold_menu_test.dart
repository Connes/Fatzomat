import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant favorites overflow and edit icons use brand gold only on icons', () {
    final source = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();

    expect(source, contains('child: Icon(Icons.more_vert_rounded, color: AppDesign.iconGold)'));
    expect(source, contains('leading: Icon(Icons.edit_outlined, color: AppDesign.iconGold)'));
    expect(source, contains("title: Text('Bearbeiten')"));
    expect(source, contains("title: Text('Löschen', style: TextStyle(color: AppDesign.error))"));
  });
}
