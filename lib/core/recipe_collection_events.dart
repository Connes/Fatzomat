import 'package:flutter/foundation.dart';

/// Lightweight in-process signal for changes to the current user's saved
/// recipe collection.
///
/// Supabase Realtime remains the source of truth, but local writes should be
/// reflected immediately even when the Postgres Changes event arrives later.
class RecipeCollectionEvents {
  RecipeCollectionEvents._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notifyChanged() {
    revision.value++;
  }
}
