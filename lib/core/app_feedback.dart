import 'package:flutter/material.dart';

/// Centralizes short, transient feedback messages.
///
/// All transient SnackBars should be shown through [AppFeedback.showSnackBar]
/// so they share the same duration and block further touch input while visible.
class AppFeedback {
  AppFeedback._();

  static final ValueNotifier<int> _activeNotices = ValueNotifier<int>(0);

  static ValueListenable<bool> get inputBlocked =>
      _InputBlockedListenable(_activeNotices);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showSnackBar(
    BuildContext context,
    SnackBar snackBar,
  ) {
    _activeNotices.value++;
    final controller = ScaffoldMessenger.of(context).showSnackBar(
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
    controller.closed.whenComplete(() {
      if (_activeNotices.value > 0) _activeNotices.value--;
    });
    return controller;
  }
}

class _InputBlockedListenable extends ValueListenable<bool> {
  _InputBlockedListenable(this._count);

  final ValueListenable<int> _count;

  @override
  bool get value => _count.value > 0;

  @override
  void addListener(VoidCallback listener) => _count.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _count.removeListener(listener);
}
