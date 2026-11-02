import '../../core/food_name_normalizer.dart';
import '../../data/models/food.dart';

enum CookingIngredientGroup { vegetables, side, other }

CookingIngredientGroup cookingIngredientGroup(Food food) {
  final category = food.category.trim().toLowerCase();
  final name = FoodNameNormalizer.normalize(food.name);

  bool hasAny(List<String> terms) => terms.any(
        (term) => FoodNameNormalizer.equivalentOrContains(name, term),
      );

  // Blattsalate sollen im Koch-Flow unter Sonstiges auftauchen, auch wenn
  // sie im Onboarding der Kategorie Gemüse zugeordnet sind.
  // Chicorée enthält ein é, das der allgemeine Such-Normalizer entfernt.
  final isSalad = name.contains('chicor') || hasAny(const [
    'salat', 'rucola', 'feldsalat', 'endivie', 'chicoree',
  ]);
  if (isSalad) return CookingIngredientGroup.other;

  // Diese Hülsenfrüchte werden im Koch-Flow bewusst bei Gemüse angeboten.
  final isBeanOrChickpea = hasAny(const [
    'schwarze bohne',
    'schwarze bohnen',
    'weisse bohne',
    'kidney bohne',
    'kichererbse',
  ]);
  if (isBeanOrChickpea) return CookingIngredientGroup.vegetables;

  final isPotato = name.contains('kartoffel');
  final isVegetable = category.contains('gemüse') ||
      category.contains('vegetable');
  if (isVegetable && !isPotato) {
    return CookingIngredientGroup.vegetables;
  }

  // Nur echte Beilagen bleiben in dieser Gruppe. Alle anderen Lebensmittel
  // aus dem Onboarding fallen automatisch in Sonstiges.
  final isRice = name.contains('reis');
  final isPasta = name.contains('nudel') || name.contains('pasta');
  final isSideOverride = hasAny(const [
    'couscous',
    'bulgur',
    'quinoa',
    'gnocchi',
    'brot',
    'baguette',
    'toast',
    'linsen',
  ]);
  final isOtherOverride = hasAny(const [
    'haferflocken',
    'semmelbroesel',
    'lasagneplatten',
    'tortilla',
  ]);

  if (isOtherOverride) return CookingIngredientGroup.other;

  final isSide = isRice ||
      isPasta ||
      isPotato ||
      isSideOverride ||
      category == 'getreide & beilagen';
  if (isSide) return CookingIngredientGroup.side;

  return CookingIngredientGroup.other;
}
