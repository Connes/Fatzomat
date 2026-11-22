import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/recipe.dart';
import 'recipe_image_service.dart';

/// Builds the visual cover and the plain-text companion message used when a
/// recipe is shared to WhatsApp or another messaging app.
class RecipeShareCardService {
  const RecipeShareCardService();

  static const int _width = 1080;
  static const int _height = 1080;

  Future<Uint8List> buildCover(Recipe recipe) async {
    final photo = await _loadRecipeImage(recipe);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = const Rect.fromLTWH(0, 0, 1080.0, 1080.0);

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8ED), Color(0xFFF3E8D7)],
        ).createShader(bounds),
    );

    final photoRect = const Rect.fromLTWH(0, 0, 1080.0, 720);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(photoRect, const Radius.circular(0)));
    if (photo != null) {
      final source = _coverSourceRect(photo, photoRect.size);
      canvas.drawImageRect(photo, source, photoRect, Paint()..filterQuality = FilterQuality.high);
    } else {
      canvas.drawRect(
        photoRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF476C42), Color(0xFF172F25)],
          ).createShader(photoRect),
      );
      _drawText(canvas, 'FATZOMAT', const Offset(72, 110), 44, Colors.white, bold: true);
    }

    canvas.drawRect(
      photoRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xCC10251C)],
          stops: [0.38, 1],
        ).createShader(photoRect),
    );
    _drawText(
      canvas,
      recipe.name.trim().isEmpty ? 'Leckeres Rezept' : recipe.name.trim(),
      const Offset(64, 485),
      76,
      Colors.white,
      bold: true,
      maxWidth: 950,
      maxLines: 2,
    );
    canvas.restore();
    photo?.dispose();

    // Warm paper-like footer and metadata.
    canvas.drawRect(const Rect.fromLTWH(0, 720, 1080.0, 360), Paint()..color = const Color(0xFFFFF8ED));
    _drawCenteredText(canvas, recipe.name.trim().isEmpty ? 'Leckeres Rezept' : recipe.name.trim(), const Rect.fromLTWH(64, 770, 952, 100), 46, const Color(0xFF1D3829), bold: true, maxLines: 2);
    final total = recipe.prepTimeMinutes + recipe.cookTimeMinutes;
    final meta = [
      if (recipe.servings > 0) '${recipe.servings} ${recipe.servingsUnit}',
      if (total > 0) '${total} Min.',
      _difficulty(recipe.difficulty),
    ].where((value) => value.trim().isNotEmpty).join('   •   ');
    _drawText(canvas, meta, const Offset(64, 890), 42, const Color(0xFF1D3829), bold: true, maxWidth: 950, maxLines: 2);

    final picture = recorder.endRecording();
    final image = await picture.toImage(_width, _height);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw StateError('Die Rezeptgrafik konnte nicht erstellt werden.');
    }
    return data.buffer.asUint8List();
  }

  String buildRecipeText(Recipe recipe) {
    final sections = <String, List<RecipeIngredient>>{};
    for (final ingredient in recipe.ingredients) {
      final section = ingredient.section?.trim();
      sections.putIfAbsent(
        section == null || section.isEmpty ? 'Weitere Zutaten' : section,
        () => <RecipeIngredient>[],
      ).add(ingredient);
    }
    final ingredientText = sections.entries.map((entry) {
      final lines = entry.value.map((ingredient) {
        final amount = ingredient.hidesQuantity
            ? ''
            : '${_formatQuantity(ingredient.quantity)} ${ingredient.unit.trim()}'.trim();
        final value = amount.isEmpty ? ingredient.name : '$amount ${ingredient.name}';
        return _formatBulletItem(value);
      }).join('\n');
      return '${entry.key}:\n$lines';
    }).join('\n\n');
    final steps = recipe.instructions.asMap().entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');

    return [
      if (ingredientText.isNotEmpty) '*Zutaten*\n\n$ingredientText',
      if (steps.isNotEmpty) '*Zubereitung*\n\n$steps',
    ].join('\n\n');
  }


  String _formatBulletItem(String value) {
    const continuationIndent = '  ';
    const maxLineLength = 30;
    final words = value.split(RegExp(r'\\s+'));
    final lines = <String>[];
    var line = '•';
    for (final word in words) {
      final candidate = line == '•' ? '$line $word' : '$line $word';
      if (line != '•' && candidate.length > maxLineLength) {
        lines.add(line);
        line = '$continuationIndent$word';
      } else {
        line = candidate;
      }
    }
    lines.add(line);
    return lines.join('\\n');
  }

  void _drawCenteredText(
    Canvas canvas,
    String value,
    Rect bounds,
    double fontSize,
    Color color, {
    bool bold = false,
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontFamily: 'Inter',
          height: 1.12,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: bounds.width);
    painter.paint(canvas, Offset(bounds.left, bounds.top + (bounds.height - painter.height) / 2));
    painter.dispose();
  }

  Future<ui.Image?> _loadRecipeImage(Recipe recipe) async {
    Uint8List? bytes;
    final path = recipe.imagePath?.trim() ?? '';
    if (path.isNotEmpty) {
      try {
        bytes = await RecipeImageService().download(path);
      } catch (_) {
        // Older/imported recipes may only have a resolved URL.
      }
    }
    final url = recipe.imageUrl?.trim() ?? '';
    if ((bytes == null || bytes.isEmpty) && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
        try {
          final data = await NetworkAssetBundle(uri).load(uri.toString());
          bytes = data.buffer.asUint8List();
        } catch (_) {
          // A missing image must not prevent sharing the recipe itself.
        }
      }
    }
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: _width);
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Rect _coverSourceRect(ui.Image image, Size target) {
    final imageRatio = image.width / image.height;
    final targetRatio = target.width / target.height;
    if (imageRatio > targetRatio) {
      final width = image.height * targetRatio;
      return Rect.fromLTWH((image.width - width) / 2, 0, width, image.height.toDouble());
    }
    final height = image.width / targetRatio;
    return Rect.fromLTWH(0, (image.height - height) / 2, image.width.toDouble(), height);
  }

  void _drawText(
    Canvas canvas,
    String value,
    Offset offset,
    double fontSize,
    Color color, {
    bool bold = false,
    double letterSpacing = 0,
    double maxWidth = 950,
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontFamily: 'Inter',
          letterSpacing: letterSpacing,
          height: 1.12,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
    painter.dispose();
  }

  String _difficulty(String value) => switch (value.toLowerCase()) {
        'easy' || 'einfach' => 'Einfach',
        'medium' || 'mittel' => 'Mittel',
        'hard' || 'schwer' => 'Schwer',
        _ => value,
      };

  String _formatQuantity(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
