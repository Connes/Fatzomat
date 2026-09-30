# V68 Asset Cleanup

The Together asset tree was reduced to assets that are currently referenced by the app.

## Kept
- `assets/together/clean/icons/icon_cooking.png`
- `assets/together/clean/icons/icon_delivery.png`
- `assets/together/clean/icons/icon_restaurant.png`
- `assets/together/clean/icons/icon_surprise.png`
- `assets/together/clean/decorations/decoration_top_right.png`
- `assets/together/clean/decorations/decoration_bottom_left.png`

The launch screen and shared branding continue to use the existing `assets/branding/` files.

## Removed
Old duplicate Together icon, ingredient, background, branding and UI reference sets were removed from `assets/together/`. Unused color PNG references were removed from `pubspec.yaml`; UI colors remain code-driven.

## Verification
The cleanup intentionally leaves no stale Together asset directories in the Flutter asset manifest. Run `./setup.sh` to regenerate platform files, launcher icons, dependencies, analyzer results and tests.
