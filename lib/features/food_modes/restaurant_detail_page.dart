import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/restaurant_discovery.dart';

class RestaurantDetailPage extends StatelessWidget {
  final RestaurantDiscoveryResult result;
  final bool order;
  final VoidCallback? onSelect;

  const RestaurantDetailPage({
    super.key,
    required this.result,
    required this.order,
    this.onSelect,
  });

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Link konnte nicht geöffnet werden.')),
      );
    }
  }

  Future<void> _call(BuildContext context, String phone) async {
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Telefon-App konnte nicht geöffnet werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(title: Text(result.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(order ? Icons.delivery_dining_rounded : Icons.restaurant_rounded, size: 44),
                  const SizedBox(height: 12),
                  Text(result.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (result.locationLabel.isNotEmpty) Text(result.locationLabel),
                  Text(result.formattedDistance),
                  if (order && result.deliveryVerified) ...[
                    const SizedBox(height: 8),
                    const Chip(avatar: Icon(Icons.check_rounded, size: 18), label: Text('Lieferung verfügbar')),
                  ] else if (order && result.deliveryUnknown) ...[
                    const SizedBox(height: 8),
                    const Chip(avatar: Icon(Icons.help_outline_rounded, size: 18), label: Text('Lieferung nicht verifiziert')),
                  ],
                ],
              ),
            ),
          ),
          if (onSelect != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(order ? 'Für heute auswählen' : 'Für heute auswählen'),
            ),
          ],
          const SizedBox(height: 12),
          if (result.phone != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone_rounded),
                title: const Text('Telefon'),
                subtitle: Text(result.phone!),
                trailing: const Icon(Icons.call_rounded),
                onTap: () => _call(context, result.phone!),
              ),
            ),
          if (result.website != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Webseite'),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _open(context, result.website!),
              ),
            ),
          if (order && result.orderUri != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag_rounded),
                title: const Text('Bestellen / Lieferung'),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _open(context, result.orderUri!),
              ),
            ),
          if (result.openingHours != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Öffnungszeiten'),
                subtitle: Text(result.openingHours!),
              ),
            ),
          if (result.phone == null && result.website == null && (!order || result.orderUri == null))
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Keine Kontaktdaten verfügbar'),
                subtitle: Text('Die externe Datenquelle liefert für diesen Anbieter derzeit keine Telefonnummer oder Webseite.'),
              ),
            ),
        ],
      ),
    );
  }
}

