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
      throw const RestaurantDiscoveryException(
        'Die Restaurantsuche unterstützt derzeit ausschließlich den 10-km-Radius.',
      );
    }

    try {
      await client.auth.refreshSession();

      final response = await client.rpc(
        'search_restaurants',
        params: {
          'p_lat': location.latitude,
          'p_lon': location.longitude,
          'p_cuisine': cuisine,
          'p_delivery_only': deliveryOnly,
          'p_limit': limit.clamp(1, 10).toInt(),
          'p_radius_km': 10,
        },
      );

      if (response is! List) {
        throw const RestaurantDiscoveryException(
          'Die Restaurantsuche hat eine ungültige Antwort geliefert.',
        );
      }

      return response
          .whereType<Map>()
          .map((row) => RestaurantDiscoveryResult.fromMap(
                Map<String, dynamic>.from(row),
              ))
          .where((item) =>
              item.name.trim().isNotEmpty && item.distanceKm <= 10.0001)
          .take(10)
          .toList(growable: false);
    } on RestaurantDiscoveryException {
      rethrow;
    } catch (_) {
      throw const RestaurantDiscoveryException(
        'Die Restaurantsuche ist gerade nicht verfügbar. Prüfe deine Internetverbindung und versuche es erneut.',
      );
    }
  }
}
