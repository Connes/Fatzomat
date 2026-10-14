import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/personal_today_repository.dart';

class ChatGptRestaurantPage extends StatefulWidget {
  final DateTime? planDate;
  final VoidCallback? onNavigateToToday;

  const ChatGptRestaurantPage({super.key, this.planDate, this.onNavigateToToday});

  @override
  State<ChatGptRestaurantPage> createState() => _ChatGptRestaurantPageState();
}

class _ChatGptRestaurantPageState extends State<ChatGptRestaurantPage> {
  static const _cuisines = <String>[
    'Griechisch', 'Italienisch', 'Türkisch', 'Japanisch', 'Chinesisch',
    'Thailändisch', 'Vietnamesisch', 'Koreanisch', 'Indonesisch',
    'Malaysisch', 'Sushi', 'Burger', 'Steak', 'Mexikanisch', 'Spanisch',
    'Libanesisch', 'Portugiesisch', 'Vegetarisch', 'Vegan',
  ];

  String _cuisine = 'Griechisch';
  final _locationController = TextEditingController();
  String? _error;
  Map<String, dynamic>? _restaurant;
  bool _importing = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  String get _prompt {
    final location = _locationController.text.trim();
    final start = location.isEmpty
        ? 'Ermittle meinen Standort nicht selbst. Frage mich zuerst nach meinem Ort oder meiner Adresse und fahre erst nach meiner Antwort fort.'
        : 'Ausgangspunkt für die Suche: $location.';
    return '''
Finde aktuelle Restaurants mit Küche „$_cuisine“ in einem Radius von 10 Kilometern um folgenden Ausgangspunkt: $start
Recherchiere mithilfe aktueller Webquellen. Bevorzuge offizielle Restaurant-Webseiten und verlässliche Quellen. Nenne zuerst eine übersichtliche Auswahl passender Restaurants. Gib nur Restaurants innerhalb des 10-km-Radius aus; wenn die Entfernung nicht zuverlässig überprüfbar ist, kennzeichne den Treffer nicht als bestätigt innerhalb des Radius.
Ermittle ausschließlich diese Daten: Name, Küche, Adresse, Telefonnummer, Webseite und Öffnungszeiten. Erfinde keine Angaben. Nicht verifizierbare oder unbekannte Telefonnummern, Webseiten oder Öffnungszeiten müssen null sein.
Wenn ich ein Restaurant ausgewählt habe und ausdrücklich die Fatzomat-Importdatei anfordere, gib ausschließlich gültiges JSON ohne Markdown-Codeblock und ohne zusätzliche Erklärung aus. Verwende exakt dieses Schema und keine weiteren Felder:
{
  "schema_version": 1,
  "type": "fatzomat_restaurant_suggestion",
  "restaurant": {
    "name": "Restaurantname",
    "cuisine": "$_cuisine",
    "address": "Straße Hausnummer, PLZ Ort",
    "phone": null,
    "website": null,
    "opening_hours": null
  }
}
name, cuisine und address sind Pflichtfelder und müssen nicht-leere Strings sein. phone, website und opening_hours sind optionale Strings oder null. website muss eine vollständige HTTP(S)-URL sein. opening_hours soll, wenn bekannt, die Wochentage und Zeiträume als Text enthalten. Gib keine Bewertungen, Preise, Entfernung, Beschreibung, Fotos oder andere Felder aus. Die JSON-Datei wird direkt in Fatzomat importiert und muss syntaktisch gültig sein.
'''.trim();
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Such-Prompt wurde kopiert.')),
    );
  }

  Future<void> _openChatGpt() async {
    await SharePlus.instance.share(
      ShareParams(
        text: _prompt,
        title: 'Restaurant-Suche mit ChatGPT',
      ),
    );
  }

  Future<void> _pickJson() async {
    setState(() {
      _error = null;
      _restaurant = null;
      _importing = true;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (result.isEmpty) return;
      final file = result.first;
      final bytes = await File(file.path!).readAsBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Die JSON-Datei muss ein Objekt enthalten.');
      }
      if (decoded['schema_version'] != 1 ||
          decoded['type'] != 'fatzomat_restaurant_suggestion') {
        throw const FormatException('Unbekanntes JSON-Format. Bitte die Fatzomat-Importdatei verwenden.');
      }
      final restaurant = decoded['restaurant'];
      if (restaurant is! Map<String, dynamic>) {
        throw const FormatException('Der Bereich „restaurant“ fehlt.');
      }
      String requiredString(String key) {
        final value = restaurant[key];
        if (value is! String || value.trim().isEmpty) {
          throw FormatException('Das Pflichtfeld „$key“ fehlt oder ist ungültig.');
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
      final website = restaurant['website'] as String?;
      if (website != null) {
        final uri = Uri.tryParse(website);
        if (uri == null || !uri.hasAuthority || !{'http', 'https'}.contains(uri.scheme)) {
          throw const FormatException('Die Webseite muss eine gültige HTTP(S)-Adresse sein.');
        }
      }
      if (!mounted) return;
      setState(() {
        _restaurant = {
          'name': name,
          'cuisine': cuisine,
          'address': address,
          'phone': restaurant['phone'] as String?,
          'website': website,
          'opening_hours': restaurant['opening_hours'] as String?,
        };
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Import fehlgeschlagen: $error');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _useRestaurant() async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Als heutigen Vorschlag übernehmen?'),
        content: Text('${restaurant['name']} wird als Restaurantvorschlag für den ausgewählten Tag gespeichert.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Übernehmen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // Existing personal-day decisions store a type and value. Persist the
      // validated restaurant payload in that value to avoid a second datastore.
      await PersonalTodayRepository().selectDecision(
        type: 'dine_out',
        value: jsonEncode({
          'type': 'fatzomat_restaurant_suggestion',
          'schema_version': 1,
          'restaurant': restaurant,
        }),
        date: widget.planDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant wurde als Tagesvorschlag übernommen.')),
      );
      widget.onNavigateToToday?.call();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant konnte nicht gespeichert werden: $error')),
      );
    }
  }

  Widget _detail(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 112, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: SelectableText(value)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(title: const Text('Mit ChatGPT suchen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurface(
            padding: const EdgeInsets.all(18),
            color: AppDesign.surface.withValues(alpha: .97),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Restaurant finden', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Wähle die Küche und gib einen Ort oder eine Adresse als Ausgangspunkt an.'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _cuisine,
                decoration: const InputDecoration(labelText: 'Küche'),
                items: _cuisines.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (value) => setState(() => _cuisine = value ?? _cuisine),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ort oder Adresse',
                  hintText: 'z. B. Pforzheim',
                  helperText: 'Wird für den 10-km-Suchradius in den Prompt übernommen.',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openChatGpt,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Prompt an ChatGPT übergeben'),
              ),
              OutlinedButton.icon(
                onPressed: _copyPrompt,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Nur Prompt kopieren'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppSurface(
            padding: const EdgeInsets.all(18),
            color: AppDesign.surface.withValues(alpha: .97),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Restaurant-JSON importieren', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Wähle die von ChatGPT erstellte Fatzomat-JSON-Datei aus. Du siehst die Daten vor dem Speichern.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _importing ? null : _pickJson,
                icon: _importing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.file_upload_outlined),
                label: const Text('JSON-Datei auswählen'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_restaurant != null) ...[
                const SizedBox(height: 14),
                Text('Vorschau', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _detail('Name', _restaurant!['name'] as String?),
                _detail('Küche', _restaurant!['cuisine'] as String?),
                _detail('Adresse', _restaurant!['address'] as String?),
                _detail('Telefon', _restaurant!['phone'] as String?),
                _detail('Webseite', _restaurant!['website'] as String?),
                _detail('Öffnungszeiten', _restaurant!['opening_hours'] as String?),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _useRestaurant,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Als heutigen Vorschlag übernehmen'),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
