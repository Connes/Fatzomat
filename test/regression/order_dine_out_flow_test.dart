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
  Future<void> verifyChoiceFlow(
    WidgetTester tester, {
    required FoodMode mode,
    required String choice,
  }) async {
    final repository = _FakeDiscoveryRepository([_restaurant(choice)]);
    var selected = false;

    await tester.pumpWidget(MaterialApp(
      home: FoodModePage(
        mode: mode,
        locationService: _FakeLocationService(
          const UserLocation(latitude: 48.89, longitude: 8.70),
        ),
        discoveryRepository: repository,
        onResultSelected: (_) async => selected = true,
      ),
    ));
    await tester.pumpAndSettle();

    final choiceFinder = find.text(choice).first;
    expect(choiceFinder, findsOneWidget, reason: '$mode: Auswahl $choice fehlt');
    await tester.ensureVisible(choiceFinder);
    await tester.tap(choiceFinder);
    await tester.pumpAndSettle();

    expect(
      find.byType(DiscoveryPage),
      findsOneWidget,
      reason: '$mode/$choice öffnet keine Discovery-Seite',
    );
    expect(
      find.text('$choice Testrestaurant'),
      findsWidgets,
      reason: '$mode/$choice liefert keine Trefferseite',
    );
    expect(repository.cuisine, choice);
    expect(repository.deliveryOnly, mode == FoodMode.order);
    expect(find.textContaining('Suche nicht möglich'), findsNothing);
    expect(find.textContaining('Keine passenden'), findsNothing);

    final restaurantFinder = find.text('$choice Testrestaurant').last;
    await tester.ensureVisible(restaurantFinder);
    await tester.tap(restaurantFinder);
    await tester.pumpAndSettle();

    expect(
      find.byType(RestaurantDetailPage),
      findsOneWidget,
      reason: '$mode/$choice öffnet keine Restaurantdetails',
    );
    expect(find.text('$choice Testrestaurant'), findsWidgets);
    expect(find.text('Für heute auswählen'), findsOneWidget);

    final selectFinder = find.text('Für heute auswählen');
    await tester.ensureVisible(selectFinder);
    await tester.tap(selectFinder);
    await tester.pumpAndSettle();
    expect(
      selected,
      isTrue,
      reason: '$mode/$choice speichert die Auswahl nicht über den vollständigen Pfad',
    );
    expect(
      find.byType(FoodModePage),
      findsNothing,
      reason: '$mode/$choice bleibt nach der Auswahl fälschlich auf der Auswahlseite',
    );
  }

  for (final choice in _dineOutChoices) {
    testWidgets('Wir gehen essen: $choice durchläuft den Discovery- und Detailpfad', (tester) async {
      await verifyChoiceFlow(tester, mode: FoodMode.dineOut, choice: choice);
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
