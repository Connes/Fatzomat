import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delivery service logo failures fall back to a name and app links fall back to web', () {
    final source = File('lib/features/food_modes/delivery_services_page.dart').readAsStringSync();
    final bolt = source.substring(source.indexOf("name: 'Bolt'"), source.indexOf("name: 'Wolt'"));
    expect(bolt, contains("url: 'https://bolt.eu/de-de/food/'"));
    expect(bolt, contains("appUrl: 'boltfood://home'"));

    final open = source.substring(
      source.indexOf('Future<void> _openService'),
      source.indexOf('Future<void> _confirmAndCompleteOrder'),
    );
    expect(open, contains('catch (_)'));
    expect(open, contains('Uri.parse(service.url)'));
    expect(open, contains('konnte nicht geöffnet werden'));

    final card = source.substring(
      source.indexOf('class _DeliveryServiceCard'),
      source.indexOf('class _DeliveryService {'),
    );
    expect(card, contains('SvgPicture.network'));
    expect(card, contains('errorBuilder:'));
    expect(card, contains('service.name'));
  });
}
