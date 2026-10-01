import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/core/app_design.dart';
import '../../lib/core/services/location_service.dart';
import '../../lib/data/models/restaurant_discovery.dart';
import '../../lib/data/repositories/restaurant_discovery_repository.dart';
import '../../lib/features/food_modes/food_mode_page.dart';
import '../../lib/features/food_modes/restaurant_detail_page.dart';

class _Location implements LocationService {
  @override
  Future<UserLocation> currentLocation() async => const UserLocation(latitude: 48.89, longitude: 8.70);
}

class _Repository implements RestaurantDiscoveryRepository {
  final List<RestaurantDiscoveryResult> results;
  _Repository(this.results);

  @override
  Future<List<RestaurantDiscoveryResult>> search({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    int limit = 10,
    double radiusKm = 20,
  }) async => results.take(limit).toList();
}

void main() {
  testWidgets('Bestellen zeigt bis zu 10 Lieferanbieter innerhalb des festen 20-km-Radius', (tester) async {
    final results = List.generate(
      12,
      (i) => RestaurantDiscoveryResult(
        id: '$i',
        name: 'Anbieter $i',
        city: 'Pforzheim',
        distanceKm: i + 0.5,
        latitude: 48.89,
        longitude: 8.70,
        deliveryAvailable: true,
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: DiscoveryPage(
        mode: FoodMode.order,
        preference: 'Pizza',
        locationService: _Location(),
        discoveryRepository: _Repository(results),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('10 Treffer innerhalb von 20 km'), findsOneWidget);
    expect(find.text('Anbieter 0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Anbieter 9'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Anbieter 9'), findsOneWidget);
    expect(find.text('Anbieter 10'), findsNothing);
  });

  testWidgets('Leerer Restaurantzustand bleibt auf dem Bildhintergrund vollständig lesbar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DiscoveryPage(
        mode: FoodMode.order,
        preference: 'Pizza',
        locationService: _Location(),
        discoveryRepository: _Repository(const []),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AppSurface), findsOneWidget);
    expect(find.text('Keine passenden Restaurants zum Bestellen gefunden'), findsOneWidget);
    expect(find.text('Erneut suchen'), findsOneWidget);
  });

  testWidgets('Restaurant-Detail zeigt Telefon und Webseite, wenn vorhanden', (tester) async {
    final result = RestaurantDiscoveryResult(
      id: '1',
      name: 'Trattoria Test',
      city: 'Pforzheim',
      distanceKm: 2.4,
      latitude: 48.89,
      longitude: 8.70,
      phone: '+497231123',
      website: Uri.parse('https://example.com'),
    );
    await tester.pumpWidget(MaterialApp(
      home: RestaurantDetailPage(result: result, order: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Trattoria Test'), findsNWidgets(2));
    expect(find.text('+497231123'), findsOneWidget);
    expect(find.text('Webseite'), findsOneWidget);
    expect(find.text('2,4 km'), findsOneWidget);
  });
}
