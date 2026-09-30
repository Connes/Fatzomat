import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_design.dart';
import '../../core/async_error.dart';
import '../../core/error_text.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/services/backup_service.dart';
import '../foods/food_preferences_page.dart';
import '../shared/connection_page.dart';
import 'notifications_page.dart';
import 'personal_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final collaboration = CollaborationRepository();
  bool loading = true;
  bool connected = false;
  int unreadNotifications = 0;
  Object? loadError;
  RealtimeChannel? notificationsChannel;

  @override
  void initState() {
    super.initState();
    load();
    _subscribeNotifications();
  }

  void _subscribeNotifications() {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      notificationsChannel = client.channel('settings-notifications-$userId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_notifications',
          callback: (_) {
            if (mounted) load();
          },
        )
        ..subscribe();
    } on AssertionError {
      // Widget tests and offline previews can mount before Supabase exists.
    }
  }

  @override
  void dispose() {
    if (notificationsChannel != null) {
      try {
        Supabase.instance.client.removeChannel(notificationsChannel!);
      } on AssertionError {
        // Supabase may be unavailable in widget tests/offline previews.
      }
    }
    super.dispose();
  }

  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    try {
      final info = await collaboration.connectionInfo();
      final unread = await collaboration.unreadCount();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        connected = info?.isConnected ?? false;
        unreadNotifications = unread;
        loadError = null;
        loading = false;
      });
    } catch (error) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          loading = false;
          loadError = error;
        });
      }
    }
  }

  Future<void> exportBackup() async {
    try {
      final uri = await BackupService().exportPersonalBackup();
      if (!mounted) return;
      if (uri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sicherung gespeichert.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    }
  }

  Future<void> openConnection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConnectionPage()),
    );
    await load();
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.settings,
      appBar: const TogetherAppBar(title: Text('Einstellungen')),
      body: loadError != null
          ? AppErrorView(error: loadError!, onRetry: load)
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _SettingsTile(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Meine Ernährung',
                    subtitle: 'Lebensmittel und persönliche Entscheidungen',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _NutritionSettingsPage()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsTile(
                    icon: Icons.people_alt_outlined,
                    title: connected ? 'Meine Connection' : 'Connection hinzufügen',
                    subtitle: connected
                        ? 'Gemeinsam Rezepte und Mahlzeiten nutzen'
                        : 'Optional gemeinsam mit einer Person nutzen',
                    trailing: connected
                        ? const Icon(Icons.check_circle_rounded, color: AppDesign.primary)
                        : null,
                    onTap: openConnection,
                  ),
                  const SizedBox(height: 14),
                  _SettingsTile(
                    icon: Icons.backup_outlined,
                    title: 'Backup erstellen',
                    subtitle: 'Deine persönlichen Daten als private Sicherung speichern',
                    onTap: exportBackup,
                  ),
                  const SizedBox(height: 14),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Benachrichtigungen',
                    subtitle: unreadNotifications == 0
                        ? 'Keine neuen Hinweise'
                        : '$unreadNotifications neue Hinweise',
                    trailing: unreadNotifications == 0
                        ? null
                        : Badge(label: Text('$unreadNotifications')),
                    onTap: openNotifications,
                  ),
                  if (loading) ...[
                    const SizedBox(height: 18),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppDesign.softSurface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppDesign.primaryDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionSettingsPage extends StatelessWidget {
  const _NutritionSettingsPage();

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.settings,
      appBar: const TogetherAppBar(title: Text('Meine Ernährung')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _SettingsTile(
            icon: Icons.restaurant_menu_rounded,
            title: 'Meine Lebensmittel',
            subtitle: 'Mögen, nicht mögen und Kategorien',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoodPreferencesPage()),
            ),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.history_rounded,
            title: 'Persönliche Entscheidungen',
            subtitle: 'Deine eigenen Today-Aktionen und Entscheidungen',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalHistoryPage()),
            ),
          ),
        ],
      ),
    );
  }
}
