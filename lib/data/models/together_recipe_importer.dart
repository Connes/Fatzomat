import 'dart:convert';

import 'recipe.dart';

class TogetherRecipeImportException implements Exception {
  final String message;
  const TogetherRecipeImportException(this.message);

  @override
  String toString() => message;
}

/// Parser for the stable, AI-agnostic `together_recipe` interchange format.
///
/// The parser deliberately applies conservative size limits because the input
/// can originate outside the app. A null amount is accepted for qualitative
/// quantities such as "Salz, Prise". The numeric storage value remains 1,
/// while `isQualitative` preserves the original semantic meaning.
class TogetherRecipeImporter {
  const TogetherRecipeImporter();

  static const maxSourceBytes = 1024 * 1024;
  static const maxIngredients = 50;
  static const maxSteps = 50;
  static const maxTitleLength = 120;
  static const maxDescriptionLength = 2000;
  static const maxIngredientNameLength = 200;
  static const maxUnitLength = 40;
  static const maxSectionLength = 80;
  static const maxStepLength = 1500;

  static String _normalizeUnit(String unit) {
    final normalized = unit.trim().toLowerCase();
    if (normalized == 'stück' || normalized == 'stueck' || normalized == 'stk.' || normalized == 'stk') {
      return '';
    }
    return unit.trim();
  }

  Recipe parse(String source) {
    if (source.isEmpty) {
      throw const TogetherRecipeImportException(
        'Die Rezeptdatei ist leer.',
      );
    }
    if (utf8.encode(source).length > maxSourceBytes) {
      throw const TogetherRecipeImportException(
        'Die Rezeptdatei ist zu groß. Maximal 1 MB ist erlaubt.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const TogetherRecipeImportException(
        'Die Rezeptdatei enthält kein gültiges JSON.',
      );
    }

    if (decoded is! Map) {
      throw const TogetherRecipeImportException(
        'Die Rezeptdatei muss ein JSON-Objekt enthalten.',
      );
    }

    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != 'together_recipe') {
      throw const TogetherRecipeImportException(
        'Unbekanntes Rezeptformat. Erwartet wird „together_recipe“.',
      );
    }

    final version = root['version'];
    if (version != 1) {
      throw TogetherRecipeImportException(
        'Nicht unterstützte Rezeptformat-Version: ${version ?? 'unbekannt'}.',
      );
    }

    final recipeRaw = root['recipe'];
    if (recipeRaw is! Map) {
      throw const TogetherRecipeImportException(
        'Die Rezeptdatei enthält keinen gültigen Rezeptbereich.',
      );
    }

    final recipe = Map<String, dynamic>.from(recipeRaw);
    final title = recipe['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      throw const TogetherRecipeImportException(
        'Das Rezept benötigt einen Titel.',
      );
    }
    if (title.length > maxTitleLength) {
      throw const TogetherRecipeImportException(
        'Der Rezepttitel ist zu lang.',
      );
    }

    final description = recipe['description']?.toString().trim() ?? '';
    if (description.length > maxDescriptionLength) {
      throw const TogetherRecipeImportException(
        'Die Rezeptbeschreibung ist zu lang.',
      );
    }

    final ingredientsRaw = recipe['ingredients'];
    final stepsRaw = recipe['steps'];
    if (ingredientsRaw is! List || stepsRaw is! List) {
      throw const TogetherRecipeImportException(
        'Zutaten und Zubereitung müssen als Listen vorliegen.',
      );
    }
    if (ingredientsRaw.isEmpty) {
      throw const TogetherRecipeImportException(
        'Das Rezept benötigt mindestens eine Zutat.',
      );
    }
    if (ingredientsRaw.length > maxIngredients) {
      throw const TogetherRecipeImportException(
        'Das Rezept enthält zu viele Zutaten. Maximal 50 sind erlaubt.',
      );
    }
    if (stepsRaw.isEmpty) {
      throw const TogetherRecipeImportException(
        'Das Rezept benötigt mindestens einen Zubereitungsschritt.',
      );
    }
    if (stepsRaw.length > maxSteps) {
      throw const TogetherRecipeImportException(
        'Das Rezept enthält zu viele Zubereitungsschritte. Maximal 50 sind erlaubt.',
      );
    }

    final ingredients = <RecipeIngredient>[];
    for (var index = 0; index < ingredientsRaw.length; index++) {
      final raw = ingredientsRaw[index];
      if (raw is! Map) {
        throw TogetherRecipeImportException(
          'Zutat ${index + 1} ist ungültig.',
        );
      }
      final item = Map<String, dynamic>.from(raw);
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty) {
        throw TogetherRecipeImportException(
          'Zutat ${index + 1} hat keinen Namen.',
        );
      }
      if (name.length > maxIngredientNameLength) {
        throw TogetherRecipeImportException(
          'Der Name von Zutat ${index + 1} ist zu lang.',
        );
      }

      final hasAmount = item.containsKey('amount') || item.containsKey('quantity');
      final rawAmount = item.containsKey('amount') ? item['amount'] : item['quantity'];
      final isQualitative = hasAmount && rawAmount == null;
      final quantity = _number(rawAmount) ?? (isQualitative ? 1 : null);
      if (quantity == null || quantity <= 0) {
        throw TogetherRecipeImportException(
          'Zutat „$name“ hat keine gültige Menge. Verwende eine positive Zahl oder null für qualitative Mengen.',
        );
      }
      if (quantity > 100000) {
        throw TogetherRecipeImportException(
          'Die Menge von Zutat „$name“ ist unrealistisch groß.',
        );
      }

      final rawUnit = item['unit']?.toString().trim() ?? '';
      final unit = _normalizeUnit(rawUnit);
      final sectionRaw = item['section']?.toString().trim() ?? '';
      if (sectionRaw.length > maxSectionLength) {
        throw TogetherRecipeImportException(
          'Der Zutatenabschnitt von „$name“ ist zu lang.',
        );
      }
      final section = sectionRaw.isEmpty ? null : sectionRaw;
      if (unit.length > maxUnitLength) {
        throw TogetherRecipeImportException(
          'Die Einheit von Zutat „$name“ ist zu lang.',
        );
      }

      ingredients.add(
        RecipeIngredient(
          foodId: item['food_id']?.toString(),
          name: name,
          quantity: quantity,
          unit: unit,
          isUserSelected: item['is_user_selected'] == true,
          isAdditional: item['is_additional'] == true,
          isQualitative: isQualitative || item['is_qualitative'] == true,
          section: section,
        ),
      );
    }

    final steps = <String>[];
    for (var index = 0; index < stepsRaw.length; index++) {
      final value = stepsRaw[index]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw TogetherRecipeImportException(
          'Zubereitungsschritt ${index + 1} ist leer.',
        );
      }
      if (value.length > maxStepLength) {
        throw TogetherRecipeImportException(
          'Zubereitungsschritt ${index + 1} ist zu lang.',
        );
      }
      steps.add(value);
    }

    final imageUrl = recipe['image_url']?.toString().trim();
    if (imageUrl != null && imageUrl.length > 2000) {
      throw const TogetherRecipeImportException(
        'Die Bildreferenz des Rezepts ist zu lang.',
      );
    }

    return Recipe(
      name: title,
      description: description,
      servings: _positiveInt(recipe['servings']) ?? 1,
      prepTimeMinutes: _nonNegativeInt(recipe['prep_time_minutes'] ?? recipe['prepTimeMinutes']) ?? 0,
      cookTimeMinutes: _nonNegativeInt(recipe['cook_time_minutes'] ?? recipe['cookTimeMinutes']) ?? 0,
      difficulty: recipe['difficulty']?.toString().trim().isNotEmpty == true
          ? recipe['difficulty'].toString().trim()
          : 'Einfach',
      instructions: steps,
      ingredients: ingredients,
      imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
    );
  }

  static num? _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString().replaceAll(',', '.') ?? '');
  }

  static int? _positiveInt(dynamic value) {
    final n = _nonNegativeInt(value);
    return n != null && n > 0 ? n : null;
  }

  static int? _nonNegativeInt(dynamic value) {
    final n = _number(value);
    if (n == null || n < 0 || n > 1440) return null;
    return n.round();
  }
}
