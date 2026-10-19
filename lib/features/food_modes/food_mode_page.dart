import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import '../../core/app_design.dart';

import 'cook_next_step_page.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../core/services/food_choice_asset_service.dart';
import '../../core/food_mode.dart';
import '../../core/error_text.dart';
import 'chatgpt_restaurant_page.dart';
import '../settings/restaurant_favorites_page.dart';

class FoodModePage extends StatefulWidget {
  final FoodMode mode;
  final DateTime? planDate;
  final VoidCallback? onNavigateToToday;
  final String? decisionRequestId;

  const FoodModePage({
    super.key,
    required this.mode,
    this.planDate,
    this.onNavigateToToday,
    this.decisionRequestId,
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
          onNavigateToToday: widget.onNavigateToToday,
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
        AppFeedback.showSnackBar(context, 
          SnackBar(content: Text(friendlyError(error))),
        );
      }
      return;
    }

    // Dine-out choices are routed directly to the ChatGPT restaurant import.
  }

  void _select(BuildContext context, String choice) {
    _resolveAndOpen(context, choice);
  }

  Future<void> _openChatGptForCuisine(BuildContext context, String cuisine) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('fatzomat_pending_restaurant_import_cuisine', cuisine);
    if (!context.mounted) return;
    final selected = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChatGptRestaurantPage(
          planDate: widget.planDate,
          initialCuisine: cuisine,
          autoOpenChatGpt: true,
        ),
      ),
    );
    if (selected == true && context.mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(true);
      }
    }
  }

  Future<void> _openRestaurantFavorites(BuildContext context) async {
    final restaurant = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const RestaurantFavoritesPage(selectForToday: true),
      ),
    );
    if (restaurant == null || !context.mounted) return;
    try {
      await PersonalTodayRepository().selectDecision(
        type: 'dine_out',
        value: jsonEncode({
          'type': 'fatzomat_restaurant_suggestion',
          'schema_version': 1,
          'restaurant': restaurant,
        }),
        date: widget.planDate,
      );
      if (!context.mounted) return;

      // Return the successful decision to the caller. The Today screen owns
      // the next navigation step; popping again here can empty the Navigator
      // history when this flow was opened as the root of a nested route.
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      AppFeedback.showSnackBar(context, 
        SnackBar(content: Text(friendlyError(error))),
      );
    }
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
          onTap: () => widget.mode == FoodMode.dineOut
                              ? _openChatGptForCuisine(context, option.label)
                              : _select(context, option.label),
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
          _ModeOption('Deutsch'),
          _ModeOption('Französisch'),
          _ModeOption('Amerikanisch'),
          _ModeOption('Afrikanisch'),
          _ModeOption('Indisch'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.mode == FoodMode.dineOut) ...[
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF4D6),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    title: const Text('Meine Lieblingsrestaurants'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openRestaurantFavorites(context),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _choiceGrid(options),
            ],
          ),
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

      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
    }

    return Semantics(
      key: ValueKey<String>('food_choice_${mode.name}_${option.label}'),
      container: true,
      button: true,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('food_choice_tap_${mode.name}_${option.label}'),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The image deliberately occupies 4/5 of the card.
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17),
                      ),
                      child: image(),
                    ),
                  ),
                  // The remaining 1/5 is a separate, opaque caption area.
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      color: const Color(0xFFF8F5EF),
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

