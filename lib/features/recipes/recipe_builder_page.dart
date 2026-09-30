import 'package:flutter/material.dart';

import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import 'add_recipe_page.dart';

/// Compatibility entry point for older navigation paths.
///
/// Recipe generation no longer calls an OpenAI API. The private two-person
/// app uses the external ChatGPT workflow and imports the resulting
/// `together_recipe.json` file.
class RecipeBuilderPage extends StatelessWidget {
  final String mainChoice;
  final String? decisionRequestId;
  final Set<String> initialSelectedFoodIds;

  const RecipeBuilderPage({
    super.key,
    required this.mainChoice,
    this.decisionRequestId,
    this.initialSelectedFoodIds = const <String>{},
    Object? repository,
  });

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(backgroundType: TogetherBackgroundType.recipes,
      appBar: const TogetherAppBar(title: Text('Rezept erstellen')),
      body: ChatGptRecipeSetupPage(
        initialMainChoice: mainChoice,
        initialSelectedFoodIds: initialSelectedFoodIds,
        decisionRequestId: decisionRequestId,
      ),
    );
  }
}
