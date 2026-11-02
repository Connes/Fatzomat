import '../../core/food_name_normalizer.dart';
import '../../data/models/food.dart';

enum CookingIngredientGroup { vegetables, side, other, hidden }

CookingIngredientGroup cookingIngredientGroup(Food food) {
  final category = food.category.trim().toLowerCase();
  final name = FoodNameNormalizer.normalize(food.name);

  bool hasAny(List<String> terms) => terms.any(
        (term) => FoodNameNormalizer.equivalentOrContains(name, term),
      );

  final isSalad = hasAny(const [
    'salat', 'rucola', 'feldsalat', 'endivie', 'chicoree',
  ]);
  if (isSalad) return CookingIngredientGroup.other;

  final isPotato = name.contains('kartoffel');
  final isBeanOrChickpea = hasAny(const [
    'schwarze bohne', 'weisse bohne', 'kidney bohne', 'kichererbse',
  ]);
  if (isBeanOrChickpea) return CookingIngredientGroup.vegetables;

  final isVegetable = category.contains('gemüse') ||
      category.contains('vegetable');
  if (isVegetable && !isPotato) {
    return CookingIngredientGroup.vegetables;
  }

  final isRice = name == 'reis';
  final isRiceVariant = hasAny(const ['basmatireis', 'vollkornreis', 'risottoreis']);
  if (isRiceVariant) return CookingIngredientGroup.hidden;
  final isPasta = name.contains('nudel') || name.contains('pasta');
  final isSideOverride = hasAny(const [
    'couscous', 'bulgur', 'quinoa', 'gnocchi', 'brot', 'baguette',
    'toast', 'linsen',
  ]);
  final isOtherOverride = hasAny(const [
    'haferflocken', 'semmelbroesel', 'lasagneplatten', 'tortilla',
  ]);

  if (isOtherOverride) return CookingIngredientGroup.other;

  final isSide = isRice || isPasta || isPotato || isSideOverride ||
      category == 'getreide & beilagen' ||
      category == 'hülsenfrüchte' && hasAny(const ['linsen']);
  if (isSide) return CookingIngredientGroup.side;

  return CookingIngredientGroup.other;
}
