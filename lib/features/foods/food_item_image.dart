import 'package:flutter/material.dart';

/// Kept as a compatibility shim for existing food rows.
///
/// Food items are intentionally text-only: this widget renders no emoji,
/// image asset, icon, or placeholder graphic.
class FoodItemImage extends StatelessWidget {
  final String foodName;
  final String? category;
  final double size;

  const FoodItemImage({
    super.key,
    required this.foodName,
    this.category,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
