import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/restaurant_discovery.dart';
import '../../core/services/location_service.dart';

class RestaurantDiscoveryException implements Exception {
  final String message;
  const RestaurantDiscoveryException(this.message);
  @override
  String toString() => message;
}

abstract class RestaurantDiscoveryRepository {
  Future<List<RestaurantDiscoveryResult>> search({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    int limit = 10,
    double radiusKm = 10,
  });
}

class SupabaseRestaurantDiscoveryRepository implements RestaurantDiscoveryRepository {
  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  const SupabaseRestaurantDiscoveryRepository({SupabaseClient? client}) : _client = client;

  @override
  Future<List<RestaurantDiscoveryResult>> search({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    int limit = 10,
    double radiusKm = 10,
  }) async {
    if (client.auth.currentUser == null) {
      throw const RestaurantDiscoveryException('Keine persönliche Sitzung verfügbar.');
    }
    if (radiusKm != 10) {
      throw const RestaurantDiscoveryException('Die Restaurantsuche unterstützt derzeit ausschließlich den 10-km-Radius.');
    }

    try {
      // The restaurant Edge Function validates the access token server-side.
      // A location permission flow can resume the app with an access token that
      // is already expired, so refresh the Supabase session before invoking
      // the function. This avoids a false "persönliche Sitzung ist nicht
      // gültig" error even though the local session object still exists.
      await client.auth.refreshSession();
      final session = client.auth.currentSession;
      final accessToken = session?.accessToken;
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const RestaurantDiscoveryException('Die persönliche Sitzung ist abgelaufen. Bitte starte Schmackofatz neu.');
      }

      // Pass the freshly refreshed user JWT explicitly. supabase_flutter normally
      // adds it for functions.invoke(), but doing this here removes an auth-token
      // race after Android location permission/resume flows. The Edge Function
      // uses withSupabase({ auth: 'user' }) and therefore expects the JWT in
      // Authorization, not the publishable API key.
      final response = await client.functions.invoke(
        'restaurant-discovery',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
        body: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'cuisine': cuisine,
          'delivery_only': deliveryOnly,
          'limit': limit.clamp(1, 10),
          'radius_km': 10,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw const RestaurantDiscoveryException('Die Restaurantsuche hat eine ungültige Antwort geliefert.');
      }
      final error = data['error']?.toString().trim();
      if (error != null && error.isNotEmpty) {
        throw RestaurantDiscoveryException(error);
      }
      final results = data['results'];
      if (results is! List) {
        throw const RestaurantDiscoveryException('Die Restaurantsuche konnte keine Ergebnisliste liefern.');
      }
      return results
          .whereType<Map>()
          .map((row) => RestaurantDiscoveryResult.fromMap(Map<String, dynamic>.from(row)))
          .where((item) => item.name.trim().isNotEmpty && item.distanceKm <= 10.0001)
          .take(10)
          .toList(growable: false);
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw RestaurantDiscoveryException(details['error'].toString());
      }
      throw RestaurantDiscoveryException(e.reasonPhrase ?? 'Die Restaurantsuche ist gerade nicht verfügbar.');
    } on RestaurantDiscoveryException {
      rethrow;
    } catch (_) {
      throw const RestaurantDiscoveryException('Die Restaurantsuche ist gerade nicht verfügbar. Prüfe deine Internetverbindung und versuche es erneut.');
    }
  }
}
