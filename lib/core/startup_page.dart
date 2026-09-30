import 'package:flutter/material.dart';

import '../features/foods/food_onboarding_page.dart';
import '../data/repositories/profile_repository.dart';
import 'app_shell.dart';
import 'async_error.dart';

class StartupLoadResult {
  final bool onboardingCompleted;
  final Object? error;

  const StartupLoadResult({
    required this.onboardingCompleted,
    this.error,
  });
}

Future<StartupLoadResult> loadStartupData() async {
  try {
    final done = await ProfileRepository().onboardingCompleted();
    return StartupLoadResult(onboardingCompleted: done);
  } catch (caught) {
    return StartupLoadResult(onboardingCompleted: false, error: caught);
  }
}

class StartupPage extends StatefulWidget {
  final StartupLoadResult? initialResult;

  const StartupPage({super.key, this.initialResult});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool? completed;
  Object? error;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      final result = widget.initialResult!;
      completed = result.error == null ? result.onboardingCompleted : null;
      error = result.error;
    } else {
      check();
    }
  }

  Future<void> check() async {
    setState(() {
      completed = null;
      error = null;
    });
    try {
      final done = await ProfileRepository().onboardingCompleted();
      if (!mounted) return;
      setState(() => completed = done);
    } catch (caught) {
      if (!mounted) return;
      setState(() => error = caught);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        body: AppErrorView(
          error: error!,
          onRetry: check,
          title: 'Schmackofatz konnte nicht gestartet werden',
          message: 'Dein Profil konnte nicht geladen werden. Deine Daten wurden nicht verändert.',
        ),
      );
    }
    if (completed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return completed!
        ? const AppShell()
        : FoodOnboardingPage(onCompleted: () => setState(() => completed = true));
  }
}
