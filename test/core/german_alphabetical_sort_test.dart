import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/german_alphabetical_sort.dart';

void main() {
  test('sorts names case-insensitively and treats German umlauts like base vowels', () {
    final values = sortByGermanName(
      ['Zucchini', 'Äpfel', 'Öl', 'Apfel', 'Übriges', 'Banane', 'ß'],
      (value) => value,
    );

    expect(values, ['Äpfel', 'Apfel', 'Banane', 'Öl', 'ß', 'Übriges', 'Zucchini']);
  });

  test('sorts objects by their displayed food name without mutating input', () {
    final input = ['Tomate', 'Apfel', 'Karotte'];
    final sorted = sortByGermanName(input, (value) => value);

    expect(sorted, ['Apfel', 'Karotte', 'Tomate']);
    expect(input, ['Tomate', 'Apfel', 'Karotte']);
  });
}
