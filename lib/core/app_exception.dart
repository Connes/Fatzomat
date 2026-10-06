import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AppException implements Exception {
  final String message;
  final Object? cause;
  const AppException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class AuthenticationException extends AppException {
  const AuthenticationException(
    [String? message, Object? cause]
  ) : super(message ?? 'Die Sitzung ist nicht mehr gültig.', cause);
}

class AuthorizationException extends AppException {
  const AuthorizationException(
    [String? message, Object? cause]
  ) : super(message ?? 'Keine Berechtigung für diese Aktion.', cause);
}

class NetworkException extends AppException {
  const NetworkException(
    [String? message, Object? cause]
  ) : super(message ?? 'Netzwerkfehler. Bitte Verbindung prüfen.', cause);
}

class ValidationException extends AppException {
  const ValidationException(
    [String? message, Object? cause]
  ) : super(message ?? 'Die eingegebenen Daten sind nicht gültig.', cause);
}

class BackendException extends AppException {
  const BackendException(
    [String? message, Object? cause]
  ) : super(message ?? 'Der Server konnte die Anfrage nicht verarbeiten.', cause);
}

class ConnectionRequiredException extends AppException {
  const ConnectionRequiredException([String? message, Object? cause])
      : super(message ?? 'Für diese Funktion wird eine Verbindung benötigt.', cause);
}

class UnexpectedAppException extends AppException {
  const UnexpectedAppException(
    [String? message, Object? cause]
  ) : super(message ?? 'Etwas ist schiefgelaufen. Bitte erneut versuchen.', cause);
}

AppException normalizeAppException(Object error) {
  if (error is AppException) return error;

  if (error is PostgrestException) {
    final message = error.message;
    final details = error.details?.toString() ?? '';
    final hint = error.hint?.toString() ?? '';
    final combined = '$message $details $hint'.toLowerCase();
    final code = error.code?.toUpperCase() ?? '';

    if (combined.contains('keine zweite person ist verbunden') ||
        combined.contains('keine verbindung zu einer zweiten person') ||
        combined.contains('für diese funktion wird eine verbindung benötigt')) {
      return ConnectionRequiredException(
        'Verbinde zuerst eine zweite Person, um diese Funktion zu nutzen.',
        error,
      );
    }
    if (code == '42501' || combined.contains('permission denied') || combined.contains('forbidden')) {
      return AuthorizationException('Keine Berechtigung für diese Aktion.', error);
    }
    if (code == '23505') {
      return ValidationException('Dieser Eintrag existiert bereits.', error);
    }
    if (code.startsWith('23') || code == '22P02' || code == '22007') {
      return ValidationException('Die eingegebenen Daten sind nicht gültig.', error);
    }
    if (code.startsWith('5')) {
      return BackendException('Der Server konnte die Anfrage nicht verarbeiten.', error);
    }
    return BackendException(message.isNotEmpty
        ? message
        : 'Der Server konnte die Anfrage nicht verarbeiten.', error);
  }
  final text = error.toString().toLowerCase();
  if (text.contains('jwt') || text.contains('401') || text.contains('auth')) {
    return AuthenticationException('Die Sitzung ist nicht mehr gültig.', error);
  }
  if (text.contains('42501') || text.contains('permission') || text.contains('forbidden') || text.contains('403')) {
    return AuthorizationException('Keine Berechtigung für diese Aktion.', error);
  }
  if (text.contains('network') || text.contains('socket') || text.contains('timeout') || text.contains('connection')) {
    return NetworkException('Netzwerkfehler. Bitte Verbindung prüfen.', error);
  }
  if (text.contains('400') || text.contains('422') || text.contains('invalid') || text.contains('ungültig')) {
    return ValidationException('Die eingegebenen Daten sind nicht gültig.', error);
  }
  if (text.contains('500') || text.contains('502') || text.contains('503') || text.contains('server')) {
    return BackendException('Der Server konnte die Anfrage nicht verarbeiten.', error);
  }
  return UnexpectedAppException('Etwas ist schiefgelaufen. Bitte erneut versuchen.', error);
}
