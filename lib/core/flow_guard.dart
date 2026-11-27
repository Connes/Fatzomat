import 'package:flutter/material.dart';

/// Owns the single active, non-resumable user editing path.
///
/// A path is started once, remains active while its child routes are visited,
/// and is cleared only after successful completion or an explicitly confirmed
/// exit. It deliberately stores no draft: abandoning a path means starting over.
class FlowGuard extends ChangeNotifier {
  FlowGuard._();

  static final FlowGuard instance = FlowGuard._();

  String? _id;
  String? _label;

  bool get isActive => _id != null;
  String? get activeId => _id;
  String? get activeLabel => _label;

  void beginIfIdle({required String id, required String label}) {
    if (isActive) return;
    _id = id;
    _label = label;
    notifyListeners();
  }

  void complete() {
    if (!isActive) return;
    _id = null;
    _label = null;
    notifyListeners();
  }

  /// Ask before leaving the current path. A positive answer clears it.
  Future<bool> confirmAbandon(BuildContext context, {String? destination}) async {
    if (!isActive) return true;
    final label = _label ?? 'Bearbeitung';
    final target = destination == null || destination.isEmpty
        ? 'einen anderen Bereich'
        : destination;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bearbeitungspfad verlassen?'),
        content: Text(
          '„$label“ ist noch nicht abgeschlossen. Wenn du jetzt zu $target wechselst, '
          'wird dieser Vorgang beendet. Du kannst ihn später nur von vorne beginnen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Weiter bearbeiten'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Pfad verlassen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    complete();
    return true;
  }
}

/// Protects the root screen of a flow. Child routes remain freely navigable;
/// only attempting to pop the root of the active path asks for confirmation.
class FlowExitGuard extends StatelessWidget {
  final Widget child;

  const FlowExitGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FlowGuard.instance,
      builder: (context, _) => PopScope<Object?>(
        canPop: !FlowGuard.instance.isActive,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || !FlowGuard.instance.isActive || !context.mounted) return;
          final leave = await FlowGuard.instance.confirmAbandon(context);
          if (leave && context.mounted) Navigator.of(context).pop();
        },
        child: child,
      ),
    );
  }
}
