# together V84 – Entscheidungsstatus live auf der Startseite

## Ziel

Der Status einer von der Startseite gesendeten Entscheidungsanfrage soll nicht erst beim nächsten manuellen Tippen aktualisiert werden. Die Startseite synchronisiert den eigenen offenen Request jetzt per Supabase Realtime.

## Änderungen

- Home lädt den aktuellen eigenen aktiven Entscheidungsrequest und hält ihn lokal vor.
- Änderungen an `decision_requests` für den angemeldeten Ersteller werden per Realtime erkannt.
- Der CTA zeigt bei einem aktiven eigenen Request `Entscheidungsanfrage läuft`.
- Der bestehende Dialog zum Zurücknehmen bleibt über den CTA erreichbar.
- Nach Erstellen oder Zurücknehmen wird der lokale Status sofort neu geladen.
- Der Realtime-Channel ist benutzerbezogen und wird beim Verlassen der Seite entfernt.
- Keine neue Migration erforderlich, da `decision_requests` bereits für Supabase Realtime aktiviert ist.
- Version auf `0.1.0+84` erhöht.

## Absichtlich nicht geändert

- Keine Änderung an den vier Entscheidungskarten.
- Keine Änderung am Entscheidungs-RPC oder RLS-Modell.
- Keine Änderung am Benachrichtigungsmodell.
