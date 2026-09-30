import 'package:flutter/material.dart';
import 'app_exception.dart';
import 'error_text.dart';

void showAppError(BuildContext context, Object error) {
  debugPrint('[Schmackofatz] $error');
  if (!context.mounted) return;
  final appError = normalizeAppException(error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(friendlyError(appError))),
  );
}

class AppErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String title;
  final String message;

  const AppErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Das hat nicht geklappt',
    this.message = 'Bitte prüfe die Verbindung und versuche es noch einmal.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Erneut versuchen')),
            const SizedBox(height: 8),
            const Text('Deine Daten wurden nicht verändert.'),
          ],
        ),
      ),
    );
  }
}
