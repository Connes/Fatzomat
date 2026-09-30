import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../data/models/decision_share.dart';
import '../../data/repositories/collaboration_repository.dart';
import 'today_page.dart';

class DecisionSharePage extends StatefulWidget {
  final DecisionShare share;
  const DecisionSharePage({super.key, required this.share});

  @override
  State<DecisionSharePage> createState() => _DecisionSharePageState();
}

class _DecisionSharePageState extends State<DecisionSharePage> {
  String _decisionText() {
    if (widget.share.decisionName != null && widget.share.decisionName!.trim().isNotEmpty) return widget.share.decisionName!;
    if (widget.share.decisionValue != null && widget.share.decisionValue!.trim().isNotEmpty) {
      return widget.share.decisionValue!;
    }
    return 'heute';
  }

  bool _applying = false;

  Future<void> _startToday() async {
    if (_applying) return;

    // "Entscheide Du" is only a request/message. It does not carry a
    // decision snapshot, so there is nothing to apply here. The requested
    // flow is simply to continue to the personal Today page.
    if (widget.share.isAsk) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TodayPage()),
      );
      return;
    }

    setState(() => _applying = true);
    try {
      final share = widget.share;
      if (!share.isShare) {
        throw StateError('Diese Nachricht enthält keine übernehmbare Entscheidung.');
      }

      // Acceptance must happen through a SECURITY DEFINER RPC. A shared recipe
      // belongs to the sender, so a direct client-side INSERT into
      // recipe_saves is correctly blocked by RLS. The RPC validates the
      // recipient, creates an independent recipe copy when necessary, saves
      // it for the current user and sets the personal Today plan atomically.
      await CollaborationRepository().acceptDecisionShare(share.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TodayPage()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final share = widget.share;
    return Scaffold(
      backgroundColor: AppDesign.background,
      appBar: AppBar(title: const Text('Entscheidung')),
      body: TogetherBackground(
        type: TogetherBackgroundType.home,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  color: AppDesign.surface.withValues(alpha: 0.97),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(share.isAsk ? Icons.people_alt_rounded : Icons.ios_share_rounded, size: 48, color: AppDesign.primaryDark),
                        const SizedBox(height: 18),
                        Text(
                          share.isAsk ? 'Entscheide Du' : 'Entscheidung geteilt',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          share.isAsk
                              ? 'Deine verbundene Person möchte, dass du heute die Essensentscheidung triffst.'
                              : 'Deine verbundene Person hat die Entscheidung für heute getroffen.',
                          textAlign: TextAlign.center,
                        ),
                        if (share.isShare) ...[
                          const SizedBox(height: 24),
                          if (share.imageUrl != null && share.imageUrl!.trim().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(share.imageUrl!, height: 180, fit: BoxFit.cover),
                            ),
                          const SizedBox(height: 18),
                          Text(
                            _decisionText(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (share.decisionType != null && share.decisionType != 'recipe') ...[
                            const SizedBox(height: 8),
                            Text(
                              share.decisionType == 'order'
                                  ? 'Bestellung'
                                  : share.decisionType == 'dine_out'
                                      ? 'Restaurant'
                                      : share.decisionType == 'surprise'
                                          ? 'Überraschung'
                                          : share.decisionType!,
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (share.servings != null) ...[
                            const SizedBox(height: 8),
                            Text('${share.servings} Personen', textAlign: TextAlign.center),
                          ],
                        ],
                        const SizedBox(height: 26),
                        FilledButton(
                          onPressed: share.isAsk
                              ? _startToday
                              : (_applying ? null : _startToday),
                          child: Text(share.isAsk ? "Los geht's" : 'Übernehmen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
