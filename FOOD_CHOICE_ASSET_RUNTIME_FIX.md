# Food-Choice Asset Runtime Fix

## Root cause

`pubspec.yaml` registered only the parent directory:

```yaml
- assets/food_choices/
```

Flutter asset directory declarations are not recursive. The 18 new PNG files are located one level deeper in `cooking/`, `delivery/`, and `restaurant/`, so those files were present in the source project but were not included by the Flutter asset bundle.

The existing `Überrasch mich` image worked because `assets/together/clean/icons/` is registered directly and `icon_surprise.png` is directly inside that registered directory.

## Fix

The three actual asset directories are now registered explicitly:

```yaml
- assets/food_choices/cooking/
- assets/food_choices/delivery/
- assets/food_choices/restaurant/
```

No FoodMode, Today, Connection, Supabase, RLS, RPC, discovery, or decision logic was changed.

## Regression protection

`test/regression/food_mode_selection_visual_test.dart` now also loads every mapped Food-Choice asset through Flutter's `rootBundle` and asserts that the asset has non-zero content. This tests the asset-bundle/runtime path rather than merely checking that an `Image` widget exists.

## Source validation

All 18 new files were present in the project and validated as PNG images with dimensions 540x480 and RGBA pixel data.
