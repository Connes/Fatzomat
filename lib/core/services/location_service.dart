import 'dart:async';

import 'package:flutter/services.dart';

class UserLocation {
  final double latitude;
  final double longitude;

  const UserLocation({required this.latitude, required this.longitude});
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => message;
}

abstract class LocationService {
  Future<UserLocation> currentLocation();
}

/// Uses the platform's native location APIs so Schmackofatz does not need a
/// second Flutter location stack. Android uses LocationManager, iOS uses
/// CLLocationManager. No location is persisted by this service.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  static const MethodChannel _channel = MethodChannel('schmackofatz/location');

  @override
  Future<UserLocation> currentLocation() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation').timeout(
        const Duration(seconds: 15),
      );
      if (result == null) {
        throw const LocationException('Der aktuelle Standort konnte nicht ermittelt werden.');
      }
      final latitude = (result['latitude'] as num?)?.toDouble();
      final longitude = (result['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null || !latitude.isFinite || !longitude.isFinite) {
        throw const LocationException('Der aktuelle Standort konnte nicht ermittelt werden.');
      }
      return UserLocation(latitude: latitude, longitude: longitude);
    } on TimeoutException {
      throw const LocationException('Der aktuelle Standort konnte nicht rechtzeitig ermittelt werden. Bitte versuche es erneut.');
    } on PlatformException catch (e) {
      throw LocationException(e.message?.trim().isNotEmpty == true ? e.message! : 'Der Standort konnte nicht ermittelt werden.');
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException('Die Standortbestimmung ist auf diesem Gerät nicht verfügbar.');
    }
  }
}
