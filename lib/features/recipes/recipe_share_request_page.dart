import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/async_error.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/recipe.dart';
import '../../data/models/recipe_suggestion.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/recipe_repository.dart';

List<(String?, List<RecipeIngredient>)> _shareIngredientGroups(List<RecipeIngredient> ingredients) {
  final groups = <String?, List<RecipeIngredient>>{};
  for (final ingredient in ingredients) {
    final section = ingredient.section?.trim();
    groups.putIfAbsent(section == null || section.isEmpty ? null : section, () => <RecipeIngredient>[]).add(ingredient);
  }
  return groups.entries.map((entry) => (entry.key, List<RecipeIngredient>.unmodifiable(entry.value))).toList(growable: false);
}

class RecipeShareRequestPage extends StatefulWidget {
  final String suggestionId;

  const RecipeShareRequestPage({super.key, required this.suggestionId});

  @override
  State<RecipeShareRequestPage> createState() => _RecipeShareRequestPageState();
}

class _RecipeShareRequestPageState extends State<RecipeShareRequestPage> {
  final collaboration = CollaborationRepository();
  final recipes = RecipeRepository();
  RecipeSuggestion? suggestion;
  Recipe? recipe;
  bool loading = true;
  bool working = false;
  Object? loadError;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final loadedSuggestion = await collaboration.recipeSuggestion(widget.suggestionId);
      if (loadedSuggestion == null) {
        throw StateError('Die Rezeptanfrage wurde nicht gefunden.');
      }
      // A declined suggestion must remain reopenable from the notification.
      // Do not try to load the original recipe in that state: its access may
      // intentionally be revoked after the response, and the user only needs
      // the durable status message at this point.
      Recipe? loadedRecipe;
      if (!loadedSuggestion.isDeclined) {
        loadedRecipe = await recipes.getRecipeModel(loadedSuggestion.recipeId);
      }
      if (!mounted) return;
      setState(() {
        suggestion = loadedSuggestion;
        recipe = loadedRecipe;
        loadError = null;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = error;
      });
    }
  }

  Future<void> respond(bool accept) async {
    final current = suggestion;
    if (current == null || !current.isPending || working) return;
    setState(() => working = true);
    try {
      final result = await collaboration.respondToRecipeSuggestion(current.id, accept: accept);
      if (!mounted) return;
      setState(() {
        suggestion = result;
        working = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Rezept ist jetzt in der gemeinsamen Bibliothek bestätigt.' : 'Rezept wurde abgelehnt.')),
      );
      if (accept) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => working = false);
      showAppError(context, error);
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: const TogetherAppBar(title: Text('Geteiltes Rezept')),
      body: loadError != null
          ? AppErrorView(error: loadError!, onRetry: load)
          : loading
              ? const Center(child: CircularProgressIndicator())
              : suggestion?.isDeclined == true
                  ? const _RecipeShareStatusContent(
                      title: 'Rezept bereits abgelehnt',
                      message: 'Dieses Rezept wurde von dir bereits abgelehnt. Die Anfrage ist abgeschlossen.',
                      icon: Icons.block_rounded,
                    )
                  : recipe == null || suggestion == null
                      ? const Center(child: Text('Das Rezept ist nicht verfügbar.'))
                      : _RecipeShareContent(
                          recipe: recipe!,
                          suggestion: suggestion!,
                          working: working,
                          onAccept: () => respond(true),
                          onDecline: () => respond(false),
                    ),
    );
  }
}


class _RecipeShareStatusContent extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _RecipeShareStatusContent({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppDesign.softSurface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppDesign.primaryDark),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeShareContent extends StatelessWidget {
  final Recipe recipe;
  final RecipeSuggestion suggestion;
  final bool working;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RecipeShareContent({
    required this.recipe,
    required this.suggestion,
    required this.working,
    required this.onAccept,
    required this.onDecline,
  });

  String difficulty(String value) => switch (value) {
        'easy' => 'Einfach',
        'medium' => 'Mittel',
        'hard' => 'Aufwendig',
        _ => value,
      };

  @override
  Widget build(BuildContext context) {
    final total = recipe.prepTimeMinutes + recipe.cookTimeMinutes;
    final pending = suggestion.isPending;
    final statusText = switch (suggestion.status) {
      'accepted' => 'Dieses Rezept wurde bereits bestätigt.',
      'declined' => 'Dieses Rezept wurde bereits abgelehnt.',
      _ => null,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (recipe.imageUrl != null && recipe.imageUrl!.trim().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppDesign.softSurface,
                  child: Center(child: Icon(Icons.restaurant_rounded, size: 56)),
                ),
              ),
            ),
          )
        else
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppDesign.softSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(child: Icon(Icons.restaurant_rounded, size: 56, color: AppDesign.primaryDark)),
          ),
        const SizedBox(height: 18),
        Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'Dieses Rezept gehört zur gemeinsamen Bibliothek.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(icon: Icons.people_alt_outlined, text: '${recipe.servings} Personen'),
            _InfoChip(icon: Icons.schedule_rounded, text: '$total Min.'),
            _InfoChip(icon: Icons.signal_cellular_alt_rounded, text: difficulty(recipe.difficulty)),
          ],
        ),
        if (recipe.description.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        Text('Zutaten', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ..._shareIngredientGroups(recipe.ingredients).expand((group) => [
          if (group.$1 != null) Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(group.$1!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          ...group.$2.map((ingredient) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text('${_quantity(ingredient.quantity)} ${ingredient.unit} ${ingredient.name}'.trim())),
              ],
            ),
          )),
        ]),
        const SizedBox(height: 18),
        Text('Zubereitung', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ...recipe.instructions.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 14, child: Text('${entry.key + 1}')),
                const SizedBox(width: 10),
                Expanded(child: Text(entry.value)),
              ],
            ),
          ),
        ),
        if (statusText != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppDesign.softSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(statusText, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
        if (pending) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: working ? null : onDecline,
                  child: const Text('Ablehnen'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: working ? null : onAccept,
                  child: Text(working ? 'Wird bestätigt …' : 'Rezept bestätigen'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _quantity(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 17),
        label: Text(text),
      );
}
