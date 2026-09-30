import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';

class DiagnosticsPage extends StatefulWidget {
  final String supabaseUrl;
  final String publishableKey;

  const DiagnosticsPage({
    super.key,
    required this.supabaseUrl,
    this.publishableKey = '',
  });

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  bool checking = false;
  String? connectionStatus;
  String? connectionError;

  bool get urlOk => Uri.tryParse(widget.supabaseUrl)?.hasScheme == true;
  bool get keyOk => widget.publishableKey.trim().isNotEmpty;

  Future<void> _checkConnection() async {
    if (checking) return;
    setState(() {
      checking = true;
      connectionStatus = null;
      connectionError = null;
    });

    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session == null) {
        await client.auth.signInAnonymously();
      }
      await client.from('profiles').select('id').limit(1);
      if (!mounted) return;
      setState(() {
        connectionStatus = 'Verbindung zu Supabase funktioniert.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        connectionError = 'Verbindung konnte nicht geprüft werden.';
      });
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.settings,
      appBar: TogetherAppBar(title: const Text('Diagnose')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'App-Konfiguration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(urlOk ? Icons.check_circle : Icons.error),
            title: const Text('Supabase URL'),
            subtitle: Text(urlOk ? 'Konfiguriert' : 'Fehlt oder ist ungültig'),
          ),
          ListTile(
            leading: Icon(keyOk ? Icons.check_circle : Icons.error),
            title: const Text('Supabase Publishable Key'),
            subtitle: Text(keyOk ? 'Konfiguriert' : 'Fehlt'),
          ),
          ListTile(
            leading: Icon(session != null ? Icons.check_circle : Icons.info_outline),
            title: const Text('App-Sitzung'),
            subtitle: Text(session != null ? 'Aktive Sitzung vorhanden' : 'Keine aktive Sitzung'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: checking ? null : _checkConnection,
            icon: checking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            label: Text(checking ? 'Verbindung wird geprüft…' : 'Verbindung prüfen'),
          ),
          if (connectionStatus != null) ...[
            const SizedBox(height: 12),
            Text(connectionStatus!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
          if (connectionError != null) ...[
            const SizedBox(height: 12),
            Text(connectionError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          const Text(
            'Es werden keine geheimen Schlüssel oder Sitzungstokens angezeigt. '
            'Die App verwendet weiterhin den Publishable Key und die Supabase-RLS-Regeln.',
          ),
        ],
      ),
    );
  }
}
