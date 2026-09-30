# V82 – Entscheidungsanfragen stabilisieren und nachvollziehbar machen

## Ziel
Der Übergang „Du entscheidest heute“ behandelt jetzt auch bereits laufende oder inzwischen erledigte Anfragen sauber. Stale Benachrichtigungen führen nicht mehr in einen scheinbar offenen Auswahlbildschirm, und der Absender kann eine aktive Anfrage kontrolliert zurücknehmen.

## Änderungen
- Startseite prüft vor dem Erstellen einer neuen Entscheidungsanfrage, ob bereits eine aktive Anfrage des Benutzers existiert.
- Bei einer aktiven Anfrage wird der aktuelle Zustand angezeigt: noch offen oder bereits angenommen.
- Eine eigene aktive Anfrage kann aus der Startseite zurückgenommen werden.
- Die Empfängerseite lädt beim Öffnen den aktuellen Serverstatus der Anfrage nach.
- Bereits zurückgenommene, abgeschlossene oder anderweitig nicht mehr offene Anfragen zeigen einen eindeutigen Status statt auswählbarer Aktionen.
- Eine bereits angenommene Anfrage muss nicht erneut über den Annahme-RPC bestätigt werden.
- Benachrichtigungen für angenommene und zurückgenommene Entscheidungsanfragen werden passend dargestellt.
- Das Zurücknehmen einer Anfrage erzeugt eine In-App-Benachrichtigung beim Empfänger.
- Keine Änderung an den vier freigegebenen Entscheidungskarten.
- Version auf `0.1.0+82` erhöht.

## Datenbank
Neue Migration: `supabase/migrations/202609160002_v82_decision_request_polish.sql`

- `cancel_decision_request` wird um die Benachrichtigung an den Empfänger ergänzt.
- Die bestehende Statuslogik bleibt erhalten.

## Absichtlich nicht geändert
- Kein Chat-System.
- Keine OS-Push-Infrastruktur.
- Keine neue Verbindungssystematik.
- Keine Änderung am Ergebnis-/Rezeptauflösungsmodell.

## V82 Fix1
- `acceptDecisionRequest()` ist ein `Future<void>` und wird entsprechend ohne Bool-Rückgabewert behandelt.
- Nicht-konstantes `AppBar`-Konstrukt im Ladezustand korrigiert.
- Unbenutzten `_activeDecisionRequest`-State entfernt.
- `BuildContext`-Zugriff nach dem asynchronen Partner-Lookup durch `mounted` abgesichert.
