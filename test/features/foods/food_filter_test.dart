import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/features/foods/food_filter.dart';

void main() {
  final foods = const [
    Food(id: 'tomato', name: 'Tomate', category: 'Gemüse'),
    Food(id: 'apple', name: 'Apfel', category: 'Obst'),
    Food(id: 'rice', name: 'Reis', category: 'Getreide'),
  ];
  const preferences = {'tomato': 'like', 'apple': 'dislike'};

  test('filters by search text', () {
    final result = filterFoods(
      foods: foods,
      preferences: preferences,
      query: 'tom',
      preferenceFilter: 'all',
      categoryFilter: 'Alle',
    );
    expect(result.map((food) => food.id), ['tomato']);
  });

  test('filters by preference and category', () {
    final result = filterFoods(
      foods: foods,
      preferences: preferences,
      query: '',
      preferenceFilter: 'like',
      categoryFilter: 'Gemüse',
    );
    expect(result.map((food) => food.id), ['tomato']);
  });
}
