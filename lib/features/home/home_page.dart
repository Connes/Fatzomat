import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_design.dart';
import '../../core/error_text.dart';
import '../../core/services/surprise_recommendation_service.dart';
import '../../core/food_mode.dart';
import '../../core/widgets/together_background.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/models/food.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../food_modes/food_mode_page.dart';
import '../shared/personalized_surprise_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _surprising = false;
  CollaborationRepository? _collaboration;
  bool _loadingDecisionMessage = false;

  CollaborationRepository get _collaborationRepository =>
      _collaboration ??= CollaborationRepository();

  @override
  void initState() {
    super.initState();

  }


  void _open(FoodMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodModePage(mode: mode)),
    );
  }

  Future<void> _surprise() async {
    if (_surprising) return;
    setState(() => _surprising = true);
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalizedSurprisePage(
            recommendation: recommendation,
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
    } finally {
      if (mounted) setState(() => _surprising = false);
    }
  }

  Future<void> _askPartnerToDecide() async {
    if (_loadingDecisionMessage) return;
    setState(() => _loadingDecisionMessage = true);
    try {
      final connection = await _collaborationRepository.connectionInfo();
      if (!mounted) return;
      if (connection?.isConnected != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Es ist noch keine zweite Person verbunden.')),
        );
        return;
      }
      await _collaborationRepository.sendDecisionMessage(type: 'ask');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nachricht „Entscheide Du“ gesendet.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _loadingDecisionMessage = false);
    }
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppDesign.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppDesign.background,
        body: TogetherBackground(
          type: TogetherBackgroundType.home,
          child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth >= 600 ? 28.0 : 14.0;
                  final maxContentWidth = 760.0;
                  final contentWidth = (constraints.maxWidth - horizontal * 2)
                      .clamp(0.0, maxContentWidth)
                      .toDouble();
                  final gap = constraints.maxWidth >= 600 ? 16.0 : 12.0;
                  final cardWidth = (contentWidth - gap) / 2;
                  final cardHeight = (cardWidth * (480 / 540)).clamp(158.0, 390.0).toDouble();
                  final gridHeight = cardHeight * 2 + gap;
                  const ctaGap = 16.0;
                  const ctaHeight = 60.0;
                  final groupHeight = gridHeight + ctaGap + ctaHeight;
                  final verticalRoom = constraints.maxHeight - groupHeight;
                  final topSpace = verticalRoom > 0 ? verticalRoom / 2 : 12.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(horizontal, topSpace, horizontal, 18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          children: [
                            SizedBox(
                              width: contentWidth,
                              child: const Padding(
                                padding: EdgeInsets.only(bottom: 14),
                                child: Text(
                                  'Willkommen',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: contentWidth,
                              child: GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: gap,
                                mainAxisSpacing: gap,
                                childAspectRatio: cardWidth / cardHeight,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _HomeChoiceTile(
                                    asset: 'assets/together/clean/icons/icon_cooking.png',
                                    semanticLabel: 'Wir kochen',
                                    onTap: () => _open(FoodMode.cook),
                                  ),
                                  _HomeChoiceTile(
                                    asset: 'assets/together/clean/icons/icon_delivery.png',
                                    semanticLabel: 'Wir bestellen',
                                    onTap: () => _open(FoodMode.order),
                                  ),
                                  _HomeChoiceTile(
                                    asset: 'assets/together/clean/icons/icon_restaurant.png',
                                    semanticLabel: 'Wir gehen essen',
                                    onTap: () => _open(FoodMode.dineOut),
                                  ),
                                  _HomeChoiceTile(
                                    asset: 'assets/together/clean/icons/icon_surprise.png',
                                    semanticLabel: 'Überrasch mich',
                                    onTap: _surprise,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: ctaGap),
                            SizedBox(
                              width: contentWidth,
                              height: ctaHeight,
                              child: Semantics(
                                button: true,
                                label: 'Person zur Entscheidung für heute auffordern.',
                                child: FilledButton.icon(
                                  onPressed: _askPartnerToDecide,
                                icon: const Icon(Icons.people_alt_rounded, size: 25),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Entscheide Du',
                                  ),
                                ),
                                  style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A3D),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: const Color(0x45FF8A3D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
    );
  }
}

class _HomeChoiceTile extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final String semanticLabel;

  const _HomeChoiceTile({
    required this.asset,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
