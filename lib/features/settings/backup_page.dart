import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/app_design.dart';
import '../../core/error_text.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/services/backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool busy = false;

  Future<void> createBackup() async {
    setState(() => busy = true);
    try {
      final uri = await BackupService().exportPersonalBackup();
      if (mounted && uri != null) {
        AppFeedback.showSnackBar(context, const SnackBar(content: Text('Backup gespeichert.')));
      }
    } catch (error) {
      if (mounted) AppFeedback.showSnackBar(context, SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup wiederherstellen?'),
        content: const Text(
          'Deine Lebensmittelentscheidungen werden durch das Backup ersetzt. '
          'Bei Backups ab Version 2 wird auch die persönliche Historie ersetzt. '
          'Rezepte und Restaurantfavoriten bleiben unverändert.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Wiederherstellen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final result = await BackupService().restorePersonalBackup();
      if (!mounted || result == null) return;
      final count = result['history'] ?? -1;
      final historyMessage = count < 0
          ? ' Die Historie blieb unverändert, da das ältere Backup sie nicht enthält.'
          : ' $count Historieneinträge wiederhergestellt.';
      AppFeedback.showSnackBar(context, SnackBar(
        content: Text('${result['preferences']} Lebensmittelentscheidungen wiederhergestellt.$historyMessage'),
      ));
    } catch (error) {
      if (mounted) AppFeedback.showSnackBar(context, SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TogetherScaffold(
        backgroundType: TogetherBackgroundType.settings,
        appBar: const TogetherAppBar(title: Text('Backup')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _BackupActionTile(
              icon: Icons.backup_outlined,
              title: 'Erstellen',
              subtitle: 'Persönliche Daten als JSON-Datei speichern',
              onTap: busy ? null : createBackup,
            ),
            const SizedBox(height: 14),
            _BackupActionTile(
              icon: Icons.settings_backup_restore_rounded,
              title: 'Wiederherstellen',
              subtitle: 'Persönliche Daten aus einer Backup-Datei importieren',
              onTap: busy ? null : restoreBackup,
            ),
            if (busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      );
}

class _BackupActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _BackupActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, size: 30, color: AppDesign.iconGold),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: onTap,
        ),
      );
}
