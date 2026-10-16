import 'package:flutter/material.dart';

import 'app_design.dart';
import 'app_feedback.dart';
import 'launch_page.dart';
import 'push_notification_service.dart';

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schmackofatz',
      debugShowCheckedModeBanner: false,
      theme: AppDesign.theme(),
      navigatorKey: appNavigatorKey,
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: AppFeedback.activeNotices,
        builder: (context, activeNotices, _) => AbsorbPointer(
          absorbing: activeNotices > 0,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const LaunchPage(),
    );
  }
}
