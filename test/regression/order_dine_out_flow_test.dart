import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/core/services/location_service.dart';
import '../../lib/data/models/restaurant_discovery.dart';
import '../../lib/data/repositories/restaurant_discovery_repository.dart';
import '../../lib/features/food_modes/food_mode_page.dart';
import '../../lib/features/food_modes/chatgpt_restaurant_page.dart';
import '../../lib/features/food_modes/restaurant_detail_page.dart';

class _FakeLocationService implements LocationService {
  final UserLocation location;
  _FakeLocationService(this.location);
  @override
  Future<UserLocation> currentLocation() async => location;
}

class _FakeDiscoveryRepository implements RestaurantDiscoveryRepository {
  final List<RestaurantDiscoveryResult> results;
  String? cuisine;
  bool? deliveryOnly;
  _FakeDiscoveryRepository(this.results);

  @override
  Future<List<RestaurantDiscoveryResult>> search({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    int limit = 10,
    double radiusKm = 10,
  }) async {
    this.cuisine = cuisine;
    this.deliveryOnly = deliveryOnly;
    expect(location.latitude, 48.89);
    expect(location.longitude, 8.70);
    expect(radiusKm, 10);
    expect(limit, 10);
    return results;
  }
}

class _FailingLocationService implements LocationService {
  @override
  Future<UserLocation> currentLocation() async {
    throw const LocationException('Standorttestfehler');
  }
}

RestaurantDiscoveryResult _restaurant(String cuisine) => RestaurantDiscoveryResult(
      id: cuisine,
      name: '$cuisine Testrestaurant',
      city: 'Pforzheim',
      distanceKm: 2.1,
      latitude: 48.89,
      longitude: 8.70,
      deliveryAvailable: true,
      phone: '+497231123',
      website: Uri.parse('https://example.com'),
      orderUri: Uri.parse('https://example.com/order'),
    );

const _dineOutChoices = [
  'Italienisch',
  'Griechisch',
  'Türkisch',
  'Japanisch',
  'Chinesisch',
  'Thailändisch',
  'Vietnamesisch',
  'Koreanisch',
  'Indonesisch',
  'Malaysisch',
  'Sushi',
  'Burger',
  'Steak',
  'Mexikanisch',
  'Spanisch',
  'Libanesisch',
  'Portugiesisch',
  'Vegetarisch',
  'Vegan',
];

void main() {
  for (final choice in _dineOutChoices) {
    testWidgets('Wir gehen essen: $choice öffnet ChatGPT mit der gewählten Küche', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FoodModePage(
          mode: FoodMode.dineOut,
          locationService: _FakeLocationService(
            const UserLocation(latitude: 48.89, longitude: 8.70),
          ),
          discoveryRepository: _FakeDiscoveryRepository([_restaurant(choice)]),
        ),
      ));
      await tester.pumpAndSettle();

      final choiceCard = find.byKey(ValueKey<String>('food_choice_dineOut_$choice'));
      expect(choiceCard, findsOneWidget, reason: 'Auswahl $choice fehlt');
      await tester.ensureVisible(choiceCard);
      await tester.tap(choiceCard);
      // The restaurant page starts device-location lookup asynchronously and
      // may show an indeterminate progress indicator, so don't use pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ChatGptRestaurantPage), findsOneWidget);
      final cuisineField = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(cuisineField.initialValue, choice);
    });
  }

  testWidgets('Standortfehler zeigt eine verständliche Fehlerseite statt eines Crashes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DiscoveryPage(
        mode: FoodMode.order,
        preference: 'Burger',
        locationService: _FailingLocationService(),
        discoveryRepository: _FakeDiscoveryRepository(const []),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Suche nicht möglich'), findsOneWidget);
    expect(find.text('Standorttestfehler'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('Restaurantdetails zeigen für Essen gehen keine Bestellaktion', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RestaurantDetailPage(result: _restaurant('Italienisch'), order: false)));
    await tester.pumpAndSettle();

    expect(find.text('Telefon'), findsOneWidget);
    expect(find.text('Webseite'), findsOneWidget);
    expect(find.text('Bestellen / Lieferung'), findsNothing);
  });
}
