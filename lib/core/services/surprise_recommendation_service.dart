import 'dart:math';

import '../../core/food_mode.dart';
import '../../data/models/food.dart';
import '../../data/models/recipe.dart';
import '../../data/models/restaurant_discovery.dart';
import '../../data/repositories/restaurant_discovery_repository.dart';
import 'location_service.dart';
import 'personalized_decision_service.dart';

class SurpriseRecommendation {
  final PersonalizedDecision decision;
  final List<Recipe> recipes;
  final List<RestaurantDiscoveryResult> restaurants;

  const SurpriseRecommendation({
    required this.decision,
    this.recipes = const [],
    this.restaurants = const [],
  });

  bool get isRecipe => decision.mode == FoodMode.cook;
  bool get isRestaurant => decision.mode != FoodMode.cook;
}

class SurpriseRecommendationService {
  final RestaurantDiscoveryRepository restaurantRepository;
  final LocationService locationService;

  SurpriseRecommendationService({
    RestaurantDiscoveryRepository? restaurantRepository,
    LocationService? locationService,
  }) : restaurantRepository = restaurantRepository ?? const SupabaseRestaurantDiscoveryRepository(),
        locationService = locationService ?? const DeviceLocationService();

  Future<SurpriseRecommendation> generate({
    required List<Recipe> savedRecipes,
    required Map<String, String> preferences,
    required List<Food> foods,
    int? seed,
  }) async {
    final decision = PersonalizedDecisionService.decide(
      savedRecipes: savedRecipes,
      preferences: preferences,
      foods: foods,
      seed: seed,
    );

    if (decision.mode == FoodMode.cook) {
      final recipes = _pickRecipes(savedRecipes, seed ?? DateTime.now().microsecondsSinceEpoch);
      return SurpriseRecommendation(decision: decision, recipes: recipes);
    }

    final location = await locationService.currentLocation();
    final results = await restaurantRepository.search(
      location: location,
      cuisine: '',
      deliveryOnly: decision.mode == FoodMode.order,
      limit: 10,
      radiusKm: 20,
    );
    return SurpriseRecommendation(decision: decision, restaurants: results.take(10).toList(growable: false));
  }

  List<Recipe> _pickRecipes(List<Recipe> source, int seed) {
    final candidates = source.where((recipe) => recipe.id != null && recipe.name.trim().isNotEmpty).toList();
    if (candidates.length <= 3) return List.unmodifiable(candidates);
    final random = Random(seed);
    candidates.shuffle(random);
    return List.unmodifiable(candidates.take(3));
  }
}
