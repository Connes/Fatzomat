import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/error_text.dart';
import '../../core/widgets/together_background.dart';

import '../../core/app_design.dart';
import '../../core/food_mode.dart';
import '../../core/services/surprise_recommendation_service.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/models/food.dart';
import '../../data/models/recipe.dart';
import '../../data/models/decision_request.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../food_modes/food_mode_page.dart';
import 'personalized_surprise_page.dart';

class DecisionRequestPage extends StatefulWidget {
  final DecisionRequest request;

  const DecisionRequestPage({super.key, required this.request});

  @override
  State<DecisionRequestPage> createState() => _DecisionRequestPageState();
}

class _DecisionRequestPageState extends State<DecisionRequestPage> with WidgetsBindingObserver {
  CollaborationRepository? _repo;
  late DecisionRequest currentRequest;
  bool working = false;
  bool loading = true;
  RealtimeChannel? _decisionRequestChannel;
  int _refreshGeneration = 0;

  CollaborationRepository get repo => _repo ??= CollaborationRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentRequest = widget.request;
    _refreshRequest();
    _subscribeDecisionRequest();
  }

  void _subscribeDecisionRequest() {
    try {
      final client = Supabase.instance.client;
      _decisionRequestChannel = client
          .channel('decision-request-${widget.request.id}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'decision_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.request.id,
          ),
          callback: (_) => _refreshRequest(),
        )
        ..subscribe();
    } on AssertionError {
      // Widget tests and offline previews may mount before Supabase exists.
    }
  }

  Future<void> _refreshRequest() async {
    final generation = ++_refreshGeneration;
    try {
      final fresh = await repo.decisionRequest(widget.request.id);
      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        if (fresh != null) currentRequest = fresh;
        loading = false;
      });
    } catch (_) {
      if (mounted && generation == _refreshGeneration) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshRequest();
    }
  }

  Future<bool> _accept() async {
    if (working) return false;
    setState(() => working = true);
    try {
      if (currentRequest.isAccepted) return true;
      await repo.acceptDecisionRequest(currentRequest.id);
      if (mounted) {
        setState(() {
          currentRequest = DecisionRequest.fromMap({
            'id': currentRequest.id,
            'connection_id': currentRequest.connectionId,
            'created_by': currentRequest.createdBy,
            'assigned_to': currentRequest.assignedTo,
            'status': 'accepted',
            'decision_mode': currentRequest.decisionMode,
            'result_type': currentRequest.resultType,
            'result_id': currentRequest.resultId,
            'created_at': currentRequest.createdAt.toIso8601String(),
            'resolved_at': currentRequest.resolvedAt?.toIso8601String(),
          });
        });
      }
      return true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      return false;
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _select(FoodMode mode) async {
    if (working) return;
    final accepted = await _accept();
    if (!accepted || !mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FoodModePage(mode: mode, decisionRequestId: currentRequest.id),
      ),
    );
  }

  Future<void> _surprise() async {
    if (working) return;
    final accepted = await _accept();
    if (!accepted || !mounted) return;
    try {
      final results = await Future.wait([
        FoodRepository().preferences(),
        FoodRepository().foods(),
        RecipeRepository().savedRecipeModels(),
      ]);
      final preferences = results[0] as Map<String, String>;
      final foods = results[1] as List<Food>;
      final saved = results[2] as List<Recipe>;
      final service = SurpriseRecommendationService();
      final recommendation = await service.generate(
        savedRecipes: saved,
        preferences: preferences,
        foods: foods,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalizedSurprisePage(
            recommendation: recommendation,
            decisionRequestId: currentRequest.id,
            service: service,
            savedRecipes: saved,
            preferences: preferences,
            foods: foods,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshGeneration++;
    if (_decisionRequestChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_decisionRequestChannel!);
      } on AssertionError {
        // Supabase may be unavailable in widget tests/offline previews.
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return TogetherScaffold(backgroundType: TogetherBackgroundType.decision, 
        appBar: TogetherAppBar(title: const Text('Du bist dran')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!currentRequest.isPending && !currentRequest.isAccepted) {
      final message = currentRequest.isCancelled
          ? 'Diese Entscheidungsanfrage wurde zurückgenommen.'
          : currentRequest.isResolved
              ? 'Diese Entscheidungsanfrage wurde bereits abgeschlossen.'
              : 'Diese Entscheidungsanfrage ist nicht mehr verfügbar.';
      return TogetherScaffold(backgroundType: TogetherBackgroundType.decision, 
        appBar: TogetherAppBar(title: const Text('Du bist dran')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 64),
                const SizedBox(height: 18),
                Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 18),
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
              ],
            ),
          ),
        ),
      );
    }

    return TogetherScaffold(backgroundType: TogetherBackgroundType.decision, 
      appBar: TogetherAppBar(title: const Text('Du bist dran')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(child: Icon(Icons.send_rounded, size: 64, color: AppDesign.primary)),
            const SizedBox(height: 20),
            Text('Du entscheidest heute.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('Entscheide, was ihr heute esst. Die andere Person wartet auf deine Wahl.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth >= 600 ? 16.0 : 12.0;
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  childAspectRatio: 540 / 480,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _DecisionAssetCard(
                      asset: 'assets/together/clean/icons/icon_cooking.png',
                      label: 'Wir kochen',
                      onTap: working ? null : () => _select(FoodMode.cook),
                    ),
                    _DecisionAssetCard(
                      asset: 'assets/together/clean/icons/icon_delivery.png',
                      label: 'Wir bestellen',
                      onTap: working ? null : () => _select(FoodMode.order),
                    ),
                    _DecisionAssetCard(
                      asset: 'assets/together/clean/icons/icon_restaurant.png',
                      label: 'Wir gehen essen',
                      onTap: working ? null : () => _select(FoodMode.dineOut),
                    ),
                    _DecisionAssetCard(
                      asset: 'assets/together/clean/icons/icon_surprise.png',
                      label: 'Überrasch mich',
                      onTap: working ? null : _surprise,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionAssetCard extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback? onTap;

  const _DecisionAssetCard({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: ExcludeSemantics(
            child: Image.asset(
              asset,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
