import 'package:flutter/material.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_design.dart';
import '../../core/async_error.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../shared/decision_request_page.dart';
import '../recipes/saved_recipes_page.dart';
import '../recipes/recipe_detail_page.dart';
import '../recipes/recipe_share_request_page.dart';
import '../shared/today_page.dart';

class NotificationsPage extends StatefulWidget {
  final String? initialNotificationId;

  const NotificationsPage({super.key, this.initialNotificationId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final repo = CollaborationRepository();
  List<AppNotification> items = const [];
  bool loading = true;
  bool markingAllRead = false;
  Object? loadError;
  RealtimeChannel? channel;
  bool _openedInitialNotification = false;

  @override
  void initState() {
    super.initState();
    load();
    try {
      final client = Supabase.instance.client;
      channel = client
        .channel('notifications-${client.auth.currentUser?.id ?? 'current'}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'app_notifications',
        filter: client.auth.currentUser == null
            ? null
            : PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: client.auth.currentUser!.id,
              ),
        callback: (_) => load(),
      )
      ..subscribe();
    } on AssertionError {
      // Widget tests and offline previews can mount before Supabase exists.
    }
  }

  @override
  void dispose() {
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel!);
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
      final result = await repo.notifications();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        items = result;
        loadError = null;
        loading = false;
      });
      final initialId = widget.initialNotificationId;
      if (!_openedInitialNotification && initialId != null) {
        AppNotification? match;
        for (final item in result) {
          if (item.id == initialId) {
            match = item;
            break;
          }
        }
        final notification = match;
        if (notification != null) {
          _openedInitialNotification = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) open(notification);
          });
        }
      }
    } catch (error) {
      if (mounted && generation == _loadGeneration) setState(() { loading = false; loadError = error; });
    }
  }

  Future<void> open(AppNotification item) async {
    if (!item.isRead) {
      await repo.markNotificationRead(item.id);
      await load();
    }

    if (!mounted) return;

    if (item.decisionShareId != null || item.type == 'decision_message') {
      if (item.decisionShareId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TodayPage()),
        );
      } else {
        // Compatibility fallback for installations where the V85
        // decision_share_id column is not available yet. The notification
        // remains usable instead of turning the inbox into an error screen.
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TodayPage()),
        );
      }
      await load();
      return;
    }

    if (item.type == 'recipe_created' && item.recipeId != null) {
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: item.recipeId!)),
        );
      } catch (_) {
        // The detail page handles a missing recipe itself.
      }
      await load();
      return;
    }

    if (item.decisionRequestId != null) {
      final request = await repo.decisionRequest(item.decisionRequestId!);
      if (!mounted || request == null || (!request.isPending && !request.isAccepted)) {
        await load();
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DecisionRequestPage(request: request)),
      );
      await load();
      return;
    }

    if (item.recipeSuggestionId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeShareRequestPage(suggestionId: item.recipeSuggestionId!),
        ),
      );
      await load();
      return;
    }

    if (item.type == 'recipe_suggestion') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedRecipesPage()),
      );
      await load();
      return;
    }

    if (item.sharedRecipePlanId != null || item.type == 'shared_recipe') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TodayPage()),
      );
      await load();
    }
  }

  Future<void> markAllRead() async {
    if (markingAllRead || unreadCount == 0) return;
    setState(() => markingAllRead = true);
    try {
      await repo.markAllNotificationsRead();
      await load();
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => markingAllRead = false);
    }
  }

  int get unreadCount => items.where((item) => !item.isRead).length;

  String timeLabel(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  IconData iconFor(AppNotification item) {
    if (item.type == 'decision_message') return Icons.people_alt_rounded;
    if (item.type == 'decision_request_accepted') return Icons.check_circle_outline_rounded;
    if (item.type == 'decision_request_cancelled') return Icons.undo_rounded;
    if (item.type == 'recipe_created' || item.type == 'shared_recipe' || item.type == 'recipe_suggestion') return Icons.restaurant_menu_rounded;
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final unread = unreadCount;
    return TogetherScaffold(backgroundType: TogetherBackgroundType.notifications, 
      appBar: TogetherAppBar(
        title: Row(
          children: [
            const Text('Benachrichtigungen'),
            if (unread > 0) ...[
              const SizedBox(width: 10),
              Badge(label: Text('$unread')),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(onPressed: markingAllRead ? null : markAllRead, child: Text(markingAllRead ? 'Wird gespeichert …' : 'Alle gelesen')),
        ],
      ),
      body: loadError != null
          ? AppErrorView(error: loadError!, onRetry: load)
          : RefreshIndicator(
        onRefresh: load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 70),
                      Icon(Icons.notifications_none_rounded, size: 56, color: AppDesign.primaryDark),
                      const SizedBox(height: 18),
                      Text('Alles ruhig.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('Hier erscheinen neue Rezepte und Entscheidungen.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Card(
                        color: item.isRead ? null : AppDesign.softSurface,
                        child: ListTile(
                          onTap: () => open(item),
                          leading: CircleAvatar(
                            backgroundColor: AppDesign.peachSurface,
                            child: Icon(iconFor(item), color: AppDesign.primaryDark),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                              Text(timeLabel(item.createdAt), style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(item.body),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
