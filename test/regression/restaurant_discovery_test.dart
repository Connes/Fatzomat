import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/core/services/location_service.dart';
import '../../lib/data/models/restaurant_discovery.dart';
import '../../lib/data/repositories/restaurant_discovery_repository.dart';
import '../../lib/features/food_modes/food_mode_page.dart';
import '../../lib/features/food_modes/restaurant_detail_page.dart';

class _FakeLocationService implements LocationService {
  final UserLocation location;
  _FakeLocationService(this.location);

  @override
  Future<UserLocation> currentLocation() async => location;
}

class _FakeDiscoveryRepository implements RestaurantDiscoveryRepository {
  final List<RestaurantDiscoveryResult> results;
  UserLocation? requestedLocation;
  String? requestedCuisine;
  bool? requestedDeliveryOnly;

  _FakeDiscoveryRepository(this.results);

  @override
  Future<List<RestaurantDiscoveryResult>> search({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    int limit = 10,
    double radiusKm = 10,
  }) async {
    requestedLocation = location;
    requestedCuisine = cuisine;
    requestedDeliveryOnly = deliveryOnly;
    expect(radiusKm, 10);
    expect(limit, 10);
    return results.take(limit).toList();
  }
}

RestaurantDiscoveryResult _result(String id, double distance, {bool delivery = false}) => RestaurantDiscoveryResult(
      id: id,
      name: 'Anbieter $id',
      city: 'Pforzheim',
      distanceKm: distance,
      latitude: 48.89,
      longitude: 8.70,
      deliveryAvailable: delivery,
      phone: '+497231123',
      website: Uri.parse('https://example.com'),
      orderUri: delivery ? Uri.parse('https://example.com/order') : null,
    );

void main() {
  testWidgets('Wir gehen essen nutzt Küche, Standort, 10 km und maximal 10 Ergebnisse', (tester) async {
    final repository = _FakeDiscoveryRepository(List.generate(12, (i) => _result('$i', i < 10 ? i + .2 : 10.2 + i)));
    await tester.pumpWidget(MaterialApp(
      home: DiscoveryPage(
        mode: FoodMode.dineOut,
        preference: 'Italienisch',
        locationService: _FakeLocationService(const UserLocation(latitude: 48.89, longitude: 8.70)),
        discoveryRepository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Italienisch'), findsOneWidget);
    expect(find.text('Anbieter 0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Anbieter 9'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Anbieter 9'), findsOneWidget);
    expect(find.text('Anbieter 10'), findsNothing);
    expect(repository.requestedCuisine, 'Italienisch');
    expect(repository.requestedDeliveryOnly, isFalse);
    expect(repository.requestedLocation?.latitude, 48.89);
    expect(repository.results.take(10).every((item) => item.distanceKm <= 10), isTrue);
    expect(repository.results.skip(10).every((item) => item.distanceKm > 10), isTrue);
  });

  testWidgets('Wir bestellen fordert ausschließlich Lieferanbieter an', (tester) async {
    final repository = _FakeDiscoveryRepository(List.generate(3, (i) => _result('$i', i + .5, delivery: true)));
    await tester.pumpWidget(MaterialApp(
      home: DiscoveryPage(
        mode: FoodMode.order,
        preference: 'Pizza',
        locationService: _FakeLocationService(const UserLocation(latitude: 48.89, longitude: 8.70)),
        discoveryRepository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Restaurants zum Bestellen'), findsNothing);
    expect(find.textContaining('Bis zu 10 passende Restaurants'), findsNothing);
    expect(repository.requestedCuisine, 'Pizza');
    expect(repository.requestedDeliveryOnly, isTrue);
    expect(find.text('Lieferung laut Datenquelle verfügbar'), findsNWidgets(3));
  });

  testWidgets('Restaurantdetail zeigt nur tatsächlich vorhandene Kontaktdaten', (tester) async {
    final result = RestaurantDiscoveryResult(
      id: 'x',
      name: 'Ohne Kontaktdaten',
      distanceKm: 2.4,
      latitude: 48.89,
      longitude: 8.70,
    );
    await tester.pumpWidget(MaterialApp(home: RestaurantDetailPage(result: result, order: false)));
    await tester.pumpAndSettle();

    expect(find.text('Keine Kontaktdaten verfügbar'), findsOneWidget);
    expect(find.text('Telefon'), findsNothing);
    expect(find.text('Webseite'), findsNothing);
  });

  test('Restaurantsuche aktualisiert die Supabase-Sitzung vor dem Edge-Function-Aufruf', () {
    final source = File('lib/data/repositories/restaurant_discovery_repository.dart').readAsStringSync();
    expect(source, contains('await client.auth.refreshSession();'));
    final functionSource = File('supabase/functions/restaurant-discovery/index.ts').readAsStringSync();
    expect(functionSource, contains("radiusKm !== 10"));
    expect(functionSource, contains('(around:10000,'));
    expect(functionSource, contains('contactPhone'));
    expect(functionSource, contains('contactWebsite'));
    expect(functionSource, contains('PHOTON_ENDPOINT'));
    expect(functionSource, contains('deliveryMetadata'));
    expect(functionSource, contains('delivery_filter'));
    expect(functionSource, contains("Italienisch: ['italian']"));
    expect(functionSource, contains("Burger: ['burger']"));
    expect(functionSource, contains("Sushi: ['sushi']"));
    expect(functionSource, contains("Pizza: ['pizza', 'italian_pizza']"));
    expect(functionSource, contains("Steak: ['steak', 'steak_house']"));
    expect(functionSource, contains("Döner: ['kebab', 'doner', 'döner']"));
    expect(functionSource, contains("Indisch: ['indian']"));
    expect(functionSource, contains("Mexikanisch: ['mexican']"));
    expect(functionSource, contains("Asiatisch: ['asian', 'chinese', 'thai', 'vietnamese', 'korean', 'indonesian', 'malaysian']"));
    expect(functionSource, contains("return requested.some((value) => values.includes(normalizeSearchText(value)));"));
    expect(functionSource, isNot(contains("properties.name,"));
    expect(functionSource, isNot(contains("properties.osm_value")));
    expect(functionSource, isNot(contains("const nameFilter")));

    expect(functionSource, contains("delivery_filter: deliveryOnly ? 'verified_or_unknown' : 'not_requested'"));
    expect(functionSource, contains('if (deliveryOnly && delivery.status === \'not_available\') continue;'));
    expect(functionSource, contains('Prefer Overpass for the actual result payload'));
    final sourcePriority = functionSource.indexOf('Prefer Overpass for the actual result payload');
    expect(
      functionSource.indexOf('const results = buildResultsFromOverpass', sourcePriority),
      lessThan(functionSource.indexOf('const results = buildResultsFromPhoton', sourcePriority)),
    );

    final configSource = File('supabase/config.toml').readAsStringSync();
    expect(configSource, contains('[functions.restaurant-discovery]'));
    expect(configSource, contains('verify_jwt = false'));
  });
}
