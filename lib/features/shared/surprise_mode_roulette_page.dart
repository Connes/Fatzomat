import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/food_mode.dart';
import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';

class SurpriseModeRoulettePage extends StatefulWidget {
  const SurpriseModeRoulettePage({super.key});

  @override
  State<SurpriseModeRoulettePage> createState() =>
      _SurpriseModeRoulettePageState();
}

class _SurpriseModeRoulettePageState extends State<SurpriseModeRoulettePage>
    with TickerProviderStateMixin {
  static const _modes = <FoodMode>[
    FoodMode.cook,
    FoodMode.order,
    FoodMode.dineOut,
  ];

  static const _labels = <FoodMode, String>{
    FoodMode.cook: 'Wir kochen',
    FoodMode.order: 'Wir bestellen',
    FoodMode.dineOut: 'Wir gehen essen',
  };

  static const _categoryAssets = <String>[
    'assets/together/clean/icons/icon_cooking.png',
    'assets/together/clean/icons/icon_delivery.png',
    'assets/together/clean/icons/icon_restaurant.png',
  ];

  static const _gold = AppDesign.iconGold;
  static const _deepRed = Color(0xFFF7F2E8);
  static const _tileExtent = 116.0;
  static const _reelHeight = 200.0;

  late final List<AnimationController> _reels;
  late final AnimationController _celebration;
  bool _spinning = true;
  bool _stopping = false;
  bool _finished = false;
  int _stoppedReels = 0;
  int? _resultIndex;

  FoodMode? get _resultMode =>
      _resultIndex == null ? null : _modes[_resultIndex!];

  @override
  void initState() {
    super.initState();
    _celebration = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _reels = List<AnimationController>.generate(
      3,
      (index) => AnimationController.unbounded(
        vsync: this,
        value: index.toDouble(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var index = 0; index < _reels.length; index++) {
        precacheImage(AssetImage(_categoryAssets[index]), context);
      }
      _startSpinning();
    });
  }

  void _startSpinning() {
    for (var index = 0; index < _reels.length; index++) {
      final controller = _reels[index];
      final velocity = 11.5 + index * 1.1;
      unawaited(
        controller
            .animateWith(_ConstantVelocitySimulation(
              controller.value,
              velocity,
            ))
            .orCancel
            .catchError((Object _) {}),
      );
    }
  }

  Future<void> _stopRoulette() async {
    if (_stopping || !_spinning) return;

    final winner = math.Random().nextInt(_modes.length);
    setState(() {
      _stopping = true;
      _resultIndex = winner;
    });

    // Stop reels in sequence, with the entire sequence capped at 900 ms.
    final startedAt = DateTime.now();
    for (var index = 0; index < _reels.length; index++) {
      if (!mounted) return;
      final controller = _reels[index];
      final current = controller.value;
      final firstLanding = current.ceil() + 2;
      final alignment =
          (winner - (firstLanding % _modes.length) + _modes.length) %
              _modes.length;
      final target = (firstLanding + alignment).toDouble();
      final elapsed = DateTime.now().difference(startedAt);
      final remainingMs = 900 - elapsed.inMilliseconds;
      final reelsRemaining = _reels.length - index;
      final durationMs = (remainingMs / reelsRemaining).floor().clamp(80, 320);

      await controller.animateTo(
        target,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutQuart,
      );
      if (!mounted) return;
      setState(() => _stoppedReels = index + 1);
    }

    if (!mounted) return;
    setState(() {
      _spinning = false;
      _stopping = false;
      _finished = true;
    });
    _celebration.forward(from: 0);
  }

  void _spinAgain() {
    _celebration.stop();
    _celebration.reset();
    setState(() {
      _spinning = true;
      _stopping = false;
      _finished = false;
      _stoppedReels = 0;
      _resultIndex = null;
    });
    _startSpinning();
  }

  @override
  void dispose() {
    _celebration.dispose();
    for (final reel in _reels) {
      reel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _resultMode;
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.decisionResult,
      appBar: TogetherAppBar(title: const Text('Überrasch mich')),
      body: Stack(
        children: [
          SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            const SizedBox(height: 4),
            _buildSlotMachine(context),
            const SizedBox(height: 22),
            if (_finished && result != null)
              _buildWinner(context, result),
            const SizedBox(height: 18),
            if (_finished && result != null) ...[
              FilledButton.icon(
                onPressed: _spinAgain,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('NOCHMAL DREHEN'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFCF5),
                  foregroundColor: AppDesign.primaryDark,
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _gold, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, result),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('WEITER MIT „${_labels[result]}“'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFCF5),
                  foregroundColor: AppDesign.primaryDark,
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _gold, width: 1.5),
                  ),
                ),
              ),
            ] else
              FilledButton.icon(
                // Keep the button's appearance unchanged while the reels stop.
                // _stopRoulette ignores additional taps while _stopping is true.
                onPressed: _spinning ? _stopRoulette : null,
                icon: const Icon(Icons.stop_circle_rounded),
                label: const Text('STOPP'),
                style: FilledButton.styleFrom(
                  backgroundColor: _deepRed,
                  foregroundColor: _gold,
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _gold, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
          ),
          if (_finished)
            Positioned.fill(
              child: IgnorePointer(child: _buildJackpotCelebration()),
            ),
        ],
      ),
    );
  }

  Widget _buildJackpotCelebration() {
    return AnimatedBuilder(
      animation: _celebration,
      builder: (context, _) => CustomPaint(
        painter: _JackpotParticlePainter(_celebration.value),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildSlotMachine(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFCF5),
            Color(0xFFF7F2E8),
            Color(0xFFEFE5D2),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: _deepRed.withValues(alpha: .28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          const BoxShadow(
            color: Color(0x66FFFFFF),
            blurRadius: 2,
            spreadRadius: -1,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: _gold, size: 17),
              const SizedBox(width: 8),
              Text(
                'FATZOMAT',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _gold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: _gold, size: 17),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppDesign.iconGold, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: List<Widget>.generate(3, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == 2 ? 0 : 4,
                    ),
                    child: _CasinoReel(
                      controller: _reels[index],
                      stopped: index < _stoppedReels,
                      tileExtent: _tileExtent,
                      reelHeight: _reelHeight,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(3, (index) {
              final isStopped = index < _stoppedReels;
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStopped ? _gold : const Color(0xFF966A46),
                  boxShadow: isStopped
                      ? [
                          const BoxShadow(
                            color: _gold,
                            blurRadius: 7,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildWinner(BuildContext context, FoodMode mode) {
    final index = _modes.indexOf(mode);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .72, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFCF5),
                  Color(0xFFF7F2E8),
                  Color(0xFFEFE5D2),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _gold, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: .34),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: _deepRed.withValues(alpha: .32),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'EURE GEWINNER-KATEGORIE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFB98736),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    _categoryAssets[index],
                    height: 112,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: -12,
            left: 12,
            child: Icon(Icons.auto_awesome, color: _gold, size: 28),
          ),
          const Positioned(
            top: 4,
            right: 8,
            child: Icon(Icons.star_rounded, color: _gold, size: 26),
          ),
          const Positioned(
            bottom: -8,
            left: 28,
            child: Icon(Icons.star_rounded, color: _gold, size: 22),
          ),
          const Positioned(
            bottom: 0,
            right: 20,
            child: Icon(Icons.auto_awesome, color: _gold, size: 24),
          ),
        ],
      ),
    );
  }
}

class _CasinoReel extends StatelessWidget {
  final AnimationController controller;
  final bool stopped;
  final double tileExtent;
  final double reelHeight;

  const _CasinoReel({
    required this.controller,
    required this.stopped,
    required this.tileExtent,
    required this.reelHeight,
  });

  static const _assets = _SurpriseModeRoulettePageState._categoryAssets;
  static const _gold = _SurpriseModeRoulettePageState._gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: reelHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stopped ? _gold : const Color(0xFFD8C9A8),
          width: stopped ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final value = controller.value;
            final whole = value.floor();
            final fraction = value - whole;
            final center = (reelHeight - tileExtent) / 2;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (var relative = -2; relative <= 2; relative++)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: center + (relative - fraction) * tileExtent,
                    height: tileExtent,
                    child: _ReelSymbol(
                      asset: _assets[((whole + relative) % 3 + 3) % 3],
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: center,
                  height: tileExtent,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: _gold.withValues(alpha: .88),
                            width: 2,
                          ),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _gold.withValues(alpha: .05),
                            Colors.transparent,
                            _gold.withValues(alpha: .05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: center + tileExtent / 2 - 7,
                  left: 0,
                  child: const Icon(
                    Icons.arrow_right_rounded,
                    color: _gold,
                    size: 20,
                  ),
                ),
                Positioned(
                  top: center + tileExtent / 2 - 7,
                  right: 0,
                  child: const Icon(
                    Icons.arrow_left_rounded,
                    color: _gold,
                    size: 20,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReelSymbol extends StatelessWidget {
  final String asset;

  const _ReelSymbol({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF34262B), Color(0xFF171014)],
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Image.asset(
            asset,
            width: 78,
            height: 78,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _JackpotParticlePainter extends CustomPainter {
  _JackpotParticlePainter(this.progress);
  final double progress;
  static const _gold = Color(0xFFFFD779);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(23);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 100; i++) {
      final startX = random.nextDouble() * size.width;
      final drift = (random.nextDouble() - 0.5) * 110;
      final startY = -random.nextDouble() * size.height * 0.45;
      final y = startY + progress * (size.height * 1.65);
      final x = startX + drift * progress;
      if (y < -12 || y > size.height + 12) continue;
      final fade = (1 - progress * 0.72).clamp(0.0, 1.0);
      paint.color = i.isEven ? _gold.withValues(alpha: fade) : Colors.white.withValues(alpha: fade * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 8 + i);
      if (i % 3 == 0) {
        final path = Path()..moveTo(0, -7)..lineTo(3, 0)..lineTo(0, 7)..lineTo(-3, 0)..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: i.isEven ? 5 : 3, height: i.isEven ? 10 : 6), const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _JackpotParticlePainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConstantVelocitySimulation extends Simulation {
  final double start;
  final double velocity;

  _ConstantVelocitySimulation(this.start, this.velocity);

  @override
  double x(double time) => start + velocity * time;

  @override
  double dx(double time) => velocity;

  @override
  bool isDone(double time) => false;
}
