import 'package:flutter/material.dart';

import 'app_design.dart';
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
      home: const LaunchPage(),
    );
  }
}
