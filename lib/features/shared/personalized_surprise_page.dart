import 'package:flutter/material.dart';

import '../../core/error_text.dart';
import '../../core/food_mode.dart';
import '../../core/services/surprise_recommendation_service.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/recipe.dart';
import '../../data/models/food.dart';
import '../../data/models/restaurant_discovery.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../recipes/recipe_detail_page.dart';
import '../food_modes/restaurant_detail_page.dart';

class PersonalizedSurprisePage extends StatefulWidget {
  final SurpriseRecommendation recommendation;
  final String? decisionRequestId;
  final bool persistPersonalDecision;
  final DateTime? planDate;
  final SurpriseRecommendationService service;
  final List<Recipe> savedRecipes;
  final Map<String, String> preferences;
  final List<Food> foods;

  PersonalizedSurprisePage({
    super.key,
    required this.recommendation,
    this.decisionRequestId,
    this.persistPersonalDecision = false,
    this.planDate,
    SurpriseRecommendationService? service,
    this.savedRecipes = const [],
    this.preferences = const {},
    this.foods = const [],
  }) : service = service ?? SurpriseRecommendationService();

  @override
  State<PersonalizedSurprisePage> createState() => _PersonalizedSurprisePageState();
}

class _PersonalizedSurprisePageState extends State<PersonalizedSurprisePage> {
  late SurpriseRecommendation _recommendation;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recommendation = widget.recommendation;
  }

  String get _modeLabel => switch (_recommendation.decision.mode) {
        FoodMode.cook => 'Wir kochen',
        FoodMode.order => 'Wir bestellen',
        FoodMode.dineOut => 'Wir gehen essen',
      };

  Future<void> _surpriseAgain() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final next = await widget.service.generate(
        savedRecipes: widget.savedRecipes,
        preferences: widget.preferences,
        foods: widget.foods,
      );
      if (!mounted) return;
      setState(() => _recommendation = next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectRecipe(Recipe recipe) async {
    final id = recipe.id;
    if (id == null || id.isEmpty) return;
    await _saveDecision(type: 'recipe', value: recipe.name, recipeId: id);
  }

  Future<void> _selectRestaurant(RestaurantDiscoveryResult result) async {
    await _saveDecision(
      type: _recommendation.decision.mode == FoodMode.order ? 'order' : 'dine_out',
      value: result.name,
    );
  }

  Future<void> _saveDecision({required String type, required String value, String? recipeId}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (widget.decisionRequestId != null) {
        await CollaborationRepository().resolveDecisionRequest(
          requestId: widget.decisionRequestId!,
          decisionMode: _recommendation.decision.mode.name,
          resultType: type,
          resultId: recipeId ?? value,
        );
      } else if (widget.persistPersonalDecision) {
        await PersonalTodayRepository().selectDecision(
          type: type,
          value: value,
          recipeId: recipeId,
          date: widget.planDate,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openRecipe(Recipe recipe) {
    final id = recipe.id;
    if (id == null || id.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: id)));
  }

  void _openRestaurant(RestaurantDiscoveryResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(result: result, order: _recommendation.decision.mode == FoodMode.order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCook = _recommendation.isRecipe;
    final resultsCount = isCook ? _recommendation.recipes.length : _recommendation.restaurants.length;

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.decisionResult,
      appBar: TogetherAppBar(title: const Text('Deine Überraschung')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                children: [
                  Center(child: Icon(Icons.auto_awesome_rounded, size: 64, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  Center(child: Text('Überraschung für heute', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                  const SizedBox(height: 6),
                  Center(child: Text(_modeLabel, style: Theme.of(context).textTheme.titleLarge)),
                  const SizedBox(height: 18),
                  if (resultsCount == 0)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          isCook
                              ? 'Es sind noch keine persönlichen Rezepte für eine Überraschung vorhanden.'
                              : 'Gerade konnten keine passenden Ergebnisse gefunden werden.',
                        ),
                      ),
                    )
                  else if (isCook)
                    ..._recommendation.recipes.map(_recipeCard)
                  else
                    ..._recommendation.restaurants.map(_restaurantCard),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading || _saving ? null : _surpriseAgain,
                    icon: const Icon(Icons.casino_outlined),
                    label: const Text('Noch einmal überraschen'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _recipeCard(Recipe recipe) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: recipe.imageUrl == null
              ? const Icon(Icons.restaurant_menu_rounded)
              : Image.network(recipe.imageUrl!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_menu_rounded)),
          title: Text(recipe.name),
          subtitle: Text('${recipe.prepTimeMinutes + recipe.cookTimeMinutes} Min · ${recipe.difficulty}'),
          onTap: () => _openRecipe(recipe),
          trailing: FilledButton(
            onPressed: _saving ? null : () => _selectRecipe(recipe),
            child: const Text('Auswählen'),
          ),
        ),
      );

  Widget _restaurantCard(RestaurantDiscoveryResult result) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(_recommendation.decision.mode == FoodMode.order ? Icons.delivery_dining_rounded : Icons.restaurant_rounded),
          title: Text(result.name),
          subtitle: Text([
            if (result.cuisine != null) result.cuisine!,
            result.formattedDistance,
          ].join(' · ')),
          onTap: () => _openRestaurant(result),
          trailing: FilledButton(
            onPressed: _saving ? null : () => _selectRestaurant(result),
            child: const Text('Auswählen'),
          ),
        ),
      );
}
