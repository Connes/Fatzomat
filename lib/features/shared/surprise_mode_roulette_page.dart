import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/food_mode.dart';
import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';

class SurpriseModeRoulettePage extends StatefulWidget {
  const SurpriseModeRoulettePage({super.key});

  @override
  State<SurpriseModeRoulettePage> createState() => _SurpriseModeRoulettePageState();
}

class _SurpriseModeRoulettePageState extends State<SurpriseModeRoulettePage> {
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

  Timer? _timer;
  int _index = 0;
  int _round = 0;
  bool _spinning = true;
  bool _stopping = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _scheduleTick(const Duration(milliseconds: 95));
  }

  void _scheduleTick(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!mounted || !_spinning) return;
      setState(() {
        _index = (_index + 1) % _modes.length;
        _round++;
      });
      _scheduleTick(Duration(milliseconds: _stopping ? 110 + (_round % 15) * 22 : 75));
    });
  }

  Future<void> _stopRoulette() async {
    if (_stopping || !_spinning) return;
    setState(() => _stopping = true);
    _timer?.cancel();

    // A sequence of progressively longer pauses creates the slot-machine
    // slowdown while keeping the winning option centered and readable.
    for (var step = 0; step < 12; step++) {
      if (!mounted) return;
      await Future<void>.delayed(Duration(milliseconds: 90 + step * step * 13));
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _modes.length;
        _round++;
      });
    }

    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _spinning = false;
      _finished = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = _modes[_index];
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.decisionResult,
      appBar: TogetherAppBar(title: const Text('Überrasch mich')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            const SizedBox(height: 18),
            Icon(Icons.casino_rounded, size: 62, color: AppDesign.primaryDark),
            const SizedBox(height: 18),
            Text(
              _finished ? 'Das ist eure Überraschung!' : 'Was machen wir heute?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _finished
                  ? 'Der Zufall hat entschieden. Tippe auf das Ergebnis, um weiterzumachen.'
                  : 'Lass die Möglichkeiten durchlaufen und stoppe, wenn du bereit bist.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 34),
            SizedBox(
              height: 172,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: _spinning ? 65 : 180),
                    switchInCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.75, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Container(
                      key: ValueKey('$_index-$_round'),
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppDesign.primaryDark, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        _labels[mode]!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (_finished)
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, mode),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('Weiter mit „${_labels[mode]}“'),
              )
            else
              FilledButton.icon(
                onPressed: _stopping ? null : _stopRoulette,
                icon: Icon(_stopping ? Icons.hourglass_bottom_rounded : Icons.stop_circle_outlined),
                label: Text(_stopping ? 'Es wird langsamer …' : 'Stopp'),
              ),
            if (_finished) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _index = 0;
                    _round++;
                    _spinning = true;
                    _stopping = false;
                    _finished = false;
                  });
                  _scheduleTick(const Duration(milliseconds: 95));
                },
                child: const Text('Noch einmal drehen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
