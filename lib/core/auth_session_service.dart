import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// Keeps the client session usable before authenticated database/storage work.
///
/// Several parts of the app can issue requests while the access token expires.
/// Refresh tokens are single-use, so parallel refresh calls can invalidate one
/// another. Serialize refreshes and reuse the refreshed session.
class AuthSessionService {
  const AuthSessionService._();

  static Future<Session>? _refreshInFlight;

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
      session = await _refreshSession(supabase);
    }

    if (session.accessToken.trim().isEmpty || session.isExpired) {
      throw const AuthenticationException(
        'Die Sitzung konnte nicht erneuert werden. Bitte prüfe deine Internetverbindung und versuche es erneut.',
      );
    }
    return session;
  }

  static Future<Session> _refreshSession(SupabaseClient client) async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      try {
        final refreshed = await inFlight;
        final current = client.auth.currentSession;
        if (current != null && !current.isExpired && current.accessToken.isNotEmpty) {
          return current;
        }
        if (!refreshed.isExpired && refreshed.accessToken.isNotEmpty) return refreshed;
      } catch (_) {
        // The request that started the refresh reports the original failure.
        // A later caller gets one fresh attempt if no valid session remains.
      }
    }

    final current = client.auth.currentSession;
    if (current != null && !current.isExpired && current.accessToken.isNotEmpty) {
      return current;
    }

    final future = _performRefresh(client);
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    }
  }

  static Future<Session> _performRefresh(SupabaseClient client) async {
    try {
      final response = await client.auth.refreshSession();
      final session = response.session ?? client.auth.currentSession;
      if (session == null || session.accessToken.trim().isEmpty || session.isExpired) {
        throw const AuthenticationException(
          'Die Sitzung konnte nicht erneuert werden. Bitte prüfe deine Internetverbindung und versuche es erneut.',
        );
      }
      return session;
    } on AuthException catch (error) {
      final current = client.auth.currentSession;
      if (current != null && !current.isExpired && current.accessToken.trim().isNotEmpty) {
        return current;
      }
      throw AuthenticationException(
        'Die Sitzung konnte nicht erneuert werden. Bitte prüfe deine Internetverbindung und versuche es erneut.',
        error,
      );
    }
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
      await _refreshSession(client);
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
