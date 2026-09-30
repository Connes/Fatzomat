import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/recipe.dart';
import '../models/together_recipe_importer.dart';

/// Small platform boundary for recipe JSON files.
///
/// Keeping file_picker here means the feature pages only deal with recipes,
/// not with native URI/path details.
class TogetherRecipeFileService {
  const TogetherRecipeFileService();

  Future<Recipe?> pickRecipe() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return const TogetherRecipeImporter().parse(await readText(file));
  }

  Future<bool> saveRecipe(Recipe recipe, {int? servings}) async {
    final exportRecipe = servings == null ? recipe : recipe.scaledTo(servings);
    final jsonText = const JsonEncoder.withIndent('  ').convert(exportRecipe.toTogetherRecipeJson());
    final filename = _safeFilename(exportRecipe.name);
    final path = await FilePicker.saveFile(
      dialogTitle: 'Rezeptdatei speichern',
      fileName: filename,
      bytes: Uint8List.fromList(utf8.encode(jsonText)),
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return path != null;
  }

  String _safeFilename(String name) {
    final cleaned = name
        .trim()
        .replaceAll(RegExp(r'[\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final base = cleaned.isEmpty ? 'schmackofatz_rezept' : cleaned;
    return '$base.json';
  }

  Future<String> readText(PlatformFile file) async {
    const maxBytes = TogetherRecipeImporter.maxSourceBytes;
    final length = await file.length();
    if (length != null && length > maxBytes) {
      throw const TogetherRecipeImportException(
        'Die Rezeptdatei ist zu groß. Maximal 1 MB ist erlaubt.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        throw const TogetherRecipeImportException(
          'Die Rezeptdatei ist zu groß. Maximal 1 MB ist erlaubt.',
        );
      }
      return utf8.decode(bytes);
    } on FormatException {
      throw const TogetherRecipeImportException(
        'Die ausgewählte Datei ist keine gültige UTF-8-JSON-Datei.',
      );
    } on TogetherRecipeImportException {
      rethrow;
    } catch (_) {
      throw const TogetherRecipeImportException(
        'Die ausgewählte Datei konnte nicht gelesen werden.',
      );
    }
  }
}
