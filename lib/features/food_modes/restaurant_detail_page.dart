import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/restaurant_discovery.dart';

class RestaurantDetailPage extends StatelessWidget {
  final RestaurantDiscoveryResult result;
  final bool order;
  final VoidCallback? onSelect;
  final VoidCallback? onComplete;

  const RestaurantDetailPage({
    super.key,
    required this.result,
    required this.order,
    this.onSelect,
    this.onComplete,
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
    const dayNames = <String, String>{
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

  Widget _contactSection({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(icon, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: onTap == null ? Colors.blueGrey : null,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: trailing,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressParts = <String>[
      if (result.address?.trim().isNotEmpty == true) result.address!.trim(),
      if (result.postalCode != null || result.city != null)
        [result.postalCode, result.city]
            .whereType<String>()
            .where((part) => part.trim().isNotEmpty)
            .join(' '),
    ].where((part) => part.isNotEmpty).toList();
    final address = addressParts.isEmpty ? 'Nicht verfügbar' : addressParts.join('\n');
    final addressWithDistance = result.formattedDistance.isEmpty
        ? address
        : '$address\n${result.formattedDistance}';
    final phone = result.phone?.trim().isNotEmpty == true
        ? result.phone!.trim()
        : 'Nicht verfügbar';
    final website = result.website == null ? 'Nicht verfügbar' : result.website!.host;
    final openingHours = result.openingHours?.trim().isNotEmpty == true
        ? _formatOpeningHours(result.openingHours!.trim())
        : 'Nicht verfügbar';

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(title: Text(result.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  _contactSection(
                    icon: Icons.location_on_rounded,
                    title: 'Anschrift',
                    value: addressWithDistance,
                  ),
                  const Divider(height: 1),
                  _contactSection(
                    icon: Icons.phone_rounded,
                    title: 'Telefon',
                    value: phone,
                    onTap: result.phone?.trim().isNotEmpty == true
                        ? () => _call(context, result.phone!.trim())
                        : null,
                    trailing: result.phone?.trim().isNotEmpty == true
                        ? const Icon(Icons.call_rounded, color: Colors.blueGrey)
                        : null,
                  ),
                  const Divider(height: 1),
                  _contactSection(
                    icon: Icons.language_rounded,
                    title: 'Webseite',
                    value: website,
                    onTap: result.website == null
                        ? null
                        : () => _open(context, result.website!),
                    trailing: result.website == null
                        ? null
                        : const Icon(Icons.open_in_new_rounded, color: Colors.blueGrey),
                  ),
                  const Divider(height: 1),
                  _contactSection(
                    icon: Icons.schedule_rounded,
                    title: 'Öffnungszeiten',
                    value: openingHours,
                  ),
                  if (order && result.orderUri != null) ...[
                    const Divider(height: 1),
                    _contactSection(
                      icon: Icons.shopping_bag_rounded,
                      title: 'Bestellen / Lieferung',
                      value: result.orderUri!.host,
                      onTap: () => _open(context, result.orderUri!),
                      trailing: const Icon(Icons.open_in_new_rounded, color: Colors.blueGrey),
                    ),
                  ],
                  if (order && result.deliveryAvailable) ...[
                    const Divider(height: 1),
                    _contactSection(
                      icon: Icons.check_circle_rounded,
                      title: 'Lieferung',
                      value: 'Laut Datenquelle verfügbar',
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onComplete != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Entscheidung abschließen'),
            ),
          ] else if (onSelect != null) ...[
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
