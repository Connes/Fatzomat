import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/core/services/location_service.dart';
import '../../lib/data/models/restaurant_discovery.dart';
import '../../lib/data/repositories/restaurant_discovery_repository.dart';
import '../../lib/features/food_modes/food_mode_page.dart';

class _Location implements LocationService {
  @override
  Future<UserLocation> currentLocation() async => const UserLocation(latitude: 48.89, longitude: 8.70);
}

class _Repository implements RestaurantDiscoveryRepository {
  final bool delivery;
  _Repository(this.delivery);

  @override
  Future<List<RestaurantDiscoveryResult>> search({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    int limit = 10,
    double radiusKm = 20,
  }) async {
    expect(location.latitude, 48.89);
    expect(cuisine, delivery ? 'Pizza' : 'Italienisch');
    expect(deliveryOnly, delivery);
    expect(radiusKm, 20);
    expect(limit, 10);
    return [
      RestaurantDiscoveryResult(
        id: '1',
        name: delivery ? 'Pizza Lieferung' : 'Trattoria Test',
        city: 'Pforzheim',
        distanceKm: 3.2,
        latitude: 48.90,
        longitude: 8.70,
        deliveryAvailable: delivery,
        deliveryStatus: delivery ? 'verified' : 'unknown',
        phone: '+497231123',
        website: Uri.parse('https://example.com'),
        orderUri: delivery ? Uri.parse('https://example.com/order') : null,
      ),
    ];
  }
}

void main() {
  testWidgets('Lieferdienst-Discovery zeigt nur echte Lieferergebnisse', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DiscoveryPage(
        mode: FoodMode.order,
        preference: 'Pizza',
        locationService: _Location(),
        discoveryRepository: _Repository(true),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pizza Lieferung'), findsOneWidget);
    expect(find.text('3,2 km'), findsOneWidget);
    expect(find.text('Lieferung laut Datenquelle verfügbar'), findsOneWidget);
  });

  testWidgets('Restaurant-Discovery zeigt reale Treffer statt externe Suchlinks', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DiscoveryPage(
        mode: FoodMode.dineOut,
        preference: 'Italienisch',
        locationService: _Location(),
        discoveryRepository: _Repository(false),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Trattoria Test'), findsOneWidget);
    expect(find.text('3,2 km'), findsOneWidget);
    expect(find.text('Externe Suche'), findsNothing);
  });
}
