import 'package:supabase_flutter/supabase_flutter.dart';

class PushDeviceRepository {
  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;
  PushDeviceRepository({SupabaseClient? client}) : _client = client;

  Future<void> saveToken(String token, {required String platform}) async {
    if (client.auth.currentUser?.id == null || token.trim().isEmpty) return;
    await client.rpc('register_push_device', params: {
      'p_device_token': token.trim(),
      'p_platform': platform,
    });
  }
}
