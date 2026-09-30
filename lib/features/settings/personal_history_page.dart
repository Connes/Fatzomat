import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/async_error.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/personal_history_entry.dart';
import '../../data/repositories/personal_today_repository.dart';

class PersonalHistoryPage extends StatefulWidget {
  const PersonalHistoryPage({super.key});

  @override
  State<PersonalHistoryPage> createState() => _PersonalHistoryPageState();
}

class _PersonalHistoryPageState extends State<PersonalHistoryPage> {
  final repository = PersonalTodayRepository();
  bool loading = true;
  Object? error;
  List<PersonalHistoryEntry> entries = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await repository.history();
      if (!mounted) return;
      setState(() {
        entries = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.settings,
      appBar: TogetherAppBar(title: const Text('Persönliche History')),
      body: RefreshIndicator(
        onRefresh: load,
        child: error != null
            ? AppErrorView(error: error!, onRetry: load)
            : loading
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 80),
                          Icon(Icons.history_rounded, size: 52, color: AppDesign.secondaryText),
                          SizedBox(height: 16),
                          Center(child: Text('Noch keine persönlichen Entscheidungen.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _HistoryTile(entry: entries[index]),
                      ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PersonalHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final image = entry.imageUrl?.trim();
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image != null && image.isNotEmpty
              ? Image.network(image, width: 52, height: 52, fit: BoxFit.cover)
              : Image.asset('assets/together/clean/background/recipe_detail_background.png', width: 52, height: 52, fit: BoxFit.cover),
        ),
        title: Text(entry.recipeName ?? entry.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${entry.label}\n${_formatDate(entry.createdAt)}'),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
