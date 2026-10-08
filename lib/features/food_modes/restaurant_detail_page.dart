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
    final opened = await launchUrl(
      Uri(scheme: 'tel', path: phone),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Telefon-App konnte nicht geöffnet werden.')),
      );
    }
  }

  String _formatOpeningHours(String value) {
    final dayNames = <String, String>{
      'Mo': 'Mo',
      'Tu': 'Di',
      'We': 'Mi',
      'Th': 'Do',
      'Fr': 'Fr',
      'Sa': 'Sa',
      'Su': 'So',
    };

    return value
        .split(';')
        .map((entry) {
          var formatted = entry.trim();
          for (final replacement in dayNames.entries) {
            formatted = formatted.replaceAll(
              RegExp(r'\b' + replacement.key + r'\b'),
              replacement.value,
            );
          }
          return formatted.replaceAll(',', ', ');
        })
        .where((entry) => entry.isNotEmpty)
        .join('\n');
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required Widget child,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon),
        title: Text(title),
        subtitle: child,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressParts = <String>[
      if (result.address != null) result.address!,
      if (result.postalCode != null || result.city != null)
        [result.postalCode, result.city].whereType<String>().join(' '),
    ].where((part) => part.isNotEmpty).toList();

    final hasAddress = addressParts.isNotEmpty;

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(title: Text(result.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          if (hasAddress)
            _infoCard(
              icon: Icons.location_on_rounded,
              title: 'Anschrift',
              child: Text([
                ...addressParts,
                result.formattedDistance,
              ].join('\n')),
            ),
          if (!hasAddress)
            _infoCard(
              icon: Icons.near_me_rounded,
              title: 'Entfernung',
              child: Text(result.formattedDistance),
            ),
          if (result.phone != null) ...[
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.phone_rounded,
              title: 'Telefon',
              child: Text(result.phone!),
              trailing: const Icon(Icons.call_rounded),
              onTap: () => _call(context, result.phone!),
            ),
          ],
          if (result.website != null) ...[
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.language_rounded,
              title: 'Webseite',
              child: Text(
                result.website!.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _open(context, result.website!),
            ),
          ],
          if (order && result.orderUri != null) ...[
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.shopping_bag_rounded,
              title: 'Bestellen / Lieferung',
              child: Text(
                result.orderUri!.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _open(context, result.orderUri!),
            ),
          ],
          if (result.openingHours != null) ...[
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.schedule_rounded,
              title: 'Öffnungszeiten',
              child: Text(_formatOpeningHours(result.openingHours!)),
            ),
          ],
          if (!hasAddress &&
              result.phone == null &&
              result.website == null &&
              result.openingHours == null &&
              (!order || result.orderUri == null))
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Keine Kontaktdaten verfügbar'),
                subtitle: Text(
                  'Die externe Datenquelle liefert für diesen Anbieter derzeit keine Kontaktdaten.',
                ),
              ),
            ),
          if (order && result.deliveryAvailable) ...[
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle_rounded),
                title: Text('Lieferung verfügbar'),
              ),
            ),
          ],
          if (onSelect != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Für heute auswählen'),
            ),
          ],
        ],
      ),
    );
  }
}
