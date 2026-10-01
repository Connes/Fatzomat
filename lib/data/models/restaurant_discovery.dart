class RestaurantDiscoveryResult {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String? phone;
  final Uri? website;
  final Uri? orderUri;
  final String? openingHours;
  final bool deliveryAvailable;
  final String deliveryStatus;
  final String? cuisine;

  const RestaurantDiscoveryResult({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.phone,
    this.website,
    this.orderUri,
    this.openingHours,
    this.deliveryAvailable = false,
    this.deliveryStatus = 'unknown',
    this.cuisine,
  });

  factory RestaurantDiscoveryResult.fromMap(Map<String, dynamic> map) {
    Uri? parseUri(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      final uri = Uri.tryParse(text);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') ? uri : null;
    }

    return RestaurantDiscoveryResult(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unbenannter Anbieter',
      address: _nullable(map['address']),
      city: _nullable(map['city']),
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      phone: _nullable(map['phone']),
      website: parseUri(map['website']),
      orderUri: parseUri(map['order_url']),
      openingHours: _nullable(map['opening_hours']),
      deliveryAvailable: map['delivery_available'] == true,
      deliveryStatus: switch (map['delivery_status']?.toString()) {
        'verified' => 'verified',
        'not_available' => 'not_available',
        _ => 'unknown',
      },
      cuisine: _nullable(map['cuisine']),
    );
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  bool get deliveryVerified => deliveryStatus == 'verified';
  bool get deliveryUnknown => deliveryStatus == 'unknown';

  String get locationLabel {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null && city != address) parts.add(city!);
    return parts.join(', ');
  }

  String get formattedDistance {
    if (distanceKm < 10) return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
    return '${distanceKm.toStringAsFixed(0)} km';
  }
}
