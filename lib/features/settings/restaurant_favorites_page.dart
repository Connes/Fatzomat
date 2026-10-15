import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/restaurant_favorites_repository.dart';

class RestaurantFavoritesPage extends StatefulWidget {
  final bool selectForToday;

  const RestaurantFavoritesPage({super.key, this.selectForToday = false});

  @override
  State<RestaurantFavoritesPage> createState() => _RestaurantFavoritesPageState();
}

class _RestaurantFavoritesPageState extends State<RestaurantFavoritesPage> {
  final _repository = RestaurantFavoritesRepository();
  List<Map<String, dynamic>> _favorites = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final favorites = await _repository.all();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _addRestaurant() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lieblingsrestaurant hinzufügen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Restaurantname', hintText: 'z. B. Gasthaus zur Linde'),
          onSubmitted: (_) => Navigator.pop(dialogContext, controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Mit ChatGPT ergänzen'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;
    final prompt = '''
Ergänze mein Fatzomat-Lieblingsrestaurant anhand des Namens: "$name".
Recherchiere aktuelle, verlässliche Quellen. Falls mehrere gleichnamige Restaurants existieren, frage nach dem Ort. Erfinde keine Daten; unbekannte optionale Angaben müssen null sein.
Gib anschließend ausschließlich gültiges JSON ohne Markdown oder Erklärung in genau diesem Format aus:
{
  "schema_version": 1,
  "type": "fatzomat_restaurant_suggestion",
  "restaurant": {
    "name": "Restaurantname",
    "cuisine": "Küche",
    "address": "Straße Hausnummer, PLZ Ort",
    "phone": null,
    "website": null,
    "opening_hours": null
  }
}
name, cuisine und address sind Pflichtfelder als nicht-leere Strings. phone, website und opening_hours sind Strings oder null. website muss eine vollständige HTTP(S)-URL sein. opening_hours enthält, sofern verlässlich auffindbar, Wochentage und Zeiträume. Keine zusätzlichen Felder.
'''.trim();
    final uri = Uri.https('chatgpt.com', '/', {'q': prompt});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ChatGPT konnte nicht geöffnet werden. Bitte prüfe, ob ChatGPT installiert ist.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ChatGPT erstellt die Restaurantdaten. Importiere anschließend die JSON-Datei hier in Fatzomat.'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _remove(Map<String, dynamic> restaurant) async {
    await _repository.remove(restaurant);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.settings,
      appBar: TogetherAppBar(
        title: Text(widget.selectForToday ? 'Meine Restaurantfavoriten' : 'Restaurant'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Restaurantfavoriten konnten nicht geladen werden.'),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Erneut versuchen')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      AppSurface(
                        padding: const EdgeInsets.all(20),
                        color: AppDesign.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 38, color: AppDesign.primaryDark),
                            const SizedBox(height: 10),
                            Text(
                              'Lieblingsrestaurants',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppDesign.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Füge ein Restaurant über ChatGPT hinzu. ChatGPT recherchiert die fehlenden Angaben; anschließend importierst du die JSON-Daten in Fatzomat.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppDesign.text,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _addRestaurant,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Lieblingsrestaurant hinzufügen'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_favorites.isEmpty)
                        AppSurface(
                          padding: const EdgeInsets.all(22),
                          color: AppDesign.surface,
                          child: Column(
                            children: [
                              const Icon(Icons.restaurant_menu_rounded, size: 34, color: AppDesign.primaryDark),
                              const SizedBox(height: 8),
                              Text(
                                'Noch keine Favoriten gespeichert',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppDesign.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Deine gespeicherten Restaurants erscheinen hier.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppDesign.text,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._favorites.map((restaurant) {
                          final name = restaurant['name'].toString();
                          final cuisine = restaurant['cuisine']?.toString().trim() ?? '';
                          final address = restaurant['address']?.toString().trim() ?? '';
                          final details = [
                            if (cuisine.isNotEmpty) cuisine,
                            if (address.isNotEmpty) address,
                          ].join(' · ');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              color: AppDesign.surface,
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppDesign.softSurface,
                                  child: Icon(Icons.restaurant_rounded, color: AppDesign.primaryDark),
                                ),
                                title: Text(name, style: const TextStyle(color: AppDesign.text, fontWeight: FontWeight.w600)),
                                subtitle: details.isEmpty ? null : Text(details, style: const TextStyle(color: AppDesign.text)),
                                trailing: widget.selectForToday
                                    ? const Icon(Icons.chevron_right_rounded)
                                    : IconButton(
                                        tooltip: 'Favorit entfernen',
                                        icon: const Icon(Icons.favorite, color: AppDesign.primaryDark),
                                        onPressed: () => _remove(restaurant),
                                      ),
                                onTap: widget.selectForToday ? () => Navigator.pop(context, restaurant) : null,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
