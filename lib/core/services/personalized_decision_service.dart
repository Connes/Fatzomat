import '../food_mode.dart';
import '../../data/models/recipe.dart';
import '../../data/models/food.dart';
import 'food_decision_service.dart';

class PersonalizedDecision {
  final FoodMode mode;
  final String choice;
  final String reason;

  const PersonalizedDecision({
    required this.mode,
    required this.choice,
    required this.reason,
  });
}

class PersonalizedDecisionService {
  static PersonalizedDecision decideForMode({
    required FoodMode mode,
    required List<Recipe> savedRecipes,
    required Map<String, String> preferences,
    required List<Food> foods,
    int? seed,
  }) {
    final randomSeed = seed ?? DateTime.now().microsecondsSinceEpoch;
    final disliked = preferences.entries
        .where((entry) => entry.value == 'dislike')
        .map((entry) => _foodName(foods, entry.key).toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();
    final liked = preferences.entries
        .where((entry) => entry.value == 'like')
        .map((entry) => _foodName(foods, entry.key).toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();
    final recentNames = savedRecipes
        .take(12)
        .map((recipe) => recipe.name.toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();
    final choice = _pickChoice(mode, recentNames, disliked, randomSeed);
    return PersonalizedDecision(
      mode: mode,
      choice: choice,
      reason: _reason(
        mode: mode,
        choice: choice,
        savedCount: savedRecipes.length,
        likedCount: liked.length,
        dislikedCount: disliked.length,
      ),
    );
  }

  static PersonalizedDecision decide({
    required List<Recipe> savedRecipes,
    required Map<String, String> preferences,
    required List<Food> foods,
    int? seed,
  }) {
    final randomSeed = seed ?? DateTime.now().microsecondsSinceEpoch;
    final disliked = preferences.entries
        .where((entry) => entry.value == 'dislike')
        .map((entry) => _foodName(foods, entry.key).toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();
    final liked = preferences.entries
        .where((entry) => entry.value == 'like')
        .map((entry) => _foodName(foods, entry.key).toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();

    final recentNames = savedRecipes
        .take(12)
        .map((recipe) => recipe.name.toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();

    final modeScores = <FoodMode, int>{
      FoodMode.cook: 3 + (savedRecipes.length.clamp(0, 4)),
      FoodMode.order: 2,
      FoodMode.dineOut: 2,
    };

    if (liked.any((food) => _containsAny(food, ['reis', 'nudel', 'pasta', 'tomate', 'huhn', 'gemüse']))) {
      modeScores[FoodMode.cook] = modeScores[FoodMode.cook]! + 1;
    }
    if (savedRecipes.isEmpty) {
      modeScores[FoodMode.order] = modeScores[FoodMode.order]! + 1;
      modeScores[FoodMode.dineOut] = modeScores[FoodMode.dineOut]! + 1;
    }

    final mode = _pickWeighted(modeScores, randomSeed);
    final choice = _pickChoice(mode, recentNames, disliked, randomSeed ~/ 7 + 11);

    final reason = _reason(
      mode: mode,
      choice: choice,
      savedCount: savedRecipes.length,
      likedCount: liked.length,
      dislikedCount: disliked.length,
    );

    return PersonalizedDecision(mode: mode, choice: choice, reason: reason);
  }

  static FoodMode _pickWeighted(Map<FoodMode, int> scores, int seed) {
    final total = scores.values.fold<int>(0, (sum, value) => sum + value);
    var cursor = seed.abs() % total;
    for (final entry in scores.entries) {
      if (cursor < entry.value) return entry.key;
      cursor -= entry.value;
    }
    return FoodMode.cook;
  }

  static String _pickChoice(
    FoodMode mode,
    List<String> recentNames,
    List<String> disliked,
    int seed,
  ) {
    final choices = switch (mode) {
      FoodMode.cook => FoodDecisionService.cookChoices,
      FoodMode.order => FoodDecisionService.orderChoices,
      FoodMode.dineOut => FoodDecisionService.dineOutChoices,
    };

    final candidates = choices.where((choice) {
      final normalized = choice.toLowerCase();
      if (disliked.any((food) => normalized.contains(food))) return false;
      if (mode != FoodMode.cook) return true;
      return !recentNames.any((name) => _containsAny(name, [normalized]));
    }).toList();

    final pool = candidates.isEmpty ? choices : candidates;
    return pool[seed.abs() % pool.length];
  }

  static bool _containsAny(String value, List<String> needles) =>
      needles.any((needle) => needle.isNotEmpty && value.contains(needle));

  static String _foodName(List<Food> foods, String id) => foods.where((food) => food.id == id).map((food) => food.name).firstOrNull ?? '';

  static String _reason({
    required FoodMode mode,
    required String choice,
    required int savedCount,
    required int likedCount,
    required int dislikedCount,
  }) {
    if (savedCount >= 3 && mode == FoodMode.cook) {
      return 'Ihr habt schon einige Rezepte gesammelt. Ich schicke euch heute in eine neue Richtung.';
    }
    if (likedCount > 0 && dislikedCount > 0) {
      return 'Ich berücksichtige eure Vorlieben und lasse bekannte No-Gos außen vor.';
    }
    if (likedCount > 0) {
      return 'Ich berücksichtige eure gespeicherten Vorlieben.';
    }
    if (savedCount > 0) {
      return 'Ich orientiere mich an eurer bisherigen Auswahl und vermeide Wiederholungen.';
    }
    return 'Noch keine Historie? Dann darf der Zufall heute ein bisschen arbeiten.';
  }
}
