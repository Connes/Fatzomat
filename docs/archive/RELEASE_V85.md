# together V85 – UX- und Stabilitätsrunde

## Stabilität

- Realtime-Subscriptions sind gegen nicht initialisiertes Supabase in Tests, Previews und Offline-Zuständen abgesichert.
- Repository-Konstruktoren greifen erst beim tatsächlichen Datenzugriff auf Supabase zu. Dadurch können Screens robuster gemountet und getestet werden.
- Fehlerzustände auf Profil, Benachrichtigungen und Verbindung zeigen jetzt einen persistenten Retry-Zustand statt stiller oder nur kurz sichtbarer Fehler.

## UX und Navigation

- Android-Back auf den Haupttabs führt zunächst zurück zu „Start“; erst dort darf der App-Root geschlossen werden.
- Kritische Home- und Auswahlaktionen sind für Screenreader explizit als Buttons beschriftet.
- Bestehende Tooltips und verständliche Aktionsbezeichnungen wurden als Teil der UX-Regression abgesichert.

## Qualitätssicherung

- Kritische User-Flows werden in einem V85-Regressionstest auf Navigation, Accessibility, Fehlerzustände und Realtime-Lifecycle geprüft.
- Bestehende Versionsregressionen wurden auf `0.1.0+85` aktualisiert, damit die Test-Suite den aktuellen Release-Stand prüft.

Keine neue Supabase-Migration erforderlich.

Version: `0.1.0+85`
