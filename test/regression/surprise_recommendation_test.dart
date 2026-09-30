import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/core/services/location_service.dart';
import '../../lib/core/services/surprise_recommendation_service.dart';
import '../../lib/data/models/food.dart';
import '../../lib/data/models/recipe.dart';
import '../../lib/data/models/restaurant_discovery.dart';
import '../../lib/data/repositories/restaurant_discovery_repository.dart';

class _Location implements LocationService {
  @override
  Future<UserLocation> currentLocation() async =>
      const UserLocation(latitude: 48.89, longitude: 8.70);
}

class _Discovery implements RestaurantDiscoveryRepository {
  UserLocation? location;
  String? cuisine;
  bool? deliveryOnly;
  int? limit;
  double? radius;

  @override
  Future<List<RestaurantDiscoveryResult>> search({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    int limit = 10,
    double radiusKm = 20,
  }) async {
    this.location = location;
    this.cuisine = cuisine;
    this.deliveryOnly = deliveryOnly;
    this.limit = limit;
    radius = radiusKm;
    return List.generate(
      12,
      (index) => RestaurantDiscoveryResult(
        id: '$index',
        name: 'Anbieter $index',
        city: 'Pforzheim',
        distanceKm: index + 0.4,
        latitude: 48.89,
        longitude: 8.70,
        deliveryAvailable: deliveryOnly,
      ),
    ).take(limit).toList();
  }
}

Recipe _recipe(String id) => Recipe(
      id: id,
      name: 'Rezept $id',
      description: '',
      servings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      difficulty: 'Einfach',
      instructions: const [],
      ingredients: const [],
    );

void main() {
  test('Überraschung Kochen liefert drei unterschiedliche Rezepte', () async {
    final service = SurpriseRecommendationService(
      locationService: _Location(),
      restaurantRepository: _Discovery(),
    );
    final result = await service.generate(
      savedRecipes: List.generate(6, (i) => _recipe('$i')),
      preferences: const {},
      foods: const <Food>[],
      seed: 0,
    );

    expect(result.decision.mode, FoodMode.cook);
    expect(result.recipes, hasLength(3));
    expect(result.recipes.map((r) => r.id).toSet(), hasLength(3));
  });

  test('Überraschung Essen gehen lädt maximal zehn Restaurants mit 20 km', () async {
    final repository = _Discovery();
    final service = SurpriseRecommendationService(
      locationService: _Location(),
      restaurantRepository: repository,
    );
    final result = await service.generate(
      savedRecipes: List.generate(4, (i) => _recipe('$i')),
      preferences: const {},
      foods: const <Food>[],
      seed: 9,
    );

    expect(result.decision.mode, FoodMode.dineOut);
    expect(result.restaurants, hasLength(10));
    expect(repository.cuisine, isEmpty);
    expect(repository.deliveryOnly, isFalse);
    expect(repository.limit, 10);
    expect(repository.radius, 20);
    expect(repository.location?.latitude, 48.89);
  });

  test('Überraschung Bestellen fordert Delivery und maximal zehn Anbieter an', () async {
    final repository = _Discovery();
    final service = SurpriseRecommendationService(
      locationService: _Location(),
      restaurantRepository: repository,
    );
    final result = await service.generate(
      savedRecipes: List.generate(4, (i) => _recipe('$i')),
      preferences: const {},
      foods: const <Food>[],
      seed: 7,
    );

    expect(result.decision.mode, FoodMode.order);
    expect(result.restaurants, hasLength(10));
    expect(repository.deliveryOnly, isTrue);
    expect(repository.limit, 10);
    expect(repository.radius, 20);
  });
}
