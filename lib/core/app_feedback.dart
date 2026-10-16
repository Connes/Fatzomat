import 'package:flutter/material.dart';

/// Centralizes short, transient feedback messages.
///
/// All transient SnackBars should be shown through [AppFeedback.showSnackBar]
/// so they share the same duration and block further touch input while visible.
class AppFeedback {
  AppFeedback._();

  static final ValueNotifier<int> activeNotices = ValueNotifier<int>(0);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showSnackBar(
    BuildContext context,
    SnackBar snackBar,
  ) {
    activeNotices.value++;
    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
        controller;
    try {
      controller = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: snackBar.content,
          action: snackBar.action,
          backgroundColor: snackBar.backgroundColor,
          behavior: snackBar.behavior,
          dismissDirection: snackBar.dismissDirection,
          elevation: snackBar.elevation,
          margin: snackBar.margin,
          padding: snackBar.padding,
          shape: snackBar.shape,
          width: snackBar.width,
          animation: snackBar.animation,
          onVisible: snackBar.onVisible,
          showCloseIcon: snackBar.showCloseIcon,
          closeIconColor: snackBar.closeIconColor,
          clipBehavior: snackBar.clipBehavior,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      activeNotices.value--;
      rethrow;
    }
    controller.closed.whenComplete(() {
      if (activeNotices.value > 0) activeNotices.value--;
    });
    return controller;
  }
}
