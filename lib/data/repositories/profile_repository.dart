import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  ProfileRepository({SupabaseClient? client})
      : _client = client;

  String get userId => client.auth.currentUser?.id ??
      (throw StateError('Keine Supabase-Sitzung vorhanden.'));

  Future<bool> onboardingCompleted() async {
    final row = await client
        .from('profiles')
        .select('onboarding_completed')
        .eq('id', userId)
        .maybeSingle();
    return row?['onboarding_completed'] == true;
  }

  Future<void> completeOnboarding(Map<String, String> preferences) async {
    if (preferences.isNotEmpty) {
      await client.from('user_food_preferences').upsert(
        preferences.entries
            .map((entry) => {
                  'user_id': userId,
                  'food_id': entry.key,
                  'preference': entry.value,
                })
            .toList(),
      );
    }
    await client.from('profiles').upsert({
      'id': userId,
      'onboarding_completed': true,
    });
  }
}
