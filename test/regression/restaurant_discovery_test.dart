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
  testWidgets('Wir gehen essen zeigt die kuratierte Küchenliste ohne Asiatisch', (tester) async {
    final repository = _FakeDiscoveryRepository([_result('1', 1.2)]);
    await tester.pumpWidget(MaterialApp(
      home: FoodModePage(
        mode: FoodMode.dineOut,
        locationService: _FakeLocationService(const UserLocation(latitude: 48.89, longitude: 8.70)),
        discoveryRepository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    for (final cuisine in const [
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
    ]) {
      expect(find.text(cuisine), findsOneWidget, reason: 'Missing cuisine: $cuisine');
    }
    expect(find.text('Asiatisch'), findsNothing);
  });

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

  testWidgets('Restaurantdetail zeigt Adresse, Kontakte und Auswahl in sauberer Reihenfolge', (tester) async {
    final result = RestaurantDiscoveryResult(
      id: 'x',
      name: 'Asiadong-Gourmet',
      address: 'Westliche Karl-Friedrich-Straße 123',
      postalCode: '75172',
      city: 'Pforzheim',
      distanceKm: 2.3,
      latitude: 48.89,
      longitude: 8.70,
      phone: '+49 7231 586670',
      website: Uri.parse('https://example.com'),
      openingHours: 'Tu 11:30-15:00,17:30-22:30; We-Fr 11:30-15:00,17:30-22:30',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RestaurantDetailPage(
          result: result,
          order: false,
          onSelect: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asiadong-Gourmet'), findsOneWidget);
    expect(find.text('Westliche Karl-Friedrich-Straße 123\n75172 Pforzheim\n2,3 km'), findsOneWidget);
    expect(find.text('+49 7231 586670'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('Di 11:30-15:00, 17:30-22:30\nMi-Fr 11:30-15:00, 17:30-22:30'), findsOneWidget);
    expect(find.text('Für heute auswählen'), findsOneWidget);
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

  test('Restaurantsuche aktualisiert die Supabase-Sitzung und nutzt die Datenbank-Suche', () {
    final source = File('lib/data/repositories/restaurant_discovery_repository.dart').readAsStringSync();
    expect(source, contains('await client.auth.refreshSession();'));
    expect(source, contains("'search_restaurants'"));
    expect(source, contains("'p_radius_km': 10"));
    expect(source, contains("'p_limit': limit.clamp(1, 10).toInt()"));
    expect(source, isNot(contains("_nominatimFallback")));
    expect(source, isNot(contains("nominatim.openstreetmap.org")));
    final functionSource = File('supabase/functions/restaurant-discovery/index.ts').readAsStringSync();
    final searchMigrationSource = File('supabase/migrations/20261004185400_restaurant_search_cuisine_expansion.sql').readAsStringSync();
    final postalMigrationSource = File('supabase/migrations/20261008161500_restaurant_postal_code.sql').readAsStringSync();
    expect(functionSource, contains("radiusKm !== 10"));
    expect(functionSource, contains('(around:10000,'));
    expect(functionSource, contains('contactPhone'));
    expect(functionSource, contains('contactWebsite'));
    expect(functionSource, contains('PHOTON_ENDPOINT'));
    expect(functionSource, contains('deliveryMetadata'));
    expect(functionSource, contains('delivery_filter'));
    expect(postalMigrationSource, contains('postal_code text'));
    expect(postalMigrationSource, contains("metadata #>> '{osm_tags,addr:postcode}'"));
    expect(postalMigrationSource, contains('overture_postcode'));
    expect(searchMigrationSource, contains("when 'Italienisch' then array['italian']"));
    expect(searchMigrationSource, contains("when 'Griechisch' then array['greek']"));
    expect(searchMigrationSource, contains("when 'Türkisch' then array['turkish']"));
    expect(searchMigrationSource, contains("when 'Japanisch' then array['japanese']"));
    expect(searchMigrationSource, contains("when 'Chinesisch' then array['chinese']"));
    expect(searchMigrationSource, contains("when 'Thailändisch' then array['thai']"));
    expect(searchMigrationSource, contains("when 'Vietnamesisch' then array['vietnamese']"));
    expect(searchMigrationSource, contains("when 'Koreanisch' then array['korean']"));
    expect(searchMigrationSource, contains("when 'Indonesisch' then array['indonesian']"));
    expect(searchMigrationSource, contains("when 'Malaysisch' then array['malaysian']"));
    expect(searchMigrationSource, contains("when 'Spanisch' then array['spanish']"));
    expect(searchMigrationSource, contains("when 'Libanesisch' then array['lebanese']"));
    expect(searchMigrationSource, contains("when 'Portugiesisch' then array['portuguese']"));
    expect(searchMigrationSource, contains("when 'Vegan' then array['vegan']"));
    expect(searchMigrationSource, contains("when 'Burger' then array['burger']"));
    expect(searchMigrationSource, contains("when 'Sushi' then array['sushi']"));
    expect(searchMigrationSource, contains("when 'Pizza' then array['pizza','italian_pizza']"));
    expect(searchMigrationSource, contains("when 'Steak' then array['steak','steak_house']"));
    expect(searchMigrationSource, contains("when 'Döner' then array['kebab','doner','döner']"));
    expect(searchMigrationSource, contains("when 'Indisch' then array['indian']"));
    expect(searchMigrationSource, contains("when 'Mexikanisch' then array['mexican']"));
    expect(searchMigrationSource, contains("when 'Asiatisch' then array['asian','chinese','thai','vietnamese','korean','indonesian','malaysian']"));
    expect(functionSource, contains("return requested.some((value) => values.includes(normalizeSearchText(value)));"));
    expect(functionSource, isNot(contains("const nameFilter")));
    expect(functionSource, isNot(contains("const searchable =")));
    expect(functionSource, contains("PHOTON_ENDPOINT + 'api/?'"));
    expect(functionSource, contains("params.append('include', photonCuisineCategories(cuisine).join(','));"));
    expect(functionSource, isNot(contains("for (const category of photonCuisineCategories(cuisine))")));
    expect(functionSource, isNot(contains("radius: '10'")));
    expect(functionSource, contains("[cuisine~\"(' + cuisinePattern + ')\",i]"));
    expect(functionSource, contains('cuisineSearchFallbackMatches'));
    expect(functionSource, contains('Never inspect the name here'));
    expect(functionSource, contains('if (results.length > 0) {'));


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
