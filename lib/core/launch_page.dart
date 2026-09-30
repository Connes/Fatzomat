import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_design.dart';
import 'startup_page.dart';

/// Minimum time the launch screen remains visible before the app continues.
const kLaunchMinimumDuration = Duration(seconds: 4);

/// Cross-fade used when leaving the launch screen.
const kLaunchTransitionDuration = Duration(milliseconds: 350);

/// Resolves only after both startup data and the minimum visible launch time
/// have completed. The two operations intentionally run in parallel.
Future<StartupLoadResult> waitForLaunchReadiness({
  required Future<StartupLoadResult> startup,
  Duration minimumDuration = kLaunchMinimumDuration,
  Future<void> Function(Duration duration)? delay,
}) async {
  final minimum = (delay ?? Future<void>.delayed)(minimumDuration);
  final results = await Future.wait<Object?>([startup, minimum]);
  return results.first as StartupLoadResult;
}

/// Branded first screen based on the approved launch artwork.
///
/// It deliberately stays in Flutter instead of using a screenshot of a phone,
/// so the real system status bar remains visible and the layout scales cleanly
/// across Android and iOS devices.
class LaunchPage extends StatefulWidget {
  final Future<StartupLoadResult> Function()? startupLoader;
  final Duration minimumDuration;

  const LaunchPage({
    super.key,
    this.startupLoader,
    this.minimumDuration = kLaunchMinimumDuration,
  });

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _transitionStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // Start the readiness clock after the first frame, so the minimum visible
    // duration is measured from the point at which the launch page can actually
    // be rendered. Startup data and the minimum duration run in parallel.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      waitForLaunchReadiness(
        startup: (widget.startupLoader ?? loadStartupData)(),
        minimumDuration: widget.minimumDuration,
      ).then(_continue, onError: (Object error, StackTrace stackTrace) {
        if (!mounted || _transitionStarted) return;
        _transitionStarted = true;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (_, __, ___) => StartupPage(
              initialResult: StartupLoadResult(
                onboardingCompleted: false,
                error: error,
              ),
            ),
            transitionDuration: kLaunchTransitionDuration,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      });
    });
  }

  void _continue(StartupLoadResult result) {
    if (!mounted || _transitionStarted) return;
    _transitionStarted = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => StartupPage(initialResult: result),
        transitionDuration: kLaunchTransitionDuration,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppDesign.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppDesign.background,
        body: FadeTransition(
          opacity: _opacity,
          child: const _LaunchArtwork(),
        ),
      ),
    );
  }
}

class _LaunchArtwork extends StatelessWidget {
  const _LaunchArtwork();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomImageHeight = (size.height * 0.30).clamp(190.0, 300.0).toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppDesign.background),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomImageHeight,
          child: Image.asset(
            'assets/branding/launch_vegetables.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 4),
              Image.asset(
                'assets/branding/launch_heart.png',
                width: 92,
                height: 90,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 16),
              const Text(
                'Schmackofatz',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.6,
                  color: AppDesign.text,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Gutes Essen.\nGemeinsam einfacher.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: AppDesign.text,
                ),
              ),
              const Spacer(flex: 5),
            ],
          ),
        ),
      ],
    );
  }
}
