import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/async_error.dart';
import '../../core/error_text.dart';
import '../../core/app_design.dart';
import '../../core/recipe_collection_events.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/today_plan.dart';
import '../../data/models/restaurant_discovery.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/collaboration_repository.dart';
import 'controllers/today_controller.dart';
import '../recipes/recipe_detail_page.dart';
import '../../core/food_mode.dart';
import '../../core/services/food_choice_asset_service.dart';
import '../food_modes/food_mode_page.dart';
import '../food_modes/restaurant_detail_page.dart';
import '../food_modes/delivery_services_page.dart';
import 'personalized_surprise_page.dart';
import 'connection_page.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/models/food.dart';
import '../../data/models/decision_share.dart';
import '../../core/services/surprise_recommendation_service.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final repo = PersonalTodayRepository();
  final recipeRepo = RecipeRepository();
  late final TodayController controller;
  TodayPlan? plan;
  DateTime _selectedDate = DateTime.now();
  List<TodayPlan> completedPlans = const [];
  bool loading = true;
  Object? loadError;
  RealtimeChannel? channel;
  CollaborationRepository? _collaboration;
  bool _loadingDecisionMessage = false;
  DecisionShare? _pendingDecisionShare;
  bool _decisionShareActionInFlight = false;

  CollaborationRepository get _collaborationRepository =>
      _collaboration ??= CollaborationRepository();

  @override
  void initState() {
    super.initState();
    controller = TodayController();
    load();
    RecipeCollectionEvents.revision.addListener(_onRecipeCollectionChanged);
    _subscribeRealtime();
  }

  void _onRecipeCollectionChanged() {
    if (mounted) load();
  }

  void _subscribeRealtime() {
    try {
      final client = Supabase.instance.client;
      channel = client.channel('today-plan');
      channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'personal_today_plans',
        callback: (_) {
          if (mounted) load();
        },
      ).subscribe();
    } on AssertionError {
      // Widget tests and offline previews can mount before Supabase exists.
    }
  }

  Future<void> load() async {
    await controller.load();
    final selectedPlan = await repo.todayPlan(date: _selectedDate);
    DecisionShare? pendingShare;
    List<TodayPlan> completed = const [];
    try {
      completed = await repo.completedTodayPlans();
    } catch (_) {
      // Completed history must not block the current decision card.
    }
    try {
      pendingShare = await _collaborationRepository.pendingDecisionShareForToday();
    } catch (_) {
      // A pending shared decision is additive UI. Never make Today unusable
      // because its optional collaboration lookup failed.
    }
    if (!mounted) return;
    setState(() {
      plan = selectedPlan;
      completedPlans = completed;
      loading = controller.loading;
      loadError = controller.error;
      _pendingDecisionShare = pendingShare;
    });
  }

  Future<void> _acceptPendingDecisionShare() async {
    final share = _pendingDecisionShare;
    if (share == null || _decisionShareActionInFlight) return;
    setState(() => _decisionShareActionInFlight = true);
    try {
      await _collaborationRepository.acceptDecisionShare(share.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geteilte Entscheidung übernommen.')),
      );
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _decisionShareActionInFlight = false);
    }
  }

  Future<void> _rejectPendingDecisionShare() async {
    final share = _pendingDecisionShare;
    if (share == null || _decisionShareActionInFlight) return;
    setState(() => _decisionShareActionInFlight = true);
    try {
      await _collaborationRepository.rejectDecisionShare(share.id);
      if (!mounted) return;
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _decisionShareActionInFlight = false);
    }
  }

  Future<void> _handleSurprise() async {
    await _openSurprise();
  }

  Future<void> _openSurprise() async {
    try {
      final results = await Future.wait([
        FoodRepository().preferences(),
        FoodRepository().foods(),
        recipeRepo.savedRecipeModels(),
      ]);
      if (!mounted) return;
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalizedSurprisePage(
            recommendation: recommendation,
            persistPersonalDecision: true,
            service: service,
            savedRecipes: saved,
            preferences: preferences,
            foods: foods,
          ),
        ),
      );
      if (mounted) await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Future<void> _openMode(FoodMode mode) async {
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FoodModePage(mode: mode)),
    );
    if (selected == true && mounted) await load();
  }

  Future<void> _askPartnerToDecide() async {
    if (_loadingDecisionMessage) return;
    setState(() => _loadingDecisionMessage = true);
    try {
      final connection = await _collaborationRepository.connectionInfo();
      if (!mounted) return;
      final connected = connection?.isConnected == true;
      if (!connected) {
        await _showNoConnectionDialog();
        return;
      }
      await _collaborationRepository.sendDecisionMessage(type: 'ask');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nachricht „Entscheide Du“ gesendet.')),
      );
    } catch (error) {
      if (!mounted) return;
      final errorText = error.toString().toLowerCase();
      if (errorText.contains('keine zweite person ist verbunden') ||
          errorText.contains('keine verbindung zu einer zweiten person')) {
        await _showNoConnectionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDecisionMessage = false);
    }
  }

  Future<void> _shareTodayDecision() async {
    if (_loadingDecisionMessage || plan == null || plan!.status == 'cooked') return;
    setState(() => _loadingDecisionMessage = true);
    try {
      final connection = await _collaborationRepository.connectionInfo();
      if (!mounted) return;
      final connected = connection?.isConnected == true;
      if (!connected) {
        await _showNoConnectionDialog();
        return;
      }
      await _collaborationRepository.sendDecisionMessage(
        type: 'share',
        decisionType: plan!.decisionType,
        decisionValue: plan!.decisionValue,
        decisionName: plan!.displayTitle,
        imageUrl: plan!.imageUrl,
        recipeId: plan!.recipeId,
        servings: plan!.servings,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deine Entscheidung wurde geteilt.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _loadingDecisionMessage = false);
    }
  }


  Future<void> _showNoConnectionDialog() async {
    final openConnection = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keine Verbindung vorhanden'),
        content: const Text(
          'Noch keine Connection vorhanden. Für „Entscheide Du“ brauchst du eine Verbindung zu einem anderen Schmackofatz-Benutzer. Du kannst jetzt eine Connection aufbauen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.link_rounded),
            label: const Text('Jetzt Connection aufbauen'),
          ),
        ],
      ),
    );
    if (openConnection != true || !mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ConnectionPage()),
    );
  }

  Future<void> removeTodayPlan() async {
    if (plan == null) return;
    if (plan!.status == 'cooked') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Für heute ist schon alles erledigt. Deine Entscheidung ist abgeschlossen.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Heutige Entscheidung entfernen?'),
        content: Text(
          '„${plan!.displayTitle}“ wird aus deinem heutigen Plan entfernt. Zugehörige persönliche Rezeptartikel verschwinden ebenfalls aus der Einkaufsliste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await repo.removeTodayPlan(plan!.id);
      // The Recipes tab also shows the current Today plan. Notify it directly
      // so the "Für dich heute" marker disappears immediately, even if the
      // Supabase Realtime event arrives later.
      RecipeCollectionEvents.notifyChanged();
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Heutige Entscheidung entfernt.')),
        );
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }


  @override
  void dispose() {
    RecipeCollectionEvents.revision.removeListener(_onRecipeCollectionChanged);
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel!);
      } on AssertionError {
        // Supabase may be unavailable in widget tests/offline previews.
      }
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    if (loading) {
      page = TogetherScaffold(
        backgroundType: TogetherBackgroundType.home,
        respectTopSafeArea: true,
        appBar: _todayAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    } else if (loadError != null) {
      page = TogetherScaffold(
        backgroundType: TogetherBackgroundType.home,
        respectTopSafeArea: true,
        appBar: _todayAppBar(),
        body: SafeArea(
          child: AppErrorView(error: loadError!, onRetry: load),
        ),
      );
    } else {
      page = TogetherScaffold(
        backgroundType: TogetherBackgroundType.home,
        respectTopSafeArea: true,
        appBar: _todayAppBar(),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: load,
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_pendingDecisionShare != null) ...[
                      _IncomingDecisionShareCard(
                        share: _pendingDecisionShare!,
                        busy: _decisionShareActionInFlight,
                        onAccept: _acceptPendingDecisionShare,
                        onReject: _rejectPendingDecisionShare,
                      ),
                      const SizedBox(height: 14),
                    ],
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity.abs() < 180) return;
                        setState(() {
                          _selectedDate = _selectedDate.add(Duration(days: velocity < 0 ? 1 : -1));
                          loading = true;
                        });
                        load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(tooltip: 'Vorheriger Tag', onPressed: () { setState(() { _selectedDate = _selectedDate.subtract(const Duration(days: 1)); loading = true; }); load(); }, icon: const Icon(Icons.chevron_left)),
                            Text(
                              _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day
                                  ? 'Heute'
                                  : '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(tooltip: 'Nächster Tag', onPressed: () { setState(() { _selectedDate = _selectedDate.add(const Duration(days: 1)); loading = true; }); load(); }, icon: const Icon(Icons.chevron_right)),
                          ],
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: plan == null
                          ? _TodayDecisionCard(
                              onCook: () => _openMode(FoodMode.cook),
                              onOrder: () => _openMode(FoodMode.order),
                              onDineOut: () => _openMode(FoodMode.dineOut),
                              onSurprise: _handleSurprise,
                              onDecide: _askPartnerToDecide,
                            )
                          : _TodayResultCard(
                              plan: plan!,
                              onCancel: removeTodayPlan,
                              onShare: plan!.status == 'cooked' || plan!.isShared ? null : _shareTodayDecision,
                              onOpenOrder: plan!.decisionType == 'order' && plan!.status != 'cooked'
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DeliveryServicesPage(
                                            planId: plan!.id,
                                          ),
                                        ),
                                      );
                                    }
                                  : plan!.decisionType == 'dine_out'
                                      ? () {
                                          final data = plan!.restaurantData;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RestaurantDetailPage(
                                                result: RestaurantDiscoveryResult(
                                                  id: data['id']?.toString() ?? '',
                                                  name: plan!.restaurantName,
                                                  address: data['address']?.toString(),
                                                  city: data['city']?.toString(),
                                                  distanceKm: (data['distance_km'] as num?)?.toDouble() ?? 0,
                                                  latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
                                                  longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
                                                  phone: data['phone']?.toString(),
                                                  website: data['website'] == null ? null : Uri.tryParse(data['website'].toString()),
                                                  orderUri: data['order_url'] == null ? null : Uri.tryParse(data['order_url'].toString()),
                                                  openingHours: data['opening_hours']?.toString(),
                                                  deliveryAvailable: data['delivery_available'] == true,
                                                  cuisine: data['cuisine']?.toString(),
                                                ),
                                                order: false,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                              onOpenRecipe: plan!.isRecipe && plan!.status != 'cooked'
                                  ? () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RecipeDetailPage(
                                            recipeId: plan!.recipeId!,
                                            canMarkCooked: true,
                                            viewingTodaySelection: true,
                                            onTodayPlanChanged: load,
                                          ),
                                        ),
                                      );
                                      if (mounted) await load();
                                    }
                                  : null,
                            ),
                    ),
                    if (completedPlans.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _CompletedTodayDecisions(plans: completedPlans),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppDesign.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppDesign.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: page,
    );
  }


}

String _todayDateLabel() {
  final now = DateTime.now();
  const weekdays = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return '${weekdays[now.weekday - 1]}, ${now.day}. ${months[now.month - 1]}';
}

PreferredSizeWidget _todayAppBar() {
  return TogetherAppBar(
    automaticallyImplyLeading: false,
    title: Text(
      _todayDateLabel(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );
}

class _IncomingDecisionShareCard extends StatelessWidget {
  final DecisionShare share;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingDecisionShareCard({
    required this.share,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  String get _decisionLabel {
    final name = share.decisionName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final value = share.decisionValue?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Heutige Entscheidung';
  }

  String get _typeLabel {
    switch (share.decisionType) {
      case 'recipe':
        return 'Rezept';
      case 'order':
        return 'Bestellung';
      case 'dine_out':
        return 'Restaurant';
      case 'surprise':
        return 'Überraschung';
      default:
        return 'Geteilte Entscheidung';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppDesign.surface.withValues(alpha: 0.98),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppDesign.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Geteilte Entscheidung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppDesign.primaryDark,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Deine verbundene Person hat heute entschieden.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (share.imageUrl != null && share.imageUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  share.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              _decisionLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(_typeLabel),
            if (share.servings != null) ...[
              const SizedBox(height: 4),
              Text('${share.servings} Personen'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onAccept,
                    child: const Text('Übernehmen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayDecisionCard extends StatelessWidget {
  final VoidCallback onCook;
  final VoidCallback onOrder;
  final VoidCallback onDineOut;
  final VoidCallback onSurprise;
  final VoidCallback onDecide;
  const _TodayDecisionCard({
    required this.onCook,
    required this.onOrder,
    required this.onDineOut,
    required this.onSurprise,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gap = width >= 700 ? 14.0 : 10.0;
    final padding = width >= 700 ? 24.0 : 16.0;

    return Card(
      color: AppDesign.surface.withValues(alpha: 0.97),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, 18, padding, 20),
        child: Column(
          children: [
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: 1.06,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _TodayChoiceImage(
                  asset: 'assets/together/clean/icons/icon_cooking.png',
                  label: 'Wir kochen',
                  onTap: onCook,
                ),
                _TodayChoiceImage(
                  asset: 'assets/together/clean/icons/icon_delivery.png',
                  label: 'Wir bestellen',
                  onTap: onOrder,
                ),
                _TodayChoiceImage(
                  asset: 'assets/together/clean/icons/icon_restaurant.png',
                  label: 'Wir gehen essen',
                  onTap: onDineOut,
                ),
                _TodayChoiceImage(
                  asset: 'assets/together/clean/icons/icon_surprise.png',
                  label: 'Überrasch mich',
                  onTap: onSurprise,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDecide,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Entscheide Du'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayResultCard extends StatelessWidget {
  final TodayPlan plan;
  final VoidCallback? onOpenRecipe;
  final VoidCallback? onOpenOrder;
  final VoidCallback onCancel;
  final VoidCallback? onShare;

  const _TodayResultCard({
    required this.plan,
    required this.onOpenRecipe,
    required this.onOpenOrder,
    required this.onCancel,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width >= 700 ? 40.0 : 32.0;

    return Card(
      color: AppDesign.surface.withValues(alpha: 0.97),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(width >= 700 ? 28 : 18, 20, width >= 700 ? 28 : 18, 22),
        child: Column(
          children: [
            const SizedBox(height: 22),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: plan.status == 'cooked'
                    ? null
                    : plan.decisionType == 'order' || plan.decisionType == 'dine_out'
                        ? onOpenOrder
                        : onOpenRecipe,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      if (plan.isRecipe) ...[
                        ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: plan.imageUrl != null && plan.imageUrl!.trim().isNotEmpty
                            ? Image.network(
                                plan.imageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/together/clean/background/recipe_detail_background.png',
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/together/clean/background/recipe_detail_background.png',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        ),
                      ] else if (plan.decisionType == 'order') ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            FoodChoiceAssetService.assetFor(FoodMode.order, plan.decisionValue ?? '') ?? 'assets/together/clean/icons/icon_delivery.png',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ] else if (plan.decisionType == 'dine_out') ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            FoodChoiceAssetService.assetFor(
                                  FoodMode.dineOut,
                                  plan.restaurantCuisine ?? '',
                                ) ??
                                'assets/together/clean/icons/icon_restaurant.png',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (plan.status == 'cooked') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppDesign.secondarySurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Gekocht', style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (plan.decisionType == 'dine_out' && plan.restaurantCuisine != null) ...[
                        Text(
                          plan.restaurantCuisine!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppDesign.primaryDark.withValues(alpha: 0.72),
                              ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        plan.displayTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontSize: titleSize,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              color: AppDesign.primaryDark,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (plan.status == 'cooked')
              AppSurface(
                color: AppDesign.secondarySurface,
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      'Für heute ist alles erledigt.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deine Entscheidung ist abgeschlossen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else ...[
              if (plan.isSharedAccepted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.people_alt_rounded),
                    label: const Text('Gemeinsame Tagesentscheidung'),
                  ),
                )
              else if (plan.isShared)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Entscheidung bereits geteilt'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Entscheidung teilen'),
                  ),
                ),
              if (plan.isSharedAccepted) ...[
                const SizedBox(height: 8),
                Text(
                  'Entscheidung übernommen',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppDesign.primaryDark,
                      ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Entscheidung entfernen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayChoiceImage extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onTap;

  const _TodayChoiceImage({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _TodayServingsDialog extends StatefulWidget {
  final int initial;
  const _TodayServingsDialog({required this.initial});

  @override
  State<_TodayServingsDialog> createState() => _TodayServingsDialogState();
}

class _TodayServingsDialogState extends State<_TodayServingsDialog> {
  late int servings = widget.initial.clamp(1, 12).toInt();

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Für wie viele Personen?'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(tooltip: 'Weniger Portionen', onPressed: servings > 1 ? () => setState(() => servings--) : null, icon: const Icon(Icons.remove_circle_outline)),
            SizedBox(width: 110, child: Text('$servings Personen', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
            IconButton(tooltip: 'Mehr Portionen', onPressed: servings < 12 ? () => setState(() => servings++) : null, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, servings), child: const Text('Speichern')),
        ],
      );
}

class ShoppingPage extends StatefulWidget {
  final String planId;
  final String recipeName;
  final int servings;
  final bool shared;
  final VoidCallback? onCompleted;
  const ShoppingPage({super.key, required this.planId, required this.recipeName, required this.servings, this.shared = false, this.onCompleted});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final personalRepo = PersonalTodayRepository();
  final collaborationRepo = CollaborationRepository();
  List<ShoppingItem> items = [];
  int _shoppingLoadGeneration = 0;
  bool loading = true;
  Object? loadError;
  RealtimeChannel? channel;
  @override
  void initState() {
    super.initState();
    load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    try {
      final client = Supabase.instance.client;
      channel = client.channel('shopping-${widget.shared ? 'shared' : 'personal'}-${widget.planId}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: widget.shared ? 'shared_recipe_plan_id' : 'personal_today_plan_id',
            value: widget.planId,
          ),
          callback: (_) {
            if (mounted) load();
          },
        )
        ..subscribe();
    } on AssertionError {
      // Widget tests and offline previews can mount before Supabase exists.
    }
  }

  @override
  void dispose() {
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel!);
      } on AssertionError {
        // Supabase may be unavailable in widget tests/offline previews.
      }
    }
    super.dispose();
  }

  Future<void> load() async {
    final generation = ++_shoppingLoadGeneration;
    try {
      final value = widget.shared
          ? await collaborationRepo.shoppingItems(widget.planId)
          : await personalRepo.shoppingItems(widget.planId);
      if (!mounted || generation != _shoppingLoadGeneration) return;
      setState(() { items = value; loadError = null; loading = false; });
    } catch (e) {
      if (!mounted || generation != _shoppingLoadGeneration) return;
      setState(() { loading = false; loadError = e; });
    }
  }

  Future<void> toggleItem(ShoppingItem item, bool checked) async {
    final old = item.checked;
    setState(() {
      final index = items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        items[index] = ShoppingItem(id: item.id, name: item.name, quantity: item.quantity, unit: item.unit, checked: checked, foodId: item.foodId, category: item.category, source: item.source);
      }
    });
    try {
      if (widget.shared) {
        await collaborationRepo.setShoppingChecked(item.id, checked);
      } else {
        await personalRepo.setShoppingChecked(item.id, checked);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final index = items.indexWhere((i) => i.id == item.id);
        if (index != -1) items[index] = ShoppingItem(id: item.id, name: item.name, quantity: item.quantity, unit: item.unit, checked: old, foodId: item.foodId, category: item.category, source: item.source);
      });
      showAppError(context, e);
    }
  }

  Future<void> addItem() async {
    final result = await showDialog<_ShoppingEditResult>(
      context: context,
      builder: (_) => const _ShoppingItemDialog(),
    );
    if (result == null) return;
    try {
      if (widget.shared) {
        await collaborationRepo.addShoppingItem(planId: widget.planId, name: result.name, quantity: result.quantity, unit: result.unit);
      } else {
        await personalRepo.addShoppingItem(planId: widget.planId, name: result.name, quantity: result.quantity, unit: result.unit);
      }
      await load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> editItem(ShoppingItem item) async {
    final result = await showDialog<_ShoppingEditResult>(
      context: context,
      builder: (_) => _ShoppingItemDialog(item: item),
    );
    if (result == null) return;
    try {
      if (widget.shared) {
        await collaborationRepo.updateShoppingItem(itemId: item.id, name: result.name, quantity: result.quantity, unit: result.unit);
      } else {
        await personalRepo.updateShoppingItem(itemId: item.id, name: result.name, quantity: result.quantity, unit: result.unit);
      }
      await load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> clearCompleted() async {
    final completed = items.where((item) => item.checked).toList();
    if (completed.isEmpty) return;

    try {
      for (final item in completed) {
        if (widget.shared) {
          await collaborationRepo.deleteShoppingItem(item.id);
        } else {
          await personalRepo.deleteShoppingItem(item.id);
        }
      }

      if (widget.shared) {
        await collaborationRepo.removeSharedRecipePlan(widget.planId);
      } else {
        await personalRepo.removeTodayPlan(widget.planId);
      }

      if (mounted) {
        widget.onCompleted?.call();
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> deleteItem(ShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Artikel löschen?'),
        content: Text('„${item.name}“ wird aus ${widget.shared ? 'eurer gemeinsamen' : 'deiner'} Einkaufsliste entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (widget.shared) {
        await collaborationRepo.deleteShoppingItem(item.id);
      } else {
        await personalRepo.deleteShoppingItem(item.id);
      }
      await load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  String itemLabel(ShoppingItem item) {
    final hasUnit = item.unit.trim().isNotEmpty;
    final hasQuantity = item.quantity != 1 || hasUnit;
    if (!hasQuantity) return item.name;
    final quantity = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
    return '$quantity${hasUnit ? ' ${item.unit}' : ''} ${item.name}';
  }

  @override
  Widget build(BuildContext context) {
    final checked = items.where((item) => item.checked).length;
    final openItems = items.where((item) => !item.checked).toList();
    final completedItems = items.where((item) => item.checked).toList();

    Map<String, List<ShoppingItem>> grouped(List<ShoppingItem> source) {
      final result = <String, List<ShoppingItem>>{};
      for (final item in source) {
        result.putIfAbsent(item.category, () => []).add(item);
      }
      return result;
    }

    final openGrouped = grouped(openItems);
    final completedGrouped = grouped(completedItems);

    if (loadError != null) {
      return TogetherScaffold(
        backgroundType: TogetherBackgroundType.today,
        appBar: TogetherAppBar(title: Text(widget.shared ? 'Gemeinsame Einkaufsliste' : 'Einkaufsliste')),
        body: AppErrorView(error: loadError!, onRetry: load),
      );
    }

    final progress = items.isEmpty ? 0.0 : checked / items.length;
    final theme = Theme.of(context);

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.today,
      appBar: TogetherAppBar(
        title: Text(widget.shared ? 'Gemeinsame Einkaufsliste' : 'Einkaufsliste'),
        actions: [
          AppBadge(
            label: widget.shared ? 'Gemeinsam' : 'Persönlich',
            icon: widget.shared ? Icons.people_alt_rounded : Icons.person_rounded,
            backgroundColor: widget.shared ? AppDesign.accentSoft : AppDesign.primarySoft,
            foregroundColor: widget.shared ? AppDesign.accentDark : AppDesign.primaryDark,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                children: [
                  AppSurface(
                    padding: const EdgeInsets.all(20),
                    bordered: false,
                    color: AppDesign.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipeName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MetaPill(icon: Icons.people_outline_rounded, label: '${widget.servings} Personen'),
                            MetaPill(icon: Icons.check_circle_outline_rounded, label: '$checked von ${items.length} erledigt'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                          child: LinearProgressIndicator(value: progress, minHeight: 8),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: addItem,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Artikel hinzufügen'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (items.isNotEmpty && checked == items.length)
                    AppSurface(
                      color: AppDesign.secondarySurface,
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 34),
                          const SizedBox(height: 10),
                          Text(
                            'Einkaufsliste vollständig erledigt',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppDesign.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Alle Artikel sind abgehakt. Du kannst die Liste jetzt abschließen.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppDesign.text,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: clearCompleted,
                              icon: const Icon(Icons.done_all_rounded),
                              label: const Text('Einkaufsliste erledigt'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (items.isEmpty)
                    AppSurface(
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_basket_outlined, size: 42, color: AppDesign.mutedText),
                          const SizedBox(height: 12),
                          Text('Noch keine Artikel', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Füge etwas hinzu, wenn ihr es braucht.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  if (openItems.isNotEmpty) ...[
                    AppSurface(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOCH OFFEN',
                            style: theme.textTheme.labelLarge?.copyWith(
                              letterSpacing: .8,
                              color: AppDesign.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...openGrouped.entries.map(
                            (entry) => _ShoppingGroup(
                              category: entry.key,
                              items: entry.value,
                              itemLabel: itemLabel,
                              onToggle: toggleItem,
                              onEdit: editItem,
                              onDelete: deleteItem,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (completedItems.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    AppSurface(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'ERLEDIGT',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppDesign.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .8,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: clearCompleted,
                                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                                label: const Text('Leeren'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...completedGrouped.entries.map(
                            (entry) => _ShoppingGroup(
                              category: entry.key,
                              items: entry.value,
                              itemLabel: itemLabel,
                              onToggle: toggleItem,
                              onEdit: editItem,
                              onDelete: deleteItem,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}


class _ShoppingGroup extends StatelessWidget {
  final String category;
  final List<ShoppingItem> items;
  final String Function(ShoppingItem) itemLabel;
  final Future<void> Function(ShoppingItem, bool) onToggle;
  final Future<void> Function(ShoppingItem) onEdit;
  final Future<void> Function(ShoppingItem) onDelete;

  const _ShoppingGroup({
    required this.category,
    required this.items,
    required this.itemLabel,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.trim().toLowerCase() != 'weitere zutaten')
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppDesign.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
            AppSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final item = entry.value;
                  return AnimatedContainer(
                    duration: AppDesign.normal,
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: item.checked ? AppDesign.surfaceSoft.withValues(alpha: .55) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDesign.radiusXl),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: Checkbox(
                        value: item.checked,
                        onChanged: (value) {
                          if (value != null) onToggle(item, value);
                        },
                      ),
                      title: AnimatedDefaultTextStyle(
                        duration: AppDesign.fast,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: item.checked ? FontWeight.w500 : FontWeight.w600,
                              color: item.checked ? AppDesign.secondaryText : AppDesign.text,
                              decoration: item.checked ? TextDecoration.lineThrough : null,
                            ),
                        child: Text(itemLabel(item)),
                      ),
                      subtitle: item.source == 'manual'
                          ? Text('Manuell hinzugefügt', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDesign.secondaryText, fontSize: 13))
                          : null,
                      // Artikel werden nur über das Drei-Punkte-Menü bearbeitet.
                      onTap: null,
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Artikelaktionen',
                        onSelected: (value) {
                          if (value == 'edit') onEdit(item);
                          if (value == 'delete') onDelete(item);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                          PopupMenuItem(value: 'delete', child: Text('Löschen')),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
}

class _ShoppingEditResult {
  final String name;
  final num quantity;
  final String unit;
  const _ShoppingEditResult({required this.name, required this.quantity, required this.unit});
}

class _ShoppingItemDialog extends StatefulWidget {
  final ShoppingItem? item;
  const _ShoppingItemDialog({this.item});

  @override
  State<_ShoppingItemDialog> createState() => _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends State<_ShoppingItemDialog> {
  late final TextEditingController nameController;
  late final TextEditingController quantityController;
  late final TextEditingController unitController;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    nameController = TextEditingController(text: item?.name ?? '');
    quantityController = TextEditingController(text: item == null ? '' : (item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString()));
    unitController = TextEditingController(text: item?.unit ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    super.dispose();
  }

  void submit() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final parsed = num.tryParse(quantityController.text.trim().replaceAll(',', '.'));
    final quantity = parsed == null || parsed <= 0 ? 1 : parsed;
    Navigator.pop(context, _ShoppingEditResult(name: name, quantity: quantity, unit: unitController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return AlertDialog(
      title: Text(editing ? 'Artikel bearbeiten' : 'Artikel hinzufügen'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Artikel', hintText: 'z. B. Parmesan')), 
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: quantityController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Menge', hintText: 'optional'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: unitController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Einheit', hintText: 'z. B. g'))),
          ]),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft, child: Text('Menge und Einheit sind optional.')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: submit, child: Text(editing ? 'Speichern' : 'Hinzufügen')),
      ],
    );
  }
}
class _CompletedTodayDecisions extends StatelessWidget {
  final List<TodayPlan> plans;
  const _CompletedTodayDecisions({required this.plans});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            leading: const Icon(Icons.check_circle_rounded, color: AppDesign.primaryDark),
            title: Text(
              'Heute bereits erledigt',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppDesign.primaryDark,
                fontWeight: FontWeight.w800,
                letterSpacing: .3,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${plans.length}', style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
            children: plans.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.done_rounded, color: AppDesign.secondaryText),
              title: Text(
                item.displayTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppDesign.secondaryText,
                ),
              ),
              trailing: const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: AppDesign.secondaryText,
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}
