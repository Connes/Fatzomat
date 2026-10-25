import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/features/recipes/together_chatgpt_prompt.dart';

void main() {
  test('builds a together_recipe prompt with selected foods', () {
    final prompt = TogetherChatGptPrompt.build(
      mainChoice: 'Huhn',
      selectedFoods: const [
        Food(id: 'f1', name: 'Brokkoli', category: 'Gemüse', defaultUnit: 'g'),
        Food(id: 'f2', name: 'Reis', category: 'Beilage', defaultUnit: 'g'),
      ],
    );

    expect(prompt, contains('Hauptauswahl / Rezeptbasis:\nHuhn'));
    expect(prompt, contains('- Brokkoli'));
    expect(prompt, contains('- Reis'));
    expect(prompt, isNot(contains('(Einheit:')));
    expect(prompt, contains('"format": "together_recipe"'));
    expect(prompt, contains('"version": 1'));
    expect(prompt, isNot(contains('PDF-Datei')));
    expect(prompt, contains('DATEINAME: together_recipe.json'));
    expect(prompt, contains('echte Datei „together_recipe.json“'));
    expect(prompt, contains('Huhn'));
    expect(prompt, contains('alle von mir ausgewählten Zutaten'));
    expect(prompt, contains('is_user_selected'));
    expect(prompt, contains('is_additional'));
    expect(prompt, contains('ausschließlich'));
    expect(prompt, contains('höchstens 40 Zeichen'));
    expect(prompt, contains('recipe.title in der späteren JSON-Datei'));
    expect(prompt, contains('höchstens 40 Zeichen enthalten'));
  });

  test('allows a prompt without additional ingredients', () {
    final prompt = TogetherChatGptPrompt.build(
      mainChoice: 'Vegetarisch',
      selectedFoods: const [],
    );

    expect(prompt, contains('Hauptauswahl / Rezeptbasis:\nVegetarisch'));
    expect(prompt, contains('Keine zusätzlichen Zutaten ausgewählt.'));
    expect(prompt, contains('Du darfst sinnvolle zusätzliche Zutaten ergänzen'));
  });

  test('prioritizes recipe file output and does not request image generation in the same prompt', () {
    final prompt = TogetherChatGptPrompt.build(
      mainChoice: 'Fisch',
      selectedFoods: const [],
    );

    expect(prompt, contains('DATEINAME: together_recipe.json'));
    expect(prompt, contains('PHASE 1 – DREI VORSCHLÄGE'));
    expect(prompt, contains('genau drei deutlich unterschiedliche Gerichte'));
    expect(prompt, contains('PHASE 2 – NACH MEINER AUSWAHL'));
    expect(prompt, contains('keine JSON-Ausgabe, kein vollständiges Rezept, keine Datei'));
    expect(prompt, contains('Erst nach meiner Auswahl'));
    expect(prompt, contains('Erst nach meiner Auswahl: Erzeuge „together_recipe.json“'));
    expect(prompt, contains('recipe.title'));
    expect(prompt, contains('das vollständige rohe JSON als Chat-Antwort'));
    expect(prompt, contains('Generiere kein Bild und rufe keine Bildgenerierung auf.'));
    expect(prompt, isNot(contains('generiere AUTOMATISCH und direkt anschließend')));
    expect(prompt, isNot(contains('fotorealistisches, appetitliches Bild')));
  });

  test('photo import prompt continues to return only recipe JSON', () {
    final prompt = TogetherChatGptPrompt.buildPhotoImportPrompt();

    expect(prompt, contains('together_recipe.json'));
    expect(prompt, contains('Das Ergebnis muss syntaktisch gültiges JSON sein.'));
    expect(prompt, contains('Gib nur das JSON bzw. die erzeugte Datei zurück.'));
  });
}
