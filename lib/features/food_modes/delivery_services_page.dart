import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../core/recipe_collection_events.dart';
import '../../data/repositories/personal_today_repository.dart';

class DeliveryServicesPage extends StatelessWidget {
  final String planId;

  const DeliveryServicesPage({super.key, required this.planId});

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
    if (service.appUrl != null) {
      final appOpened = await launchUrl(Uri.parse(service.appUrl!), mode: LaunchMode.externalApplication);
      if (appOpened) return;
    }
    final webOpened = await launchUrl(Uri.parse(service.url), mode: LaunchMode.externalApplication);
    if (webOpened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.name} konnte nicht geöffnet werden.')),
    );
  }

  Future<void> _completeOrder(BuildContext context) async {
    try {
      final completed = await PersonalTodayRepository().updateStatus(planId, 'cooked');
      if (!completed) throw StateError('Die Bestellung konnte nicht abgeschlossen werden.');
      RecipeCollectionEvents.notifyChanged();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bestellung konnte nicht abgeschlossen werden: $error')),
      );
    }
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _completeOrder(context),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Bestellung abgeschlossen'),
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

  const _DeliveryService({
    required this.name,
    required this.url,
    required this.logoUrl,
    required this.brandColor,
    this.logoIsSvg = false,
    this.appUrl,
  });
}
