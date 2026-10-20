import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/app_shell.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../data/repositories/restaurant_favorites_repository.dart';


class _LocationAccessRequired implements Exception {
  final String message;

  const _LocationAccessRequired(this.message);
}

class ChatGptRestaurantPage extends StatefulWidget {
  final DateTime? planDate;
  final String initialCuisine;
  final bool autoOpenChatGpt;
  const ChatGptRestaurantPage({
    super.key,
    this.planDate,
    this.initialCuisine = 'Griechisch',
    this.autoOpenChatGpt = false,
  });

  @override
  State<ChatGptRestaurantPage> createState() => _ChatGptRestaurantPageState();
}

class _ChatGptRestaurantPageState extends State<ChatGptRestaurantPage> {
  late String _cuisine;
  final _locationController = TextEditingController();
  String? _error;
  Map<String, dynamic>? _restaurant;
  bool _importing = false;
  bool _locating = false;
  bool _waitingForLocationSettings = false;

  @override
  void initState() {
    super.initState();
    _cuisine = widget.initialCuisine;
    _determineCurrentLocation();
  }

  Future<void> _determineCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _locating = true;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationAccessRequired(
          'Die Standortdienste sind ausgeschaltet. Aktiviere sie, damit Fatzomat Restaurants in deiner Nähe finden kann.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _LocationAccessRequired(
          'Ohne Standortfreigabe kann Fatzomat keine Restaurants in deiner Nähe suchen. Öffne die Systemeinstellungen und erlaube den Standortzugriff. Danach kannst du hier fortfahren.',
        );
      }
      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 15),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final parts = <String?>[
        place?.street,
        place?.subLocality,
        place?.locality,
        place?.postalCode,
      ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
      final resolved = parts.toSet().join(', ');
      final location = resolved.isNotEmpty
          ? resolved
          : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      if (!mounted) return;
      _locationController.text = location;
    } on _LocationAccessRequired catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _waitingForLocationSettings = true;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'Der Standort konnte nicht rechtzeitig ermittelt werden. Prüfe GPS und versuche es erneut.';
        _waitingForLocationSettings = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
      if (mounted && widget.autoOpenChatGpt && !_waitingForLocationSettings && _locationController.text.trim().isNotEmpty) {
        await _launchChatGptWithPrompt();
      }
    }
  }

  Future<void> _openLocationSettings() async {
    final opened = await Geolocator.openAppSettings();
    if (!opened && mounted) {
      AppFeedback.showSnackBar(
        context,
        const SnackBar(content: Text('Die Systemeinstellungen konnten nicht geöffnet werden. Bitte öffne sie manuell.')),
      );
    }
  }

  Future<void> _retryLocationAndContinue() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _waitingForLocationSettings = false;
    });
    await _determineCurrentLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  String get _prompt {
    final location = _locationController.text.trim();
    final start = location.isEmpty
        ? 'Der aktuelle Standort konnte von Fatzomat nicht ermittelt werden. Verwende keine erfundene Position; weise darauf hin, dass der Standortzugriff aktiviert werden muss.'
        : 'Ausgangspunkt für die Suche (aktueller Gerätestandort): $location.';
    return '''
Finde aktuelle Restaurants mit Küche „$_cuisine“ in der Nähe des folgenden Ausgangspunkts: $start
Recherchiere mithilfe aktueller Webquellen. Bevorzuge offizielle Restaurant-Webseiten und verlässliche Quellen. Nenne zuerst eine übersichtliche Auswahl passender Restaurants. 
Ermittle ausschließlich diese Daten: Name, Küche, Adresse, Telefonnummer, Webseite und Öffnungszeiten. Erfinde keine Angaben. Nicht verifizierbare oder unbekannte Telefonnummern, Webseiten oder Öffnungszeiten müssen null sein.
Sobald ich eines der vorgeschlagenen Restaurants auswähle oder eindeutig benenne, erstelle die Fatzomat-Importdatei AUTOMATISCH in derselben Antwort. Warte nicht darauf, dass ich die Datei zusätzlich anfordere, und frage nicht nach, ob ich sie haben möchte. Erzeuge eine echte, herunterladbare Datei als ChatGPT-Dateianhang im Format JSON und stelle sie mit einem direkten Download-Link bereit. Ein bloßer JSON-Text im Chat, eine Ankündigung oder eine Beschreibung der Datei genügt nicht. Verwende für den Dateinamen einen kurzen, aussagekräftigen Restaurantnamen, z. B. steakhouse_tango_import.json. Die Datei muss exakt dem folgenden Schema entsprechen und darf keine zusätzlichen Felder enthalten:
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
name, cuisine und address sind Pflichtfelder und müssen nicht-leere Strings sein. phone, website und opening_hours sind optionale Strings oder null. website muss eine vollständige HTTP(S)-URL sein. opening_hours soll, wenn bekannt, die Wochentage und Zeiträume als Text enthalten. Gib keine Bewertungen, Preise, Beschreibung, Fotos oder andere Felder aus. Die JSON-Datei wird direkt in Fatzomat importiert und muss syntaktisch gültig sein.
'''.trim();
  }

  Future<bool> _tryLaunchChatGpt() async {
    try {
      final uri = Uri.https('chatgpt.com', '/', {'q': _prompt});
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Missing platform handlers and unsupported launchers must not crash
      // the restaurant flow. The prompt remains available for manual sharing.
      return false;
    }
  }

  Future<void> _launchChatGptWithPrompt() async {
    final launched = await _tryLaunchChatGpt();
    if (!launched && mounted) {
      AppFeedback.showSnackBar(context, 
        const SnackBar(content: Text('ChatGPT konnte nicht automatisch geöffnet werden. Du kannst den Prompt unten manuell öffnen.')),
      );
    }
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

  Future<void> _saveAsFavorite() async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    try {
      final added = await RestaurantFavoritesRepository().add(restaurant);
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
        SnackBar(
          content: Text(added
              ? '${restaurant['name']} wurde in deinen Restaurantfavoriten gespeichert.'
              : '${restaurant['name']} ist bereits in deinen Restaurantfavoriten.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
        SnackBar(content: Text('Favorit konnte nicht gespeichert werden: $error')),
      );
    }
  }

  Future<void> _useRestaurant() async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    if (!mounted) return;
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
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('fatzomat_pending_restaurant_import_cuisine');
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
        const SnackBar(content: Text('Restaurant wurde als Tagesvorschlag übernommen.')),
      );
      // This page can be opened from a nested flow or as a root route.
      // Persisting the decision must succeed even when there is no route to pop.
      // When pushed by FoodModePage, return true so the parent can finish its flow.
      // In the regular flow, return the result to FoodModePage and let the
      // Today page refresh after its route has been popped.
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(true);
      } else {
        // An external file import can make this page the root route, with no
        // Today page or global navigation underneath it. Rebuild the normal
        // app shell after saving so the user is not stranded on the import UI.
        navigator.pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (_) => AppShell(initialDate: widget.planDate),
          ),
          (route) => false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
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
    // When launched directly from a cuisine choice, keep the app content
    // neutral while Android displays the location permission dialog.
    if (widget.autoOpenChatGpt && _locating) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F1EA),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(height: 16),
                Text(
                  'Standort wird ermittelt …',
                  style: TextStyle(color: Color(0xFF514D46)),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              Text('Restaurant-JSON importieren', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
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
                if (_waitingForLocationSettings) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openLocationSettings,
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Systemeinstellungen öffnen'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _locating ? null : _retryLocationAndContinue,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Berechtigung prüfen und fortfahren'),
                  ),
                ],
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saveAsFavorite,
                  icon: const Icon(Icons.favorite_border_rounded),
                  label: const Text('In Restaurantfavoriten speichern'),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
