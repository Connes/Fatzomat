import 'package:flutter/material.dart';

/// Identifies the visual background family used by a screen.
///
/// The home screen is intentionally part of this system so all screens use the
/// same background API. Its existing photo is kept unchanged.
enum TogetherBackgroundType {
  home,
  recipes,
  recipeDetail,
  today,
  decision,
  decisionResult,
  notifications,
  notificationDetail,
  profile,
  profileEdit,
  settings,
  help,
  legal,
  login,
  register,
  passwordReset,
  error,
  offline,
  empty,
  search,
  filter,
  share,
  about,
  update,
}

abstract final class TogetherBackgroundAssets {
  static const _root = 'assets/together/clean/background';

  static String assetFor(TogetherBackgroundType type) {
    switch (type) {
      case TogetherBackgroundType.home:
        return '$_root/home_photo_background.png';
      case TogetherBackgroundType.recipes:
        return '$_root/recipes_background.png';
      case TogetherBackgroundType.recipeDetail:
        return '$_root/recipe_detail_background.png';
      case TogetherBackgroundType.today:
        return '$_root/today_background.png';
      case TogetherBackgroundType.decision:
        return '$_root/decision_background.png';
      case TogetherBackgroundType.decisionResult:
        return '$_root/decision_result_background.png';
      case TogetherBackgroundType.notifications:
        return '$_root/notifications_background.png';
      case TogetherBackgroundType.notificationDetail:
        return '$_root/notification_detail_background.png';
      case TogetherBackgroundType.profile:
        return '$_root/profile_background.png';
      case TogetherBackgroundType.profileEdit:
        return '$_root/profile_edit_background.png';
      case TogetherBackgroundType.settings:
        return '$_root/settings_background.png';
      case TogetherBackgroundType.help:
        return '$_root/help_background.png';
      case TogetherBackgroundType.legal:
        return '$_root/legal_background.png';
      case TogetherBackgroundType.login:
        return '$_root/login_background.png';
      case TogetherBackgroundType.register:
        return '$_root/register_background.png';
      case TogetherBackgroundType.passwordReset:
        return '$_root/password_reset_background.png';
      case TogetherBackgroundType.error:
        return '$_root/error_background.png';
      case TogetherBackgroundType.offline:
        return '$_root/offline_background.png';
      case TogetherBackgroundType.empty:
        return '$_root/empty_background.png';
      case TogetherBackgroundType.search:
        return '$_root/search_background.png';
      case TogetherBackgroundType.filter:
        return '$_root/filter_background.png';
      case TogetherBackgroundType.share:
        return '$_root/share_background.png';
      case TogetherBackgroundType.about:
        return '$_root/about_background.png';
      case TogetherBackgroundType.update:
        return '$_root/update_background.png';
    }
  }
}

/// Shared background shell for all together screens.
///
/// The background is deliberately non-interactive and sits behind the screen
/// content. A subtle overlay can be enabled where a screen needs additional
/// text contrast without changing the source artwork.
class TogetherBackground extends StatelessWidget {
  final TogetherBackgroundType type;
  final Widget child;
  final bool showOverlay;
  final double overlayOpacity;
  final Alignment alignment;
  final BoxFit fit;
  /// Keeps the system status-bar area outside the artwork while preserving
  /// the existing background for the rest of the screen.
  final bool respectTopSafeArea;
  final Color? topSafeAreaColor;

  const TogetherBackground({
    super.key,
    required this.type,
    required this.child,
    this.showOverlay = true,
    this.overlayOpacity = 0.16,
    this.alignment = Alignment.topCenter,
    this.fit = BoxFit.cover,
    this.respectTopSafeArea = false,
    this.topSafeAreaColor,
  });

  @override
  Widget build(BuildContext context) {
    assert(overlayOpacity >= 0 && overlayOpacity <= 1);

    final topInset = respectTopSafeArea
        ? MediaQuery.viewPaddingOf(context).top
        : 0.0;
    final safeAreaColor =
        topSafeAreaColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (respectTopSafeArea) ColoredBox(color: safeAreaColor),
        Positioned(
          top: topInset,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Image.asset(
              TogetherBackgroundAssets.assetFor(type),
              fit: fit,
              alignment: alignment,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        ),
        if (showOverlay)
          IgnorePointer(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: overlayOpacity),
            ),
          ),
        child,
      ],
    );
  }
}
