import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/features/recipes/recipe_builder_filter.dart';

void main() {
  final foods = [
    {'id': '1', 'name': 'Tomaten', 'category': 'Gemüse'},
    {'id': '2', 'name': 'Reis', 'category': 'Getreide & Beilagen'},
    {'id': '3', 'name': 'Tomatensauce', 'category': 'Saucen & Grundzutaten'},
  ];

  test('filters by name', () {
    expect(filterRecipeFoods(foods: foods, query: 'tomat', category: 'Alle').length, 2);
  });

  test('filters by category', () {
    final result = filterRecipeFoods(
      foods: foods,
      query: '',
      category: 'Getreide & Beilagen',
    );
    expect(result.map((f) => f['name']), ['Reis']);
  });

  test('combines name and category filters', () {
    final result = filterRecipeFoods(
      foods: foods,
      query: 'tomat',
      category: 'Saucen & Grundzutaten',
    );
    expect(result.map((f) => f['name']), ['Tomatensauce']);
  });
}
