import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// Keeps the client session usable before authenticated database/storage work.
///
/// supabase_flutter restores a persisted session during initialization, but the
/// restored access token may already be expired. In that case currentSession
/// can be non-null while the next API request still receives 401.
class AuthSessionService {
  const AuthSessionService._();

  static Future<Session> ensureValidSession({SupabaseClient? client}) async {
    final supabase = client ?? Supabase.instance.client;
    var session = supabase.auth.currentSession;

    if (session == null) {
      try {
        final response = await supabase.auth.signInAnonymously();
        session = response.session ?? supabase.auth.currentSession;
      } on AuthException catch (error) {
        throw AuthenticationException('Die Sitzung konnte nicht aufgebaut werden.', error);
      }
    }

    if (session == null) {
      throw const AuthenticationException();
    }

    if (session.isExpired) {
      try {
        final response = await supabase.auth.refreshSession();
        session = response.session ?? supabase.auth.currentSession;
      } on AuthException catch (error) {
        throw AuthenticationException('Die Sitzung konnte nicht erneuert werden.', error);
      }
    }

    if (session == null || session.accessToken.trim().isEmpty || session.isExpired) {
      throw const AuthenticationException('Die Sitzung ist abgelaufen. Bitte App neu starten.');
    }
    return session;
  }

  static Future<T> runWithRefresh<T>({
    required SupabaseClient client,
    required Future<T> Function() action,
  }) async {
    await ensureValidSession(client: client);
    try {
      return await action();
    } catch (error) {
      if (!_looksLikeAuthenticationFailure(error)) rethrow;
      final response = await client.auth.refreshSession();
      final session = response.session ?? client.auth.currentSession;
      if (session == null || session.accessToken.trim().isEmpty || session.isExpired) {
        throw AuthenticationException('Die Sitzung konnte nicht erneuert werden.', error);
      }
      return action();
    }
  }

  static bool _looksLikeAuthenticationFailure(Object error) {
    if (error is AuthException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('401') ||
        text.contains('jwt') ||
        text.contains('unauthorized') ||
        text.contains('invalid token') ||
        text.contains('session missing') ||
        text.contains('session is missing');
  }
}
