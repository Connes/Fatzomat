import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'together_background.dart';
import '../app_design.dart';


/// Consistent app bar for all navigable subpages.
/// The page title is always centered; Flutter supplies the back button when
/// the current route can be popped.
class TogetherAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const TogetherAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? AppDesign.surface,
      systemOverlayStyle: systemOverlayStyle ?? const SystemUiOverlayStyle(
        statusBarColor: AppDesign.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      actions: [if (actions != null) ...actions!, const SizedBox(width: 8)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Scaffold variant that places the screen-specific together background behind
/// the page content while keeping the existing Scaffold API used by the app.
class TogetherScaffold extends StatelessWidget {
  final TogetherBackgroundType backgroundType;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool respectTopSafeArea;
  final Color? topSafeAreaColor;

  const TogetherScaffold({
    super.key,
    required this.backgroundType,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.respectTopSafeArea = false,
    this.topSafeAreaColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: TogetherBackground(
        type: backgroundType,
        respectTopSafeArea: respectTopSafeArea,
        topSafeAreaColor: topSafeAreaColor,
        child: body ?? const SizedBox.shrink(),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
    );
  }
}
