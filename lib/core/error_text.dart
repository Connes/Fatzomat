import 'app_exception.dart';

String friendlyError(Object error) {
  final rawText = error.toString().toLowerCase();
  if (rawText.contains('pgrst202') ||
      (rawText.contains('send_decision_message') &&
          (rawText.contains('could not find the function') || rawText.contains('does not exist')))) {
    return 'Die Datenbank ist noch nicht auf die neue Entscheidungsfunktion aktualisiert. Bitte die aktuellen Supabase-Migrationen einspielen.';
  }
  if (error is ConnectionRequiredException ||
      rawText.contains('keine verbindung zu einer zweiten person') ||
      rawText.contains('für diese funktion wird eine verbindung benötigt')) {
    return 'Verbinde zuerst eine zweite Person, um diese Funktion zu nutzen.';
  }
  final normalized = normalizeAppException(error);
  final text = normalized.toString().toLowerCase();

  if (text.contains('bereits ein gemeinsames rezept')) {
    return 'Für heute ist bereits ein gemeinsames Rezept ausgewählt.';
  }
  if (text.contains('keine verbindung zu einer zweiten person')) {
    return 'Verbinde zuerst eine zweite Person, um diese Funktion zu nutzen.';
  }
  if (text.contains('tagesplan ist nicht verfügbar')) {
    return 'Der heutige Plan ist gerade nicht verfügbar. Bitte erneut versuchen.';
  }
  if (text.contains('rezept ist nicht verfügbar')) {
    return 'Dieses Rezept ist nicht mehr verfügbar.';
  }
  if (text.contains('23505') || text.contains('already')) {
    return 'Dieser Eintrag existiert bereits.';
  }
  return switch (normalized) {
    AuthenticationException() => 'Die Sitzung konnte nicht verwendet werden. Bitte App neu starten.',
    AuthorizationException() => 'Keine Berechtigung für diese Aktion.',
    NetworkException() => 'Netzwerkfehler. Bitte Verbindung prüfen und erneut versuchen.',
    ValidationException() => 'Die eingegebenen Daten sind nicht gültig. Bitte erneut versuchen.',
    BackendException(message: final message) => message,
    ConnectionRequiredException() => 'Verbinde zuerst eine zweite Person, um diese Funktion zu nutzen.',
    UnexpectedAppException() => 'Etwas ist schiefgelaufen. Bitte erneut versuchen.',
    AppException() => 'Etwas ist schiefgelaufen. Bitte erneut versuchen.',
  };
}
