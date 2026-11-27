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
  Route<dynamic>? _rootRoute;

  bool get isActive => _id != null;
  String? get activeId => _id;
  String? get activeLabel => _label;

  /// Registers the first guarded route as the active path's root.
  ///
  /// Further guarded routes are child steps and must remain normally
  /// navigable. The root is captured lazily because ModalRoute is only
  /// available from a widget's build context.
  bool isRootRoute(Route<dynamic>? route) {
    if (!isActive || route == null) return false;
    _rootRoute ??= route;
    return identical(_rootRoute, route);
  }

  void beginIfIdle({required String id, required String label}) {
    if (isActive) return;
    _id = id;
    _label = label;
    _rootRoute = null;
    notifyListeners();
  }

  void complete() {
    if (!isActive) return;
    _id = null;
    _label = null;
    _rootRoute = null;
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
    final route = ModalRoute.of(context);
    return ListenableBuilder(
      listenable: FlowGuard.instance,
      builder: (context, _) {
        final isRoot = FlowGuard.instance.isRootRoute(route);
        return PopScope<Object?>(
          canPop: !isRoot,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop || !FlowGuard.instance.isRootRoute(route) || !context.mounted) {
              return;
            }
            final leave = await FlowGuard.instance.confirmAbandon(context);
            if (leave && context.mounted) Navigator.of(context).pop();
          },
          child: child,
        );
      },
    );
  }
}
