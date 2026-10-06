import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezept prüfen nutzt gut lesbare helle Bearbeiten- und Abschnittsflächen', () {
    final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();

    expect(source, contains("FilledButton.icon("));
    expect(source, contains("label: const Text('Rezept bearbeiten')"));
    expect(source, contains("backgroundColor: AppDesign.primarySoft"));
    expect(source, contains("foregroundColor: AppDesign.primaryDark"));
    expect(source, contains("class _SectionTitle extends StatelessWidget"));
    expect(source, contains("textAlign: TextAlign.center"));
    expect(source, contains("color: AppDesign.surface.withValues(alpha: .96)"));
  });
}
