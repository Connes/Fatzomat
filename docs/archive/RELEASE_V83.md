# V83 – Benachrichtigungen live und direkt nutzbar

## Ziel

Benachrichtigungen sollen nicht erst nach einem Seitenwechsel sichtbar werden. Der Hinweiszähler im Profil aktualisiert sich jetzt über Supabase Realtime. Benachrichtigungen zu einem gemeinsamen Rezept führen direkt zur Heute-Seite. Entscheidungsanfragen behalten ihren bestehenden Status- und Sicherheitsflow.

## Änderungen

- Der ungelesene Benachrichtigungszähler im Profil reagiert live auf neue, gelesene und aktualisierte Benachrichtigungen.
- Der Realtime-Channel des Profils ist pro angemeldetem Benutzer eindeutig und wird beim Verlassen der Seite sauber entfernt.
- Die Benachrichtigungsseite zeigt die aktuelle Anzahl ungelesener Hinweise direkt in der AppBar.
- Hinweise zu gemeinsamen Rezepten öffnen direkt „Heute“.
- Entscheidungsanfragen werden weiterhin anhand ihres aktuellen Serverstatus geöffnet; erledigte oder zurückgenommene Anfragen öffnen keine veraltete Auswahl.
- Nach Navigation aus einer Benachrichtigung wird die Liste erneut geladen.
- Keine neue Datenbankmigration erforderlich. `app_notifications` ist bereits seit V57 für Realtime aktiviert.
- Version auf `0.1.0+83` erhöht.

## Absichtlich nicht geändert

- Keine Änderung an den vier Entscheidungskarten.
- Keine neue Push-Infrastruktur.
- Keine Änderung am Berechtigungs- oder RLS-Modell.
- Keine Änderung an Tagesplan- oder Einkaufslisten-RPCs.
