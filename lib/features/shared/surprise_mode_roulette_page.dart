import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/app_design.dart';
import '../../core/food_mode.dart';
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
    FoodMode.dineOut: 'Wir essen',
  };

  static const _categoryAssets = <String>[
    'assets/together/clean/icons/icon_cooking.png',
    'assets/together/clean/icons/icon_delivery.png',
    'assets/together/clean/icons/icon_restaurant.png',
  ];

  static const _gold = Color(0xFFFFD779);
  static const _deepRed = Color(0xFF4A0717);
  static const _tileExtent = 116.0;
  static const _reelHeight = 200.0;

  late final List<AnimationController> _reels;
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

    // Stop the reels one after another. Each one keeps moving while the
    // previous reel decelerates, like a physical slot machine.
    for (var index = 0; index < _reels.length; index++) {
      if (!mounted) return;
      final controller = _reels[index];
      final current = controller.value;
      final firstLanding = current.ceil() + 6;
      final alignment =
          (winner - (firstLanding % _modes.length) + _modes.length) %
              _modes.length;
      final target = (firstLanding + alignment).toDouble();
      final distance = target - current;
      final duration = Duration(
        milliseconds: (distance * 1000 / (11.5 + index * 1.1) * 4).round(),
      );

      await controller.animateTo(
        target,
        duration: duration,
        curve: Curves.easeOutQuart,
      );
      if (!mounted) return;
      setState(() => _stoppedReels = index + 1);
      if (index < _reels.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }

    if (!mounted) return;
    setState(() {
      _spinning = false;
      _stopping = false;
      _finished = true;
    });
  }

  void _spinAgain() {
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            const SizedBox(height: 4),
            const Icon(Icons.auto_awesome, color: _gold, size: 26),
            const SizedBox(height: 8),
            Text(
              _finished ? 'DER ZUFALL HAT ENTSCHIEDEN' : 'FATZOMAT ROYALE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _deepRed,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.7,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _finished
                  ? 'Euer Abend steht fest.'
                  : 'Drei Walzen. Drei Möglichkeiten. Ein Treffer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppDesign.text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSlotMachine(context),
            const SizedBox(height: 22),
            if (_finished && result != null)
              _buildWinner(context, result)
            else
              Text(
                _stopping
                    ? 'Die Walzen bremsen …'
                    : 'Tippe auf STOPP und lass den Zufall entscheiden.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppDesign.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            const SizedBox(height: 18),
            if (_finished && result != null)
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, result),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('Weiter mit „${_labels[result]}“'),
              )
            else
              FilledButton.icon(
                onPressed: _stopping || !_spinning ? null : _stopRoulette,
                icon: Icon(
                  _stopping
                      ? Icons.hourglass_bottom_rounded
                      : Icons.stop_circle_rounded,
                ),
                label: Text(_stopping ? 'WALZEN STOPPEN …' : 'STOPP'),
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
            if (_finished) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _spinAgain,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _deepRed,
                  side: const BorderSide(color: _deepRed, width: 1.2),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('NOCHMAL DREHEN'),
              ),
            ],
          ],
        ),
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
            Color(0xFF7A1528),
            Color(0xFF310512),
            Color(0xFF19030A),
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
                'ROYAL JACKPOT',
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
              color: const Color(0xFF10070A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFB98736), width: 2),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: _deepRed.withValues(alpha: .12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'EURE GEWINNER-KATEGORIE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _deepRed,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Image.asset(
            _categoryAssets[index],
            height: 94,
            width: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            _labels[mode]!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _deepRed,
                  fontWeight: FontWeight.w900,
                ),
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
        color: const Color(0xFF21151A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stopped ? _gold : const Color(0xFF775A3A),
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

class _ConstantVelocitySimulation extends Simulation {
  final double start;
  final double velocity;

  const _ConstantVelocitySimulation(this.start, this.velocity);

  @override
  double x(double time) => start + velocity * time;

  @override
  double dx(double time) => velocity;

  @override
  bool isDone(double time) => false;
}
