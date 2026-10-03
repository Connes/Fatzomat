import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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

  static DateTime? _lastNominatimRequest;

  Future<List<RestaurantDiscoveryResult>> _nominatimFallback({
    required UserLocation location,
    required String cuisine,
    required bool deliveryOnly,
    required int limit,
  }) async {
    final previous = _lastNominatimRequest;
    if (previous != null) {
      final wait = const Duration(seconds: 1) - DateTime.now().difference(previous);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastNominatimRequest = DateTime.now();

    final query = switch (cuisine) {
      'Pizza' => 'pizza restaurant',
      'Burger' => 'burger restaurant',
      'Asiatisch' => 'asian restaurant',
      'Döner' => 'kebab restaurant',
      'Sushi' => 'sushi restaurant',
      'Indisch' => 'indian restaurant',
      'Italienisch' => 'italian restaurant',
      'Griechisch' => 'greek restaurant',
      'Mexikanisch' => 'mexican restaurant',
      'Vegetarisch' => 'vegetarian restaurant',
      'Steak' => 'steak restaurant',
      _ => 'restaurant',
    };

    const radians = math.pi / 180.0;
    final latitudeDelta = 10 / 111.32;
    final longitudeDelta = 10 / (111.32 * math.max(math.cos(location.latitude * radians).abs(), 0.2));
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'extratags': '1',
      'limit': '40',
      'bounded': '1',
      'layer': 'poi',
      'viewbox': '${location.longitude + longitudeDelta},${location.latitude + latitudeDelta},${location.longitude - longitudeDelta},${location.latitude - latitudeDelta}',
      'accept-language': 'de',
    });

    final http = HttpClient();
    try {
      final request = await http.getUrl(uri).timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'Schmackofatz/1.13 (+https://github.com/Connes/Fatzomat)');
      final response = await request.close().timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(await response.transform(utf8.decoder).join());
      if (response.statusCode != 200 || decoded is! List) {
        throw const RestaurantDiscoveryException('Alternative Restaurantdatenquelle nicht verfügbar.');
      }

      final requested = switch (cuisine) {
        'Italienisch' => {'italian'},
        'Griechisch' => {'greek'},
        'Asiatisch' => {'asian', 'chinese', 'thai', 'vietnamese', 'korean', 'indonesian', 'malaysian'},
        'Indisch' => {'indian'},
        'Burger' => {'burger'},
        'Mexikanisch' => {'mexican'},
        'Vegetarisch' => {'vegetarian', 'vegan'},
        'Sushi' => {'sushi'},
        'Pizza' => {'pizza', 'italian_pizza'},
        'Döner' => {'kebab', 'doner', 'döner'},
        'Steak' => {'steak', 'steak_house'},
        _ => <String>{},
      }.map((value) => value.toLowerCase().replaceAll('ö', 'o')).toSet();

      final results = <RestaurantDiscoveryResult>[];
      final seen = <String>{};
      for (final raw in decoded) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final name = '${item['name'] ?? ''}'.trim();
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        if (name.isEmpty || lat == null || lon == null) continue;

        final dLat = (lat - location.latitude) * radians;
        final dLon = (lon - location.longitude) * radians;
        final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(location.latitude * radians) *
                math.cos(lat * radians) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);
        final distance = 6371 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
        if (distance > 10.0001) continue;

        final extra = item['extratags'] is Map
            ? Map<String, dynamic>.from(item['extratags'] as Map)
            : <String, dynamic>{};
        final cuisineTags = '${extra['cuisine'] ?? ''}'
            .toLowerCase()
            .split(';')
            .map((value) => value.trim().replaceAll('ö', 'o'))
            .where((value) => value.isNotEmpty)
            .toSet();
        if (cuisineTags.isNotEmpty && !cuisineTags.any(requested.contains)) continue;

        final address = item['address'] is Map
            ? Map<String, dynamic>.from(item['address'] as Map)
            : <String, dynamic>{};
        final street = '${address['road'] ?? ''}'.trim();
        final house = '${address['house_number'] ?? ''}'.trim();
        final city = '${address['city'] ?? address['town'] ?? address['village'] ?? ''}'.trim();
        final key = '${name.toLowerCase()}|${street.toLowerCase()}|${city.toLowerCase()}';
        if (!seen.add(key)) continue;

        final delivery = '${extra['delivery'] ?? ''}'.toLowerCase();
        if (deliveryOnly && delivery == 'no') continue;
        results.add(RestaurantDiscoveryResult.fromMap({
          'id': '${item['osm_type'] ?? 'N'}/${item['osm_id'] ?? ''}',
          'name': name,
          'address': [street, house].where((v) => v.isNotEmpty).join(' '),
          'city': city.isEmpty ? null : city,
          'distance_km': double.parse(distance.toStringAsFixed(2)),
          'latitude': lat,
          'longitude': lon,
          'phone': extra['phone'],
          'website': extra['website'],
          'order_url': extra['delivery:website'],
          'opening_hours': extra['opening_hours'],
          'delivery_available': delivery == 'yes',
          'delivery_status': delivery == 'yes' ? 'verified' : delivery == 'no' ? 'not_available' : 'unknown',
          'cuisine': extra['cuisine'],
        }));
      }
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return results.take(limit).toList(growable: false);
    } finally {
      http.close(force: true);
    }
  }


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
      if (e.status == 503) {
        try {
          final fallback = await _nominatimFallback(
            location: location,
            cuisine: cuisine,
            deliveryOnly: deliveryOnly,
            limit: limit.clamp(1, 10),
          );
          if (fallback.isNotEmpty) return fallback;
        } catch (_) {
          // Keep the stable repository error below.
        }
      }
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
