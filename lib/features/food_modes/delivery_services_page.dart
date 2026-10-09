import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../core/services/location_service.dart';

class DeliveryServicesPage extends StatelessWidget {
  final String? orderQuery;

  const DeliveryServicesPage({super.key, this.orderQuery});

  static const _services = <_DeliveryService>[
    _DeliveryService(
      name: 'Lieferando',
      url: 'https://www.lieferando.de/',
      logoUrl:
          'https://presse.m2maydell.com/Content/580072/784fb4b0-d671-4862-9ec2-3a603800ed14/1200/2400/.jpg',
      brandColor: Color(0xFFFF8000),
    ),
    _DeliveryService(
      name: 'Uber Eats',
      url: 'https://www.ubereats.com/de/',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/b/b3/Uber_Eats_2020_logo.svg',
      brandColor: Color(0xFF06C167),
      logoIsSvg: true,
      appUrl: 'ubereats://home',
    ),
    _DeliveryService(
      name: 'Bolt',
      url: 'https://bolt.eu/de-de/food/',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/28/Vector_logo_of_Bolt.svg',
      brandColor: Color(0xFF34D186),
      logoIsSvg: true,
      appUrl: 'boltfood://home',
    ),
    _DeliveryService(
      name: 'Wolt',
      url: 'https://wolt.com/de/deu',
      logoUrl: 'https://d21buns5ku92am.cloudfront.net/69297/logo/retina-1665002030.png',
      brandColor: Color(0xFF00C2E8),
      appUrl: 'https://wolt.com/de/deu',
    ),
  ];

  Future<void> _openService(BuildContext context, _DeliveryService service) async {
    final query = orderQuery?.trim();
    if (query != null && query.isNotEmpty) {
      var searchUrl = service.searchUrl(query);
      if (service.name == 'Lieferando') {
        final postalCode = await _currentPostalCode();
        if (postalCode != null) {
          searchUrl = deliveryServiceSearchUrl(
            service.name,
            query,
            postalCode: postalCode,
            fallbackUrl: service.url,
          );
        }
      }
      final opened = await launchUrl(
        Uri.parse(searchUrl),
        mode: LaunchMode.externalApplication,
      );
      if (opened || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${service.name} konnte nicht geöffnet werden.')),
      );
      return;
    }

    if (service.appUrl != null) {
      final appOpened = await launchUrl(
        Uri.parse(service.appUrl!),
        mode: LaunchMode.externalApplication,
      );
      if (appOpened) return;
    }

    final webOpened = await launchUrl(
      Uri.parse(service.url),
      mode: LaunchMode.externalApplication,
    );
    if (webOpened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.name} konnte nicht geöffnet werden.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: const TogetherAppBar(title: Text('Lieferdienste')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            AppSurface(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              color: AppDesign.surface.withValues(alpha: 0.96),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ..._services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeliveryServiceCard(
                        service: service,
                        onTap: () => _openService(context, service),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryServiceCard extends StatelessWidget {
  final _DeliveryService service;
  final VoidCallback onTap;

  const _DeliveryServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: service.brandColor,
      borderRadius: BorderRadius.circular(AppDesign.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusXl),
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDesign.radiusXl),
            border: Border.all(color: service.brandColor.withValues(alpha: 0.55), width: 2),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 3),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: service.logoIsSvg
                        ? SvgPicture.network(
                            service.logoUrl,
                            height: 42,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => const SizedBox(
                              height: 42,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          )
                        : Image.network(
                            service.logoUrl,
                            height: 42,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(
                              service.name,
                              style: const TextStyle(
                                color: AppDesign.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_new_rounded, color: AppDesign.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryService {
  final String name;
  final String url;
  final String logoUrl;
  final Color brandColor;
  final bool logoIsSvg;
  final String? appUrl;

  String searchUrl(String query) => deliveryServiceSearchUrl(name, query, fallbackUrl: url);

  const _DeliveryService({
    required this.name,
    required this.url,
    required this.logoUrl,
    required this.brandColor,
    this.logoIsSvg = false,
    this.appUrl,
  });
}

Future<String?> _currentPostalCode() async {
  try {
    final location = await const DeviceLocationService().currentLocation();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
      });
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.userAgentHeader, 'Fatzomat/1.0 (delivery location lookup)');
      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 5));
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final address = decoded['address'];
      if (address is! Map) return null;
      final postalCode = address['postcode']?.toString().trim();
      return postalCode != null && RegExp(r'^\d{5}$').hasMatch(postalCode)
          ? postalCode
          : null;
    } finally {
      client.close(force: true);
    }
  } catch (_) {
    // Location lookup is best-effort; category search still works without it.
    return null;
  }
}

/// Builds the category/search destination opened by a delivery-service card.
/// A postcode lets Lieferando open its location-scoped category results.
String deliveryServiceSearchUrl(
  String serviceName,
  String query, {
  String? postalCode,
  String fallbackUrl = '',
}) {
  final normalizedQuery = query.trim().toLowerCase();
  switch (serviceName) {
    case 'Lieferando':
      if (postalCode != null &&
          RegExp(r'^\d{5}$').hasMatch(postalCode) &&
          normalizedQuery == 'pizza') {
        return Uri.https('www.lieferando.de', '/lieferservice/pizza/$postalCode').toString();
      }
      if (normalizedQuery == 'pizza') {
        return 'https://www.lieferando.de/pizza-bestellen';
      }
      return Uri.https('www.lieferando.de', '/suche', {'q': query.trim()}).toString();
    case 'Uber Eats':
      return Uri.https('www.ubereats.com', '/de/search', {
        'q': query.trim(),
        'searchType': 'GLOBAL_SEARCH',
      }).toString();
    case 'Wolt':
      return Uri.https('wolt.com', '/de/deu/search', {'q': query.trim()}).toString();
    case 'Bolt':
      return Uri.https('food.bolt.eu', '/search', {'query': query.trim()}).toString();
    default:
      return fallbackUrl;
  }
}
