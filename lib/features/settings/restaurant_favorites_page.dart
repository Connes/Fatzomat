import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/restaurant_favorites_repository.dart';
import '../shared/restaurant_details_dialog.dart';

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
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final input = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lieblingsrestaurant hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Restaurantname',
                hintText: 'z. B. Gasthaus zur Linde',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ort oder Adresse',
                hintText: 'z. B. Bad Herrenalb',
              ),
              onSubmitted: (_) {
                final name = nameController.text.trim();
                final location = locationController.text.trim();
                if (name.isNotEmpty && location.isNotEmpty) {
                  Navigator.pop(dialogContext, {'name': name, 'location': location});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () {
              final name = nameController.text.trim();
              final location = locationController.text.trim();
              if (name.isNotEmpty && location.isNotEmpty) {
                Navigator.pop(dialogContext, {'name': name, 'location': location});
              }
            },
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Mit ChatGPT suchen'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    nameController.dispose();
    locationController.dispose();
    if (input == null || !mounted) return;

    final name = input['name']!;
    final location = input['location']!;
    final prompt = '''
Ich möchte das Restaurant "$name" aus "$location" als Fatzomat-Lieblingsrestaurant speichern.
Recherchiere mit aktuellen Webquellen und offiziellen Quellen, soweit verfügbar. Falls es mehrere passende Restaurants mit diesem Namen in oder nahe "$location" gibt, liste zuerst alle plausiblen Treffer nummeriert auf. Gib Name und vollständige Adresse sowie eine kurze Unterscheidung je Treffer an. Frage mich dann, welches Restaurant ich meine, und warte auf meine Auswahl. Erstelle vor meiner Auswahl KEINE JSON-Datei.
Nach meiner Auswahl recherchiere die folgenden Felder: name, cuisine, address, phone, website, opening_hours. Das Feld name muss ausschließlich den offiziellen Restaurantnamen enthalten, ohne Ort, Stadtteil, Filiale oder Zusatz nach einem Bindestrich/Klammerzusatz, sofern dieser Zusatz nicht wirklich Teil des offiziellen Namens ist. Ort und Filiale gehören in address. Formatiere address als „Straße Hausnummer, PLZ Ort“. Pflichtfelder name, cuisine und address müssen nicht-leere Strings sein. Für nicht zuverlässig verifizierbare optionale Felder phone, website und opening_hours verwende null. Erfinde keine Angaben.
Erstelle nach meiner Auswahl eine echte herunterladbare Datei namens "fatzomat_restaurant.json" als Datei-Anhang/Download, nicht nur einen Codeblock im Chat. Die Datei muss ausschließlich ein gültiges JSON-Objekt in genau diesem Format enthalten:
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
Keine zusätzlichen Felder. website muss eine vollständige HTTP(S)-URL sein. opening_hours soll, sofern verlässlich auffindbar, Wochentage und Zeiträume enthalten. Prüfe vor Bereitstellung, dass das JSON gültig ist und exakt dem Schema entspricht. Stelle den Download direkt bereit, damit ich die Datei speichern und anschließend in Fatzomat importieren kann.
'''.trim();

    try {
      final uri = Uri.https('chatgpt.com', '/', {'q': prompt});
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!launched) {
        AppFeedback.showSnackBar(context, 
          const SnackBar(content: Text('ChatGPT konnte nicht geöffnet werden. Bitte prüfe, ob ChatGPT installiert ist.')),
        );
        return;
      }
      AppFeedback.showSnackBar(context, 
        const SnackBar(
          content: Text('Wähle in ChatGPT bei mehreren Treffern das richtige Restaurant und lade danach die JSON-Datei herunter.'),
          duration: Duration(seconds: 6),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
        SnackBar(content: Text('ChatGPT konnte nicht geöffnet werden: $error')),
      );
    }
  }

  Future<void> _showAddOptions() async {
    if (widget.selectForToday) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lieblingsrestaurant hinzufügen',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  color: AppDesign.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(sheetContext, 'json'),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('JSON-Datei importieren'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, 'chatgpt'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Mit ChatGPT hinzufügen'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'json') {
      await _importFavoriteJson();
    } else if (choice == 'chatgpt') {
      await _addRestaurant();
    }
  }

  Future<void> _importFavoriteJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (result.isEmpty || !mounted) return;
      final file = result.first;
      final path = file.path;
      if (path == null || path.isEmpty) {
        throw const FormatException('Die ausgewählte Datei konnte nicht gelesen werden.');
      }
      final bytes = await File(path).readAsBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['schema_version'] != 1 ||
          decoded['type'] != 'fatzomat_restaurant_suggestion') {
        throw const FormatException('Das ist keine gültige Fatzomat-Restaurantdatei.');
      }
      final rawRestaurant = decoded['restaurant'];
      if (rawRestaurant is! Map) {
        throw const FormatException('Die Restaurantdaten fehlen in der JSON-Datei.');
      }
      final restaurant = Map<String, dynamic>.from(rawRestaurant);
      String requiredString(String key) {
        final value = restaurant[key];
        if (value is! String || value.trim().isEmpty) {
          throw FormatException('Das Pflichtfeld „$key“ fehlt.');
        }
        return value.trim();
      }
      final name = requiredString('name');
      final cuisine = requiredString('cuisine');
      final address = requiredString('address');
      for (final key in ['phone', 'website', 'opening_hours']) {
        final value = restaurant[key];
        if (value != null && value is! String) {
          throw FormatException('Das Feld „$key“ muss Text oder null sein.');
        }
      }
      final website = (restaurant['website'] as String?)?.trim();
      if (website != null && website.isNotEmpty) {
        final uri = Uri.tryParse(website);
        if (uri == null || !uri.hasAuthority || !{'http', 'https'}.contains(uri.scheme)) {
          throw const FormatException('Die Webseite muss eine gültige HTTP(S)-Adresse sein.');
        }
      }
      final normalized = <String, dynamic>{
        'name': name,
        'cuisine': cuisine,
        'address': address,
        'phone': restaurant['phone'],
        'website': website?.isEmpty == true ? null : website,
        'opening_hours': restaurant['opening_hours'],
      };
      final added = await _repository.add(normalized);
      await _load();
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
        SnackBar(
          content: Text(added
              ? '$name wurde zu deinen Favoriten hinzugefügt.'
              : '$name ist mit dieser Adresse bereits in deinen Favoriten.'),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
        SnackBar(content: Text('JSON-Import fehlgeschlagen: ${error.message}')),
      );
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
        SnackBar(content: Text('Restaurant konnte nicht importiert werden: $error')),
      );
    }
  }

  Future<void> _showRestaurantDetails(Map<String, dynamic> restaurant) async {
    await showRestaurantDetailsDialog(context, restaurant);
  }

  Future<void> _editRestaurant(Map<String, dynamic> restaurant) async {
    final nameController = TextEditingController(text: restaurant['name']?.toString() ?? '');
    final cuisineController = TextEditingController(text: restaurant['cuisine']?.toString() ?? '');
    final addressController = TextEditingController(text: restaurant['address']?.toString() ?? '');
    final phoneController = TextEditingController(text: restaurant['phone']?.toString() ?? '');
    final websiteController = TextEditingController(text: restaurant['website']?.toString() ?? '');
    final hoursController = TextEditingController(text: restaurant['opening_hours']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final edited = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lieblingsrestaurant bearbeiten'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(nameController, 'Restaurantname', required: true),
                _editField(cuisineController, 'Küche', required: true),
                _editField(addressController, 'Adresse', required: true),
                _editField(phoneController, 'Telefon'),
                _editField(websiteController, 'Webseite'),
                _editField(hoursController, 'Öffnungszeiten', maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, <String, dynamic>{
                'name': nameController.text.trim(),
                'cuisine': cuisineController.text.trim(),
                'address': addressController.text.trim(),
                'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                'website': websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
                'opening_hours': hoursController.text.trim().isEmpty ? null : hoursController.text.trim(),
              });
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    // Let the dialog route finish its reverse transition before disposing the
    // controllers and its GlobalKey-backed Form. Otherwise Flutter can still
    // have dependents attached while the dialog subtree is being unmounted.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (final controller in [nameController, cuisineController, addressController, phoneController, websiteController, hoursController]) {
      controller.dispose();
    }
    if (edited == null || !mounted) return;
    await _repository.remove(restaurant);
    await _repository.add(edited);
    await _load();
  }

  Widget _editField(TextEditingController controller, String label, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'Bitte ausfüllen' : null
            : null,
      ),
    );
  }

  Future<void> _confirmRemove(Map<String, dynamic> restaurant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lieblingsrestaurant löschen?'),
        content: Text('${restaurant['name']} wird aus deinen Favoriten entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _remove(restaurant);
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
        title: Text(widget.selectForToday ? 'Meine Restaurantfavoriten' : 'Lieblingsrestaurants'),
        actions: widget.selectForToday
            ? null
            : [
                IconButton(
                  tooltip: 'Lieblingsrestaurant hinzufügen oder importieren',
                  onPressed: _showAddOptions,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppSurface(
                      padding: const EdgeInsets.all(24),
                      color: AppDesign.surface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 36,
                            color: AppDesign.primaryDark,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Lieblingsrestaurants konnten nicht geladen werden.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppDesign.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bitte prüfe deine Verbindung und versuche es erneut.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppDesign.text,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Erneut versuchen')),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      if (_favorites.isEmpty)
                        AppSurface(
                          padding: const EdgeInsets.all(24),
                          color: AppDesign.surface,
                          child: Column(
                            children: [
                              const Icon(Icons.restaurant_menu_rounded, size: 38, color: AppDesign.primaryDark),
                              const SizedBox(height: 8),
                              Text(
                                'Noch keine Lieblingsrestaurants vorhanden',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppDesign.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Füge über das Plus oben rechts dein erstes Lieblingsrestaurant hinzu. Es erscheint dann hier.',
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
                                  child: Icon(Icons.favorite_rounded, color: AppDesign.primaryDark),
                                ),
                                title: Text(name, style: const TextStyle(color: AppDesign.text, fontWeight: FontWeight.w600)),
                                subtitle: details.isEmpty ? null : Text(details, style: const TextStyle(color: AppDesign.text)),
                                trailing: widget.selectForToday
                                    ? const Icon(Icons.chevron_right_rounded)
                                    : PopupMenuButton<String>(
                                        tooltip: 'Optionen für $name',
                                        onSelected: (action) async {
                                          if (action == 'edit') {
                                            await _editRestaurant(restaurant);
                                          } else if (action == 'delete') {
                                            await _confirmRemove(restaurant);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'edit', child: ListTile(
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text('Bearbeiten'),
                                            contentPadding: EdgeInsets.zero,
                                          )),
                                          PopupMenuItem(value: 'delete', child: ListTile(
                                            leading: Icon(Icons.delete_outline_rounded),
                                            title: Text('Löschen'),
                                            contentPadding: EdgeInsets.zero,
                                          )),
                                        ],
                                        child: const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(Icons.more_vert_rounded),
                                        ),
                                      ),
                                onTap: widget.selectForToday
                                    ? () => Navigator.pop(context, restaurant)
                                    : () => _showRestaurantDetails(restaurant),
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
