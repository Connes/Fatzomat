import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/async_error.dart';
import '../../core/app_design.dart';
import '../../core/food_mode.dart';
import '../../core/services/food_choice_asset_service.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../core/error_text.dart';
import '../../data/models/recipe.dart';
import '../../data/models/food.dart';
import '../../data/repositories/food_repository.dart';
import 'additional_ingredients_page.dart';
import 'recipe_detail_page.dart';
import 'together_chatgpt_prompt.dart';
import '../../data/services/together_recipe_file_service.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../data/services/recipe_image_service.dart';

class AddRecipePage extends StatelessWidget {
  const AddRecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: const TogetherAppBar(title: Text('Rezept hinzufügen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _OptionCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Mit ChatGPT erstellen',
            subtitle: 'Ein Rezept anhand deiner Auswahl mit ChatGPT erstellen lassen.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatGptRecipeSetupPage()),
            ),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.photo_camera_rounded,
            title: 'Rezept aus Foto erstellen',
            subtitle: 'Foto eines Rezepts an ChatGPT übergeben und als together_recipe.json übernehmen.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhotoRecipeChatGptPage()),
            ),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.file_upload_rounded,
            title: 'Rezeptdatei importieren',
            subtitle: 'Eine together_recipe.json auswählen, prüfen und in die gemeinsame Sammlung speichern.',
            onTap: () => _importFile(context),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile(BuildContext context) async {
    try {
      final recipe = await const TogetherRecipeFileService().pickRecipe();
      if (recipe == null || !context.mounted) return;

      final save = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => RecipeImportPreviewPage(recipe: recipe)),
      );
      if (save == true && context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }

}


class PhotoRecipeChatGptPage extends StatefulWidget {
  const PhotoRecipeChatGptPage({super.key});

  @override
  State<PhotoRecipeChatGptPage> createState() => _PhotoRecipeChatGptPageState();
}

class _PhotoRecipeChatGptPageState extends State<PhotoRecipeChatGptPage> {
  final ImagePicker _picker = ImagePicker();
  bool working = false;

  Future<void> _pick(ImageSource source, BuildContext shareContext) async {
    if (working) return;
    setState(() => working = true);
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 92, maxWidth: 2400);
      if (image == null || !mounted) return;

      final prompt = TogetherChatGptPrompt.buildPhotoImportPrompt();
      await Clipboard.setData(ClipboardData(text: prompt));

      final box = shareContext.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: prompt,
          files: [XFile(image.path)],
          subject: 'Rezeptfoto für Schmackofatz',
          title: 'Rezeptfoto an ChatGPT',
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto und Prompt wurden zum Teilen vorbereitet. Wähle ChatGPT aus und importiere danach die erzeugte together_recipe.json in Schmackofatz.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _chooseSource(BuildContext shareContext) async {
    if (working) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Foto aus Galerie wählen'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source, shareContext);
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: const TogetherAppBar(title: Text('Rezept aus Foto erstellen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppDesign.surface.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(AppDesign.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.document_scanner_rounded, size: 46, color: AppDesign.primaryDark),
                const SizedBox(height: 16),
                Text('Rezeptfoto an ChatGPT übergeben', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                const Text('Schmackofatz verwendet einen festen Import-Prompt. ChatGPT liest das Foto aus und erstellt daraus eine together_recipe.json. Prüfe das Rezept anschließend in der Vorschau, bevor es in eure gemeinsame Sammlung gespeichert wird.'),
                const SizedBox(height: 18),
                Builder(
                  builder: (buttonContext) => FilledButton.icon(
                    onPressed: working ? null : () => _chooseSource(buttonContext),
                    icon: working
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.photo_camera_rounded),
                    label: Text(working ? 'Wird vorbereitet …' : 'Foto auswählen'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Der Teilen-Dialog übergibt Foto und Prompt. Falls ChatGPT nicht als Ziel angeboten wird, kann das Foto dort manuell angehängt und der kopierte Prompt eingefügt werden.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


List<(String?, List<RecipeIngredient>)> _ingredientSections(List<RecipeIngredient> ingredients) {
  final groups = <String?, List<RecipeIngredient>>{};
  for (final ingredient in ingredients) {
    final section = ingredient.section?.trim();
    groups.putIfAbsent(section == null || section.isEmpty ? null : section, () => <RecipeIngredient>[]).add(ingredient);
  }
  return groups.entries.map((entry) => (entry.key, List<RecipeIngredient>.unmodifiable(entry.value))).toList(growable: false);
}

class RecipeImportPreviewPage extends StatefulWidget {
  final Recipe recipe;
  final String? decisionRequestId;
  final bool selectForToday;

  const RecipeImportPreviewPage({
    super.key,
    required this.recipe,
    this.decisionRequestId,
    this.selectForToday = false,
  });

  @override
  State<RecipeImportPreviewPage> createState() => _RecipeImportPreviewPageState();
}

class _RecipeImportPreviewPageState extends State<RecipeImportPreviewPage> {
  final RecipeRepository repository = RecipeRepository();
  final CollaborationRepository collaboration = CollaborationRepository();
  late Recipe _recipe;
  bool saving = false;
  XFile? selectedImage;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  Future<void> _editRecipe() async {
    if (saving) return;
    final edited = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(
        builder: (_) => ManualRecipePage(
          initialRecipe: _recipe,
          returnRecipeOnly: true,
        ),
      ),
    );
    if (!mounted || edited == null) return;
    setState(() => _recipe = edited);
  }

  Future<void> _pickRecipeImage() async {
    if (saving) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Aus Galerie wählen'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = await RecipeImageService().pickImage(source: source);
      if (image == null || !mounted) return;
      setState(() => selectedImage = image);
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  void _clearSelectedImage() {
    if (saving) return;
    setState(() => selectedImage = null);
  }

  Future<void> _save({bool allowDuplicate = false}) async {
    if (saving) return;
    setState(() => saving = true);
    var saveDuplicate = allowDuplicate;
    try {
      if (!saveDuplicate) {
        final duplicate = await repository.findDuplicateRecipe(_recipe);
        if (duplicate != null && mounted) {
          setState(() => saving = false);
          final action = await showDialog<String>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Rezept bereits vorhanden'),
              content: Text('„${duplicate.name}“ gibt es bereits in eurer gemeinsamen Rezeptsammlung.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, 'open'), child: const Text('Vorhandenes öffnen')),
                TextButton(onPressed: () => Navigator.pop(dialogContext, 'save'), child: const Text('Trotzdem speichern')),
              ],
            ),
          );
          if (!mounted) return;
          if (action == 'open' && duplicate.id != null) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: duplicate.id!)));
            return;
          }
          if (action != 'save') return;
          setState(() => saving = true);
          saveDuplicate = true;
        }
      }

      final recipeId = await repository.saveRecipeModel(_recipe, allowDuplicate: saveDuplicate);

      if (selectedImage != null) {
        final upload = await RecipeImageService().upload(
          recipeId: recipeId,
          file: selectedImage!,
        );
        await repository.setRecipeImage(recipeId, upload);
      }

      // A collaboration decision is resolved for the shared flow only. It must
      // never also write to the current user's personal Today plan.
      if (widget.decisionRequestId != null) {
        await collaboration.resolveDecisionRequest(
          requestId: widget.decisionRequestId!,
          decisionMode: 'cook',
          resultType: 'recipe',
          resultId: recipeId,
          servings: _recipe.servings.clamp(1, 12).toInt(),
        );
      }

      if (widget.selectForToday && widget.decisionRequestId == null) {
        await PersonalTodayRepository().selectRecipeForToday(
          recipeId,
          servings: _recipe.servings.clamp(1, 12).toInt(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('„${_recipe.name}“ wurde gespeichert.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _formatQuantity(num value) {
    final doubleValue = value.toDouble();
    if (doubleValue == doubleValue.roundToDouble()) return doubleValue.toInt().toString();
    return doubleValue.toStringAsFixed(doubleValue < 10 ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe;
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      extendBody: true,
      appBar: const TogetherAppBar(title: Text('Rezept prüfen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppDesign.surface.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(AppDesign.radiusXl),
              boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
                if (recipe.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(icon: Icons.people_outline, label: '${recipe.servings} Portionen'),
                    _MetaChip(icon: Icons.schedule_outlined, label: '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} Min.'),
                    _MetaChip(icon: Icons.bar_chart_outlined, label: recipe.difficulty),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _RecipeImagePickerCard(
            image: selectedImage,
            existingUrl: recipe.imageUrl,
            onPick: _pickRecipeImage,
            onClear: selectedImage == null ? null : _clearSelectedImage,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: saving ? null : _editRecipe,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Rezept bearbeiten'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Zutaten'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppDesign.surface.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(AppDesign.radiusXl),
            ),
            child: Column(
              children: _ingredientSections(recipe.ingredients).expand((group) => [
                if (group.$1 != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(group.$1!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppDesign.primaryDark)),
                  ),
                ],
                ...group.$2.map((ingredient) {
                  final amount = ingredient.isQualitative ? '' : '${_formatQuantity(ingredient.quantity)} ';
                  final unit = ingredient.unit.trim();
                  final separator = amount.isEmpty || unit.isEmpty ? '' : ' ';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 7, color: AppDesign.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: Text('$amount$unit$separator${ingredient.name}')),
                      ],
                    ),
                  );
                }),
              ]).toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Zubereitung'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: AppDesign.surface.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(AppDesign.radiusXl),
            ),
            child: Column(
              children: recipe.instructions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppDesign.primary, shape: BoxShape.circle),
                        child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: AppDesign.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusXl)),
            ),
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            label: Text(saving ? 'Speichern …' : 'Rezept speichern'),
          ),
        ),
      ),
    );
  }
}

class _RecipeImagePickerCard extends StatelessWidget {
  final XFile? image;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _RecipeImagePickerCard({
    required this.image,
    required this.existingUrl,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasExisting = existingUrl?.trim().isNotEmpty == true;
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(AppDesign.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (image != null)
            Image.file(File(image!.path), height: 190, fit: BoxFit.cover)
          else if (hasExisting)
            Image.network(existingUrl!, height: 190, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 190, child: Center(child: Icon(Icons.broken_image_outlined))))
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
              child: Row(
                children: [
                  Icon(Icons.restaurant_rounded),
                  SizedBox(width: 10),
                  Expanded(child: Text('Rezeptbild (optional)', style: TextStyle(fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(image != null || hasExisting ? 'Bild ersetzen' : 'Bild auswählen'),
                  ),
                ),
                if (onClear != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Ausgewähltes Bild entfernen',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppDesign.primarySoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppDesign.primaryDark),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppDesign.primaryDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


class ChatGptRecipeSetupPage extends StatefulWidget {
  final String? initialMainChoice;
  final Set<String> initialSelectedFoodIds;
  final String? decisionRequestId;
  final bool selectForToday;

  const ChatGptRecipeSetupPage({
    super.key,
    this.initialMainChoice,
    this.initialSelectedFoodIds = const <String>{},
    this.decisionRequestId,
    this.selectForToday = false,
  });

  @override
  State<ChatGptRecipeSetupPage> createState() => _ChatGptRecipeSetupPageState();
}

class _ChatGptRecipeSetupPageState extends State<ChatGptRecipeSetupPage> {
  final FoodRepository repository = FoodRepository();
  String? mainChoice;
  Set<String> selectedFoodIds = <String>{};
  List<Food> foods = <Food>[];
  bool loading = true;
  String? error;
  bool opening = false;

  static const choices = <String>['Rind', 'Schwein', 'Huhn', 'Fisch', 'Vegetarisch'];

  @override
  void initState() {
    super.initState();
    mainChoice = widget.initialMainChoice;
    selectedFoodIds = {...widget.initialSelectedFoodIds};
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    try {
      final rows = await repository.foods();
      if (!mounted) return;
      setState(() {
        foods = rows;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = friendlyError(e);
      });
    }
  }

  Future<void> _selectIngredients() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => AdditionalIngredientsPage(
          mainChoice: mainChoice,
          initialSelectedFoodIds: selectedFoodIds,
          repository: repository,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => selectedFoodIds = {...result});
  }

  Future<void> _importRecipeFile() async {
    try {
      final recipe = await const TogetherRecipeFileService().pickRecipe();
      if (recipe == null || !mounted) return;

      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeImportPreviewPage(
            recipe: recipe,
            decisionRequestId: widget.decisionRequestId,
            selectForToday: widget.selectForToday || widget.decisionRequestId != null,
          ),
        ),
      );
      if (saved == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _copyPromptAndOpenChatGpt() async {
    final selectedFoods = selectedFoodIds
        .map((id) => foods.where((food) => food.id == id).firstOrNull)
        .whereType<Food>()
        .toList(growable: false);

    if (mainChoice == null) {
      _show('Bitte zuerst eine Hauptauswahl wählen.');
      return;
    }
    final prompt = TogetherChatGptPrompt.build(
      mainChoice: mainChoice!,
      selectedFoods: selectedFoods,
    );

    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;

    setState(() => opening = true);
    try {
      const channel = MethodChannel('together/chatgpt');
      final opened = await channel.invokeMethod<bool>('openApp') ?? false;
      if (!opened) {
        final uri = Uri.parse('https://chatgpt.com/');
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
          throw StateError('ChatGPT konnte nicht geöffnet werden.');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt kopiert. In ChatGPT einfügen und das JSON anschließend in Schmackofatz importieren.')),
      );
    } on PlatformException catch (e) {
      if (mounted) showAppError(context, StateError(e.message ?? 'ChatGPT konnte nicht geöffnet werden.'));
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _icon(String choice) => switch (choice) {
        'Rind' => Icons.lunch_dining_rounded,
        'Schwein' => Icons.restaurant_rounded,
        'Huhn' => Icons.set_meal_rounded,
        'Fisch' => Icons.phishing_rounded,
        'Vegetarisch' => Icons.eco_rounded,
        _ => Icons.restaurant_menu_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedFoodIds.length;
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: const TogetherAppBar(title: Text('Mit ChatGPT erstellen')),
      extendBody: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.45,
                      ),
                      itemCount: choices.length,
                      itemBuilder: (context, index) {
                        final choice = choices[index];
                        final selected = mainChoice == choice;
                        final asset = FoodChoiceAssetService.assetFor(FoodMode.cook, choice);
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() => mainChoice = choice),
                            child: Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (asset != null)
                                          Expanded(
                                            child: Image.asset(
                                              asset,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Icon(_icon(choice), size: 44),
                                            ),
                                          )
                                        else
                                          const Expanded(child: SizedBox()),
                                        const SizedBox(height: 8),
                                        Text(
                                          choice,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Icon(Icons.check_circle_rounded, size: 22),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _selectIngredients,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(selectedCount == 0 ? 'Zutaten auswählen' : 'Zutaten ändern ($selectedCount)'),
                    ),
                    if (selectedCount > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        selectedFoodIds
                            .map((id) => foods.where((food) => food.id == id).firstOrNull?.name)
                            .whereType<String>()
                            .join(', '),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _importRecipeFile,
                      icon: const Icon(Icons.file_upload_rounded),
                      label: const Text('Erstellte JSON-Datei importieren'),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: FilledButton.icon(
            onPressed: opening ? null : _copyPromptAndOpenChatGpt,
            icon: opening ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Prompt kopieren & ChatGPT öffnen'),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class ManualRecipePage extends StatefulWidget {
  final Recipe? initialRecipe;
  final bool returnRecipeOnly;

  const ManualRecipePage({
    super.key,
    this.initialRecipe,
    this.returnRecipeOnly = false,
  });

  @override
  State<ManualRecipePage> createState() => _ManualRecipePageState();
}

class _ManualRecipePageState extends State<ManualRecipePage> {
  final name = TextEditingController();
  final description = TextEditingController();
  final servings = TextEditingController(text: '2');
  final prep = TextEditingController();
  final cook = TextEditingController();
  final difficulty = TextEditingController(text: 'Einfach');
  final ingredients = <_IngredientDraft>[_IngredientDraft()];
  final steps = <TextEditingController>[TextEditingController()];
  bool saving = false;
  bool get editing => widget.initialRecipe?.id != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecipe;
    if (initial == null) return;
    name.text = initial.name;
    description.text = initial.description;
    servings.text = initial.servings.toString();
    prep.text = initial.prepTimeMinutes.toString();
    cook.text = initial.cookTimeMinutes.toString();
    difficulty.text = initial.difficulty;
    for (final draft in ingredients) {
      draft.dispose();
    }
    ingredients.clear();
    for (final ingredient in initial.ingredients) {
      ingredients.add(_IngredientDraft.fromIngredient(ingredient));
    }
    while (ingredients.isEmpty) {
      ingredients.add(_IngredientDraft());
    }
    for (final controller in steps) {
      controller.dispose();
    }
    steps
      ..clear()
      ..addAll(initial.instructions.map((text) => TextEditingController(text: text)));
    if (steps.isEmpty) steps.add(TextEditingController());
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    servings.dispose();
    prep.dispose();
    cook.dispose();
    difficulty.dispose();
    for (final item in ingredients) {
      item.dispose();
    }
    for (final controller in steps) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (name.text.trim().isEmpty) {
      _show('Bitte einen Rezeptnamen eingeben.');
      return;
    }
    final validIngredients = ingredients
        .where((i) => i.name.text.trim().isNotEmpty)
        .toList(growable: false);
    if (validIngredients.isEmpty) {
      _show('Bitte mindestens eine Zutat eingeben.');
      return;
    }
    final invalidQuantity = validIngredients.firstWhere(
      (ingredient) => (num.tryParse(ingredient.amount.text.trim().replaceAll(',', '.')) ?? 0) <= 0,
      orElse: () => validIngredients.first,
    );
    if (validIngredients.any((ingredient) => (num.tryParse(ingredient.amount.text.trim().replaceAll(',', '.')) ?? 0) <= 0)) {
      _show('Bitte für „${invalidQuantity.name.text.trim()}“ eine positive Menge eingeben.');
      return;
    }
    final validSteps = steps.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    if (validSteps.isEmpty) {
      _show('Bitte mindestens einen Zubereitungsschritt eingeben.');
      return;
    }

    setState(() => saving = true);
    try {
      final recipe = Recipe(
        name: name.text.trim(),
        description: description.text.trim(),
        servings: _int(servings.text, fallback: 2, min: 1, max: 99),
        prepTimeMinutes: _int(prep.text, fallback: 0, min: 0, max: 1440),
        cookTimeMinutes: _int(cook.text, fallback: 0, min: 0, max: 1440),
        difficulty: difficulty.text.trim().isEmpty ? 'Einfach' : difficulty.text.trim(),
        instructions: validSteps,
        ingredients: validIngredients.map((i) => i.toIngredient()).toList(growable: false),
      );
      if (widget.returnRecipeOnly) {
        Navigator.pop(context, Recipe(
          id: widget.initialRecipe?.id,
          name: recipe.name,
          description: recipe.description,
          servings: recipe.servings,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
          difficulty: recipe.difficulty,
          instructions: recipe.instructions,
          ingredients: recipe.ingredients,
          imageUrl: widget.initialRecipe?.imageUrl,
          imagePath: widget.initialRecipe?.imagePath,
        ));
        return;
      }
      if (editing) {
        await RecipeRepository().updateSharedRecipe(Recipe(
          id: widget.initialRecipe!.id,
          name: recipe.name,
          description: recipe.description,
          servings: recipe.servings,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
          difficulty: recipe.difficulty,
          instructions: recipe.instructions,
          ingredients: recipe.ingredients,
          imageUrl: widget.initialRecipe!.imageUrl,
          imagePath: widget.initialRecipe!.imagePath,
        ));
      } else {
        await RecipeRepository().saveRecipeModel(recipe);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezept gespeichert.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int _int(String value, {required int fallback, required int min, required int max}) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return fallback;
    return parsed.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      extendBody: true,
      appBar: TogetherAppBar(title: Text(editing ? 'Rezept bearbeiten' : 'Rezept manuell erstellen')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
        children: [
          _RecipeFieldCard(
            icon: Icons.description_outlined,
            label: 'Rezeptname *',
            hint: 'z. B. Pasta mit Tomatensauce',
            controller: name,
          ),
          const SizedBox(height: 12),
          _RecipeFieldCard(
            icon: Icons.edit_note_rounded,
            label: 'Beschreibung (optional)',
            hint: 'z. B. Ein schnelles und leckeres Rezept …',
            controller: description,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _RecipeFieldCard(
            icon: Icons.groups_rounded,
            label: 'Portionen',
            controller: servings,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _RecipeFieldCard(
            icon: Icons.schedule_rounded,
            label: 'Vorbereitung (Min.)',
            hint: 'z. B. 15',
            controller: prep,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _RecipeFieldCard(
            icon: Icons.schedule_rounded,
            label: 'Kochen (Min.)',
            hint: 'z. B. 30',
            controller: cook,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _RecipeFieldCard(
            icon: Icons.bar_chart_rounded,
            label: 'Schwierigkeit',
            controller: difficulty,
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          const SizedBox(height: 16),
          _RecipeSectionCard(
            icon: Icons.shopping_basket_outlined,
            title: 'Zutaten',
            children: [
              ...List.generate(
                ingredients.length,
                (index) => _IngredientRow(
                  draft: ingredients[index],
                  onChanged: () => setState(() {}),
                  onRemove: ingredients.length == 1
                      ? null
                      : () => setState(() {
                            ingredients[index].dispose();
                            ingredients.removeAt(index);
                          }),
                ),
              ),
              const SizedBox(height: 4),
              _SectionAction(
                icon: Icons.add_rounded,
                label: 'Zutat hinzufügen',
                onPressed: () => setState(() => ingredients.add(_IngredientDraft())),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RecipeSectionCard(
            icon: Icons.format_list_numbered_rounded,
            title: 'Zubereitung',
            children: [
              ...List.generate(
                steps.length,
                (index) => _StepDraftRow(
                  index: index,
                  controller: steps[index],
                  onRemove: steps.length > 1
                      ? () => setState(() {
                            steps[index].dispose();
                            steps.removeAt(index);
                          })
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              _SectionAction(
                icon: Icons.add_rounded,
                label: 'Schritt hinzufügen',
                onPressed: () => setState(() => steps.add(TextEditingController())),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: AppDesign.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusXl)),
            ),
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            label: Text(saving ? 'Speichern …' : (editing ? 'Änderungen speichern' : 'Rezept speichern')),
          ),
        ),
      ),
    );
  }
}

class _RecipeFieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffixIcon;

  const _RecipeFieldCard({
    required this.icon,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppDesign.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppDesign.radiusXl),
        boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppDesign.primarySoft,
              borderRadius: BorderRadius.circular(AppDesign.radiusLg),
            ),
            child: Icon(icon, color: AppDesign.primaryDark, size: 28),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                suffixIcon: suffixIcon,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                labelStyle: const TextStyle(color: AppDesign.secondaryText, fontSize: 14, fontWeight: FontWeight.w600),
                floatingLabelStyle: const TextStyle(color: AppDesign.secondaryText, fontSize: 14, fontWeight: FontWeight.w600),
                hintStyle: const TextStyle(color: AppDesign.mutedText, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _RecipeSectionCard({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppDesign.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppDesign.radiusXl),
        boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppDesign.primarySoft, borderRadius: BorderRadius.circular(AppDesign.radiusMd)),
                child: Icon(icon, color: AppDesign.primaryDark),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppDesign.text)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SectionAction({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppDesign.primarySoft,
        foregroundColor: AppDesign.primaryDark,
        elevation: 0,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _StepDraftRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final VoidCallback? onRemove;

  const _StepDraftRow({required this.index, required this.controller, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppDesign.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 6),
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppDesign.primary, shape: BoxShape.circle),
            child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Zubereitungsschritt',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppDesign.primary, width: 1.5), borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Schritt entfernen',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppDesign.secondaryText,
            ),
        ],
      ),
    );
  }
}

class _IngredientDraft {
  final name = TextEditingController();
  final amount = TextEditingController(text: '1');
  final unit = TextEditingController();
  bool isQualitative = false;
  final section = TextEditingController();

  _IngredientDraft();

  _IngredientDraft.fromIngredient(RecipeIngredient ingredient) {
    name.text = ingredient.name;
    amount.text = ingredient.quantity.toString();
    unit.text = ingredient.unit;
    isQualitative = ingredient.isQualitative;
    section.text = ingredient.section ?? '';
  }

  RecipeIngredient toIngredient() => RecipeIngredient(
        name: name.text.trim(),
        quantity: num.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 1,
        unit: unit.text.trim(),
        isQualitative: isQualitative,
        section: section.text.trim().isEmpty ? null : section.text.trim(),
      );

  void dispose() {
    name.dispose();
    amount.dispose();
    unit.dispose();
    section.dispose();
  }
}

class _IngredientRow extends StatelessWidget {
  final _IngredientDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _IngredientRow({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppDesign.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: draft.name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Zutat',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppDesign.primary, width: 1.5), borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                  ),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Zutat entfernen',
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppDesign.secondaryText,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: draft.amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Menge',
                    hintText: 'z. B. 250 oder 0,5',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppDesign.primary, width: 1.5), borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.unit,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Einheit',
                    hintText: 'z. B. g, ml, Stück',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppDesign.primary, width: 1.5), borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.section,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Zutatenabschnitt (optional)',
              hintText: 'z. B. Teig, Füllung, Belag',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppDesign.primary, width: 1.5), borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMd))),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}
