import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_design.dart';
import '../../core/async_error.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/recipe.dart';
import '../../data/models/recipe_suggestion.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../recipes/recipe_share_request_page.dart';

class RecipeSuggestionsPage extends StatefulWidget {
  const RecipeSuggestionsPage({super.key});

  @override
  State<RecipeSuggestionsPage> createState() => _RecipeSuggestionsPageState();
}

class _RecipeSuggestionsPageState extends State<RecipeSuggestionsPage> {
  final collaboration = CollaborationRepository();
  final recipes = RecipeRepository();
  List<RecipeSuggestion> received = const [];
  List<RecipeSuggestion> sent = const [];
  final Map<String, Recipe> recipeCache = {};
  bool loading = true;
  Object? loadError;
  String? workingId;
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
      channel = client
          .channel('recipe-suggestions-${client.auth.currentUser?.id ?? 'current'}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'recipe_suggestions',
          callback: (_) => load(),
        )
        ..subscribe();
    } on AssertionError {
      // Offline previews and widget tests may mount before Supabase exists.
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

  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    try {
      final List<List<RecipeSuggestion>> results = await Future.wait<List<RecipeSuggestion>>([
        collaboration.receivedRecipeSuggestions(),
        collaboration.sentRecipeSuggestions(),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        received = results[0];
        sent = results[1];
        loadError = null;
        loading = false;
      });
    } catch (error) {
      if (mounted && generation == _loadGeneration) setState(() { loading = false; loadError = error; });
    }
  }

  Future<Recipe?> recipeFor(String id) async {
    if (recipeCache.containsKey(id)) return recipeCache[id];
    try {
      final recipe = await recipes.getRecipeModel(id);
      recipeCache[id] = recipe;
      if (mounted) setState(() {});
      return recipe;
    } catch (_) {
      return null;
    }
  }

  Future<void> respond(RecipeSuggestion suggestion, bool accept) async {
    if (workingId != null) return;
    setState(() => workingId = suggestion.id);
    try {
      await collaboration.respondToRecipeSuggestion(suggestion.id, accept: accept);
      await load();
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => workingId = null);
    }
  }

  Future<void> openRecipe(RecipeSuggestion suggestion) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeShareRequestPage(suggestionId: suggestion.id)),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.share,
      appBar: const TogetherAppBar(title: Text('Rezeptvorschläge')),
      body: loadError != null
          ? AppErrorView(error: loadError!, onRetry: load)
          : loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      Text('Empfangen', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (received.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Noch keine Rezeptvorschläge erhalten.')))
                      else
                        ...received.map((suggestion) => _SuggestionCard(
                              suggestion: suggestion,
                              recipe: recipeCache[suggestion.recipeId],
                              loading: workingId == suggestion.id,
                              received: true,
                              onOpen: () => openRecipe(suggestion),
                              onAccept: suggestion.isPending ? () => respond(suggestion, true) : null,
                              onDecline: suggestion.isPending ? () => respond(suggestion, false) : null,
                              loadRecipe: () => recipeFor(suggestion.recipeId),
                            )),
                      const SizedBox(height: 24),
                      Text('Gesendet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (sent.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Noch keine Rezeptvorschläge gesendet.')))
                      else
                        ...sent.map((suggestion) => _SuggestionCard(
                              suggestion: suggestion,
                              recipe: recipeCache[suggestion.recipeId],
                              loading: false,
                              received: false,
                              onOpen: () => openRecipe(suggestion),
                              onAccept: null,
                              onDecline: null,
                              loadRecipe: () => recipeFor(suggestion.recipeId),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final RecipeSuggestion suggestion;
  final Recipe? recipe;
  final bool loading;
  final bool received;
  final VoidCallback onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final Future<Recipe?> Function() loadRecipe;

  const _SuggestionCard({
    required this.suggestion,
    required this.recipe,
    required this.loading,
    required this.received,
    required this.onOpen,
    required this.onAccept,
    required this.onDecline,
    required this.loadRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Recipe?>(
              future: recipe == null ? loadRecipe() : Future.value(recipe),
              builder: (context, snapshot) {
                final value = recipe ?? snapshot.data;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppDesign.peachSurface,
                    child: const Icon(Icons.restaurant_menu_rounded, color: AppDesign.primaryDark),
                  ),
                  title: Text(value?.name ?? 'Rezept', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(_statusLabel(suggestion.status, received)),
                  onTap: onOpen,
                );
              },
            ),
            if (received && suggestion.isPending) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: loading ? null : onDecline, child: const Text('Ablehnen'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: loading ? null : onAccept, child: Text(loading ? 'Wird gespeichert …' : 'Annehmen'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status, bool received) {
    if (status == 'pending') return received ? 'Vorschlag wartet auf deine Antwort' : 'Vorschlag wartet auf Antwort';
    if (status == 'accepted') return 'Angenommen · persönliche Entscheidung bleibt bei dir';
    if (status == 'declined') return 'Abgelehnt';
    if (status == 'cancelled') return 'Zurückgenommen';
    return status;
  }
}
