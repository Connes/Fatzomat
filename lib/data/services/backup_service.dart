import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/food_repository.dart';

/// Backup of personal preferences and history, excluding shared/global data.
class BackupService {
  final SupabaseClient? _client;
  final FoodRepository? _foodRepository;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  BackupService({SupabaseClient? client, FoodRepository? foodRepository})
      : _client = client,
        _foodRepository = foodRepository;

  String get _userId => client.auth.currentUser?.id ??
      (throw StateError('Keine Supabase-Sitzung vorhanden.'));

  Future<Uri?> exportPersonalBackup() async {
    final preferences =
        await (_foodRepository ?? FoodRepository(client: client)).preferences();
    final rows = await client
        .from('personal_decision_history')
        .select('recipe_id,action,source,created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: true);
    final payload = buildPayload(
      preferences: preferences,
      history: rows.map((row) => Map<String, dynamic>.from(row)).toList(),
    );
    return FilePicker.saveFile(
      dialogTitle: 'Persönliches Backup speichern',
      fileName: 'fatzomat_backup.json',
      bytes: Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
      ),
      mimeType: 'application/json',
    );
  }

  /// Validates the complete file before modifying personal data.
  /// Older v1 backups lack history; their import leaves history unchanged.
  Future<Map<String, int>?> restorePersonalBackup() async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Fatzomat-Backup auswählen',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      throw const FormatException('Die ausgewählte Datei konnte nicht gelesen werden.');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const FormatException('Die Datei enthält kein gültiges JSON-Backup.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'schmackofatz_backup') {
      throw const FormatException('Diese Datei ist kein Fatzomat-Backup.');
    }
    final version = decoded['version'];
    if (version != 1 && version != 2) {
      throw const FormatException('Diese Backup-Version wird nicht unterstützt.');
    }
    final rawPreferences = decoded['preferences'];
    if (rawPreferences is! Map) {
      throw const FormatException('Im Backup fehlen die Lebensmittelentscheidungen.');
    }
    final preferences = <String, String>{};
    for (final entry in rawPreferences.entries) {
      final id = entry.key.toString().trim();
      final value = entry.value.toString();
      if (id.isEmpty || !const {'like', 'dislike'}.contains(value)) {
        throw const FormatException('Das Backup enthält ungültige Lebensmittelentscheidungen.');
      }
      preferences[id] = value;
    }

    final hasHistory = version == 2 && decoded.containsKey('history');
    final history = <Map<String, dynamic>>[];
    if (hasHistory) {
      final rawHistory = decoded['history'];
      if (rawHistory is! List) {
        throw const FormatException('Die persönliche Historie im Backup ist ungültig.');
      }
      const actions = {'selected', 'replaced', 'servings_changed', 'status_changed', 'cancelled'};
      for (final item in rawHistory) {
        if (item is! Map) {
          throw const FormatException('Ein Historieneintrag im Backup ist ungültig.');
        }
        final row = Map<String, dynamic>.from(item);
        final action = row['action']?.toString() ?? '';
        final date = DateTime.tryParse(row['created_at']?.toString() ?? '');
        if (!actions.contains(action) || date == null) {
          throw const FormatException('Ein Historieneintrag im Backup enthält ungültige Daten.');
        }
        history.add({
          'user_id': _userId,
          'action': action,
          'source': row['source']?.toString() ?? 'today',
          'created_at': date.toUtc().toIso8601String(),
          // History is an audit trail; avoid dangling recipe/plan foreign keys.
        });
      }
    }

    // No database writes happen until the entire file has passed validation.
    final preferencesTable = client.from('user_food_preferences');
    await preferencesTable.delete().eq('user_id', _userId);
    if (preferences.isNotEmpty) {
      await preferencesTable.insert(preferences.entries
          .map((entry) => {
                'user_id': _userId,
                'food_id': entry.key,
                'preference': entry.value,
              })
          .toList(growable: false));
    }
    if (hasHistory) {
      await client.from('personal_decision_history').delete().eq('user_id', _userId);
      if (history.isNotEmpty) {
        await client.from('personal_decision_history').insert(history);
      }
    }
    return {'preferences': preferences.length, 'history': hasHistory ? history.length : -1};
  }

  @visibleForTesting
  static Map<String, dynamic> buildPayload({
    required Map<String, String> preferences,
    required List<Map<String, dynamic>> history,
  }) => {
        'format': 'schmackofatz_backup',
        'version': 2,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'preferences': preferences,
        'history': history,
      };
}
