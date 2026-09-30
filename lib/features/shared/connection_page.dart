import 'package:flutter/material.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/async_error.dart';
import '../../core/app_design.dart';
import '../../data/models/connection_info.dart';
import '../../data/repositories/collaboration_repository.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});
  @override State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final repo = CollaborationRepository();
  final code = TextEditingController();
  String? myCode;
  int memberCount = 0;
  bool loading = true, working = false;
  Object? loadError;
  ConnectionInfo? info;
  RealtimeChannel? channel;

  @override void initState() {
    super.initState();
    load();
    _subscribe();
  }
  @override void dispose() {
    code.dispose();
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel!);
      } on AssertionError {
        // Supabase may be unavailable in widget tests/offline previews.
      }
    }
    super.dispose();
  }

  void _subscribe() {
    try {
      final client = Supabase.instance.client;
    channel = client.channel('connection-status-${client.auth.currentUser?.id ?? 'current'}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'connection_members',
        callback: (_) => load(),
      )
      ..subscribe();
    } on AssertionError {
      // Widget tests and offline previews can mount before Supabase exists.
    }
  }

  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    try {
      final value = await repo.connectionInfo();
      if (mounted && generation == _loadGeneration) {
        setState(() {
        info = value;
        loadError = null;
        myCode = value?.code;
        memberCount = value?.memberCount ?? 0;
        loading = false;
        });
      }
    }
    catch (e) { if (mounted && generation == _loadGeneration) { setState(() { loading = false; loadError = e; }); } }
  }

  Future<void> create() async {
    setState(() => working = true);
    try { final c = await repo.createConnection(); if (mounted) setState(() { myCode = c; memberCount = 1; info = ConnectionInfo(id: info?.id ?? '', code: c, memberCount: 1); }); }
    catch (e) { if (mounted) showAppError(context, e); }
    finally { if (mounted) setState(() => working = false); }
  }

  Future<void> join() async {
    final value = code.text.trim(); if (value.isEmpty) return;
    setState(() => working = true);
    try { await repo.joinConnection(value); if (mounted) { setState(() { myCode = value.toUpperCase(); memberCount = 2; info = ConnectionInfo(id: info?.id ?? '', code: value.toUpperCase(), memberCount: 2); }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ihr seid jetzt verbunden.'))); } }
    catch (e) { if (mounted) showAppError(context, e); }
    finally { if (mounted) setState(() => working = false); }
  }

  Future<void> disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verbindung trennen?'),
        content: const Text('Die gemeinsame Verbindung wird auf diesem Gerät getrennt. Deine eigenen Rezepte und Favoriten bleiben erhalten.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Trennen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => working = true);
    try {
      await repo.disconnectConnection();
      if (!mounted) return;
      setState(() { myCode = null; memberCount = 0; info = null; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verbindung getrennt.')));
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override Widget build(BuildContext context) {
    return TogetherScaffold(backgroundType: TogetherBackgroundType.share, 
      appBar: TogetherAppBar(title: const Text('Gemeinsam nutzen')),
      body: loadError != null
          ? AppErrorView(error: loadError!, onRetry: load)
          : loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(memberCount >= 2 ? Icons.people_alt_rounded : Icons.person_add_alt_1_rounded, size: 56, color: AppDesign.primaryDark),
          const SizedBox(height: 16),
          Text('Optional zu zweit', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Die App funktioniert alleine. Wenn ihr verbunden seid, könnt ihr Rezepte vorschlagen und gemeinsame Mahlzeiten planen.', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          if (myCode != null) ...[
            Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              Icon(memberCount >= 2 ? Icons.people : Icons.person_add_alt_1, size: 36),
              const SizedBox(height: 8),
              Text(memberCount >= 2 ? 'Ihr seid verbunden' : 'Verbindung bereit', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(memberCount >= 2 ? '2 Personen nutzen jetzt dieselbe gemeinsame Sammlung.' : 'Der Code kann auf dem zweiten Gerät eingegeben werden.', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              const Text('Verbindungscode'),
              const SizedBox(height: 8),
              SelectableText(myCode!, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 4)),
              const SizedBox(height: 10),
              if (memberCount < 2)
                const Text('Gib diesen Code auf dem zweiten Gerät ein. Sobald die Person beitritt, aktualisiert sich dieser Bildschirm automatisch.', textAlign: TextAlign.center)
              else
                const Text('Ihr seid jetzt gemeinsam unterwegs. Vorschläge und gemeinsame Mahlzeiten laufen über die Verbindung. Deine persönlichen Entscheidungen bleiben getrennt.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: loading || working ? null : load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Status prüfen'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: working ? null : disconnect, icon: const Icon(Icons.link_off), label: const Text('Verbindung trennen')),
            ]))),
          ] else ...[
            FilledButton.icon(onPressed: working ? null : create, icon: const Icon(Icons.add_link), label: const Text('Verbindungscode erstellen')),
            const SizedBox(height: 24),
            const Center(child: Text('oder')),
            const SizedBox(height: 12),
            TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Verbindungscode', prefixIcon: Icon(Icons.link))),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: working ? null : join, icon: const Icon(Icons.group_add_outlined), label: const Text('Mit Person verbinden')),
          ],
        ],
      ),
    );
  }
}
