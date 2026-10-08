import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/async_error.dart';
import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import 'today_page.dart';
import '../recipes/saved_recipes_page.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final _personal = PersonalTodayRepository();
  final _collaboration = CollaborationRepository();
  bool loading = true;
  Object? error;
  bool connected = false;
  Map<String, dynamic>? sharedPlan;
  String? personalPlanId;
  String personalRecipeName = 'Einkaufsliste';
  int personalServings = 2;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    load();
    _subscribe();
  }

  void _subscribe() {
    try {
      final client = Supabase.instance.client;
      channel = client.channel('shopping-list-entry');
      channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'connection_members',
          callback: (_) => load(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_recipe_plans',
          callback: (_) => load(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'personal_today_plans',
          callback: (_) => load(),
        )
        .subscribe();
    } on AssertionError {
      // Widget tests/offline previews may mount before Supabase exists.
    }
  }

  @override
  void dispose() {
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel!);
      } on AssertionError {
        // Ignore unavailable Supabase in previews/tests.
      }
    }
    super.dispose();
  }

  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    try {
      final connection = await _collaboration.connectionInfo();
      Map<String, dynamic>? shared;
      if (connection?.isConnected == true) {
        shared = await _collaboration.currentSharedRecipePlan();
      }

      final personal = await _personal.todayPlan();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        connected = connection?.isConnected == true;
        sharedPlan = shared;
        final activePersonal = personal?.status == 'cooked' || personal?.isRecipe != true ? null : personal;
        personalPlanId = activePersonal?.id;
        personalRecipeName = activePersonal?.name ?? 'Einkaufsliste';
        personalServings = activePersonal?.servings ?? 2;
        error = null;
        loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  void _openPersonal() {
    final planId = personalPlanId;
    if (planId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingPage(
          planId: planId,
          recipeName: personalRecipeName,
          servings: personalServings,
          shared: false,
          onCompleted: () {
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const TogetherScaffold(
        backgroundType: TogetherBackgroundType.today,
        appBar: TogetherAppBar(title: Text('Einkaufsliste')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return TogetherScaffold(
        backgroundType: TogetherBackgroundType.today,
        appBar: const TogetherAppBar(title: Text('Einkaufsliste')),
        body: AppErrorView(error: error!, onRetry: load),
      );
    }

    if (connected) {
      if (sharedPlan != null) {
        final plan = sharedPlan!;
        final recipe = plan['recipes'] is Map
            ? Map<String, dynamic>.from(plan['recipes'] as Map)
            : const <String, dynamic>{};
        return ShoppingPage(
          planId: plan['id'].toString(),
          recipeName: recipe['name']?.toString() ?? 'Gemeinsame Einkaufsliste',
          servings: (plan['servings'] as num?)?.toInt() ?? 2,
          shared: true,
          onCompleted: () {
            if (!mounted) return;
            setState(() => sharedPlan = null);
          },
        );
      }

      return TogetherScaffold(
        backgroundType: TogetherBackgroundType.today,
        appBar: const TogetherAppBar(title: Text('Einkaufsliste')),
        body: _EntryCard(
          icon: Icons.people_outline_rounded,
          title: 'Noch keine gemeinsame Einkaufsliste',
          text: 'Wählt zuerst ein gemeinsames Rezept für heute. Danach steht dieselbe Einkaufsliste beiden verbundenen Personen zur Verfügung.',
          actionLabel: 'Gemeinsames Rezept auswählen',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedRecipesPage())),
          secondaryLabel: personalPlanId != null ? 'Persönliche Liste öffnen' : null,
          onSecondaryPressed: personalPlanId != null ? _openPersonal : null,
        ),
      );
    }

    if (personalPlanId != null) {
      // ShoppingPage already renders its own page heading. Wrapping it in
      // another scaffold app bar would show "Einkaufsliste" twice.
      return ShoppingPage(
        planId: personalPlanId!,
        recipeName: personalRecipeName,
        servings: personalServings,
        shared: false,
        onCompleted: () {
          if (!mounted) return;
          setState(() {
            personalPlanId = null;
            personalRecipeName = 'Einkaufsliste';
            personalServings = 2;
          });
        },
      );
    }

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.today,
      appBar: const TogetherAppBar(title: Text('Einkaufsliste')),
      body: _EntryCard(
        icon: Icons.shopping_cart_outlined,
        title: 'Deine Einkaufsliste ist leer',
        text: 'Wähle zuerst ein Rezept für heute. Die zugehörigen Zutaten erscheinen anschließend hier.',
        actionLabel: 'Zu Heute',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayPage())),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String actionLabel;
  final VoidCallback onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  const _EntryCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.actionLabel,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppSurface(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            bordered: false,
            color: AppDesign.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppDesign.primarySoft,
                    borderRadius: BorderRadius.circular(AppDesign.radiusXl),
                  ),
                  child: Icon(icon, size: 34, color: AppDesign.primaryDark),
                ),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(actionLabel),
                  ),
                ),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onSecondaryPressed, child: Text(secondaryLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
