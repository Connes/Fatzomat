import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import '../../core/app_design.dart';

import 'cook_next_step_page.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../core/services/food_choice_asset_service.dart';
import '../../core/food_mode.dart';
import '../../core/error_text.dart';
import '../../core/services/location_service.dart';
import '../../data/models/restaurant_discovery.dart';
import 'restaurant_detail_page.dart';
import '../../data/repositories/restaurant_discovery_repository.dart';

class FoodModePage extends StatefulWidget {
  final FoodMode mode;
  final DateTime? planDate;
  final String? decisionRequestId;
  final LocationService locationService;
  final RestaurantDiscoveryRepository discoveryRepository;
  final Future<void> Function(RestaurantDiscoveryResult result)? onResultSelected;

  const FoodModePage({
    super.key,
    required this.mode,
    this.planDate,
    this.decisionRequestId,
    this.locationService = const DeviceLocationService(),
    this.discoveryRepository = const SupabaseRestaurantDiscoveryRepository(),
    this.onResultSelected,
  });

  @override
  State<FoodModePage> createState() => _FoodModePageState();
}

class _FoodModePageState extends State<FoodModePage> {
  String get title => switch (widget.mode) {
        FoodMode.cook => 'Was wollen wir kochen?',
        FoodMode.order => 'Was wollen wir bestellen?',
        FoodMode.dineOut => 'Worauf haben wir Lust?',
      };

  Future<void> _openCook(BuildContext context, String choice) async {
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CookNextStepPage(
          mainChoice: choice,
          decisionRequestId: widget.decisionRequestId,
          planDate: widget.planDate,
        ),
      ),
    );
    if (selected == true && context.mounted) Navigator.pop(context, true);
  }

  Future<void> _resolveAndOpen(BuildContext context, String choice) async {
    // For cooking, the actual decision result is the saved recipe. Do not
    // resolve the request prematurely with only the main ingredient choice.
    if (widget.mode == FoodMode.cook) {
      await _openCook(context, choice);
      return;
    }

    // "Wir bestellen" is itself the decision. A category such as Pizza or
    // Burger is the complete result for today. There is deliberately no
    // restaurant discovery, location lookup or delivery-service detour here.
    if (widget.mode == FoodMode.order) {
      try {
        if (widget.decisionRequestId != null) {
          await CollaborationRepository().resolveDecisionRequest(
            requestId: widget.decisionRequestId!,
            decisionMode: widget.mode.name,
            resultType: 'order',
            resultId: choice,
          );
        } else {
          await PersonalTodayRepository().selectDecision(
            type: 'order',
            value: choice,
            date: widget.planDate,
          );
        }
        if (!context.mounted) return;
        Navigator.pop(context, true);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(error))),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DiscoveryPage(
          mode: widget.mode,
          preference: choice,
          decisionRequestId: widget.decisionRequestId,
          persistPersonalDecision: widget.decisionRequestId == null,
          locationService: widget.locationService,
          discoveryRepository: widget.discoveryRepository,
          onResultSelected: widget.onResultSelected,
        ),
      ),
    );
    if (selected == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  void _select(BuildContext context, String choice) {
    _resolveAndOpen(context, choice);
  }

  Widget _choiceGrid(List<_ModeOption> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return _OptionCard(
          mode: widget.mode,
          option: option,
          onTap: () => _select(context, option.label),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = switch (widget.mode) {
      FoodMode.cook => const [
          _ModeOption('Rind'),
          _ModeOption('Schwein'),
          _ModeOption('Huhn'),
          _ModeOption('Fisch'),
          _ModeOption('Vegetarisch'),
        ],
      FoodMode.order => const [
          _ModeOption('Pizza'),
          _ModeOption('Burger'),
          _ModeOption('Asiatisch'),
          _ModeOption('Döner'),
          _ModeOption('Sushi'),
          _ModeOption('Indisch'),
          _ModeOption('Schnitzel'),
          _ModeOption('Pasta'),
        ],
      FoodMode.dineOut => const [
          _ModeOption('Italienisch'),
          _ModeOption('Griechisch'),
          _ModeOption('Türkisch'),
          _ModeOption('Japanisch'),
          _ModeOption('Chinesisch'),
          _ModeOption('Thailändisch'),
          _ModeOption('Vietnamesisch'),
          _ModeOption('Koreanisch'),
          _ModeOption('Indonesisch'),
          _ModeOption('Malaysisch'),
          _ModeOption('Sushi'),
          _ModeOption('Burger'),
          _ModeOption('Steak'),
          _ModeOption('Mexikanisch'),
          _ModeOption('Spanisch'),
          _ModeOption('Libanesisch'),
          _ModeOption('Portugiesisch'),
          _ModeOption('Vegetarisch'),
          _ModeOption('Vegan'),
        ],
    };

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(
        title: Text(switch (widget.mode) {
          FoodMode.cook => 'Wir kochen',
          FoodMode.order => 'Wir bestellen',
          FoodMode.dineOut => 'Wir gehen essen',
        }),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactMode = widget.mode == FoodMode.cook || widget.mode == FoodMode.order;
            if (!compactMode) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AppSurface(
                  key: const ValueKey<String>('food_mode_choice_group'),
                  padding: const EdgeInsets.all(10),
                  color: AppDesign.surface.withValues(alpha: 0.96),
                  child: _choiceGrid(options),
                ),
              );
            }

            final rows = (options.length + 1) ~/ 2;
            const gap = 10.0;
            const verticalPadding = 16.0;
            final gridGaps = (rows - 1) * gap;
            final reserved = verticalPadding + gridGaps;
            final cardHeight = (constraints.maxHeight - reserved) / rows;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            final aspectRatio = cardWidth / cardHeight;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  SizedBox(
                    height: cardHeight * rows + gridGaps,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: gap,
                        crossAxisSpacing: gap,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return _OptionCard(
                          mode: widget.mode,
                          option: option,
                          onTap: () => _select(context, option.label),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
class _ModeOption {
  final String label;
  const _ModeOption(this.label);
}

class _OptionCard extends StatelessWidget {
  final FoodMode mode;
  final _ModeOption option;
  final VoidCallback onTap;

  const _OptionCard({
    required this.mode,
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = FoodChoiceAssetService.assetFor(mode, option.label);
    final icon = FoodChoiceAssetService.iconFor(mode, option.label);
    Widget image() {
      if (assetPath == null) {
        return ColoredBox(
          color: AppDesign.softSurface,
          child: Center(
            child: Icon(
              icon ?? Icons.restaurant_rounded,
              size: 58,
              color: AppDesign.mutedText,
            ),
          ),
        );
      }

      final image = Image.asset(
        assetPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
        width: double.infinity,
        height: double.infinity,
      );

      return image;
    }

    return Semantics(
      container: true,
      button: true,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppDesign.softSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppDesign.divider),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  offset: Offset(0, 4),
                  color: Color(0x16000000),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17),
                      ),
                      child: ColoredBox(
                        color: AppDesign.softSurface,
                        child: image(),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F5EF),
                    ),
                    child: Text(
                      option.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppDesign.text,
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DiscoveryPage extends StatefulWidget {
  final FoodMode mode;
  final String preference;
  final bool surprised;
  final String? decisionRequestId;
  final bool persistPersonalDecision;
  final DateTime? planDate;
  final LocationService locationService;
  final RestaurantDiscoveryRepository discoveryRepository;
  final Future<void> Function(RestaurantDiscoveryResult result)? onResultSelected;

  const DiscoveryPage({
    super.key,
    required this.mode,
    required this.preference,
    this.surprised = false,
    this.decisionRequestId,
    this.persistPersonalDecision = false,
    this.planDate,
    this.locationService = const DeviceLocationService(),
    this.discoveryRepository = const SupabaseRestaurantDiscoveryRepository(),
    this.onResultSelected,
  });

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  late Future<List<RestaurantDiscoveryResult>> _searchFuture;

  bool get order => widget.mode == FoodMode.order;

  @override
  void initState() {
    super.initState();
    _searchFuture = _search();
  }

  Future<List<RestaurantDiscoveryResult>> _search() async {
    final location = await widget.locationService.currentLocation();
    return widget.discoveryRepository.search(
      location: location,
      cuisine: widget.preference,
      deliveryOnly: order,
      radiusKm: 10,
      limit: 10,
    );
  }

  void _retry() {
    setState(() => _searchFuture = _search());
  }

  Future<void> _selectResult(RestaurantDiscoveryResult result) async {
    final decisionValue = order
        ? result.name
        : jsonEncode({
            'id': result.id,
            'name': result.name,
            'address': result.address,
            'city': result.city,
            'distance_km': result.distanceKm,
            'latitude': result.latitude,
            'longitude': result.longitude,
            'phone': result.phone,
            'website': result.website?.toString(),
            'order_url': result.orderUri?.toString(),
            'opening_hours': result.openingHours,
            'delivery_available': result.deliveryAvailable,
            'cuisine': widget.preference,
          });
    try {
      if (widget.onResultSelected != null) {
        await widget.onResultSelected!(result);
      } else if (widget.decisionRequestId != null) {
        await CollaborationRepository().resolveDecisionRequest(
          requestId: widget.decisionRequestId!,
          decisionMode: widget.mode.name,
          resultType: order ? 'order' : 'dine_out',
          resultId: decisionValue,
        );
      } else if (widget.persistPersonalDecision) {
        await PersonalTodayRepository().selectDecision(
          type: order ? 'order' : 'dine_out',
          value: decisionValue,
          date: widget.planDate,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    }
  }

  Future<void> _openDetails(RestaurantDiscoveryResult result) async {
    if (widget.decisionRequestId == null && !widget.persistPersonalDecision) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantDetailPage(
            result: result,
            order: order,
          ),
        ),
      );
      return;
    }

    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(
          result: result,
          order: order,
          onSelect: () => Navigator.pop(context, true),
        ),
      ),
    );
    if (selected == true && mounted) {
      await _selectResult(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(
        title: Text(order ? 'Wir bestellen' : 'Wir gehen essen'),
      ),
      body: FutureBuilder<List<RestaurantDiscoveryResult>>(
        future: _searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DiscoveryError(
              message: snapshot.error.toString().replaceFirst('RestaurantDiscoveryException: ', '').replaceFirst('LocationException: ', ''),
              onRetry: _retry,
            );
          }

          final results = snapshot.data ?? const <RestaurantDiscoveryResult>[];
          if (results.isEmpty) {
            return _DiscoveryEmpty(
              order: order,
              cuisine: widget.preference,
              onRetry: _retry,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Text(
                widget.preference,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              ...results.map(
                (result) => _RestaurantListCard(
                  result: result,
                  order: order,
                  onTap: () => _openDetails(result),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RestaurantListCard extends StatelessWidget {
  final RestaurantDiscoveryResult result;
  final bool order;
  final VoidCallback onTap;

  const _RestaurantListCard({required this.result, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.city != null) Text(result.city!),
              Text(result.formattedDistance),
              if (order && result.deliveryAvailable)
                const Text('Lieferung laut Datenquelle verfügbar'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DiscoveryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 52),
            const SizedBox(height: 16),
            const Text('Suche nicht möglich', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryEmpty extends StatelessWidget {
  final bool order;
  final String cuisine;
  final VoidCallback onRetry;

  const _DiscoveryEmpty({required this.order, required this.cuisine, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(order ? Icons.delivery_dining_rounded : Icons.restaurant_rounded, size: 52),
            const SizedBox(height: 16),
            Text('Keine passenden ${order ? 'Restaurants zum Bestellen' : 'Restaurants'} gefunden', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Für „$cuisine“ wurden innerhalb von 10 km keine passenden Einträge aus der aktuellen Datenquelle gefunden.', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Erneut suchen')),
          ],
        ),
      ),
    );
  }
}

