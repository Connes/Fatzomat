import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';

class DeliveryServicesPage extends StatelessWidget {
  const DeliveryServicesPage({super.key});

  static const _services = <_DeliveryService>[
    _DeliveryService(name: 'Lieferando', url: 'https://www.lieferando.de/', icon: Icons.delivery_dining_rounded),
    _DeliveryService(name: 'Uber Eats', url: 'https://www.ubereats.com/de/', icon: Icons.local_shipping_outlined),
    _DeliveryService(name: 'Bolt', url: 'https://bolt.eu/de-de/food/', icon: Icons.two_wheeler_rounded),
  ];

  Future<void> _openService(BuildContext context, _DeliveryService service) async {
    final opened = await launchUrl(Uri.parse(service.url), mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
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
                  Text(
                    'Lieferdienst auswählen',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Öffne direkt die Webseite deines gewünschten Lieferdienstes.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDesign.secondaryText),
                  ),
                  const SizedBox(height: 20),
                  ..._services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DeliveryServiceCard(service: service, onTap: () => _openService(context, service)),
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
      color: AppDesign.softSurface,
      borderRadius: BorderRadius.circular(AppDesign.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusXl),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDesign.radiusXl),
            border: Border.all(color: AppDesign.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppDesign.primarySoft, borderRadius: BorderRadius.circular(16)),
                child: Icon(service.icon, color: AppDesign.primaryDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(color: AppDesign.text, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.open_in_new_rounded),
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
  final IconData icon;

  const _DeliveryService({required this.name, required this.url, required this.icon});
}
