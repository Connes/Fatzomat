# Schmackofatz v1.13.0 – Push-Tap direkt zur geteilten Entscheidung

## Änderung

Wenn eine persönliche Essensentscheidung geteilt wird und die verbundene Person die Push-Benachrichtigung antippt, öffnet Schmackofatz jetzt direkt die `DecisionSharePage` für diese geteilte Entscheidung.

## Ablauf

1. `app_notifications` enthält die `decision_share_id`.
2. Die Push-Edge-Function übergibt `decision_share_id` als FCM-Datenelement.
3. Die Flutter-Push-Schicht übernimmt diese ID bei:
   - App im Hintergrund
   - App beendet / Start über Push
   - App im Vordergrund über lokale Notification
4. Die geteilte Entscheidung wird geladen.
5. Die `DecisionSharePage` wird direkt geöffnet.
6. Der Empfänger kann dort mit `Übernehmen` seine persönliche heutige Entscheidung übernehmen.
7. Falls die geteilte Entscheidung nicht geladen werden kann, bleibt der bisherige Fallback über die Benachrichtigungsseite erhalten.

## Sicherheit

Es wird weiterhin nur die bereits serverseitig für den Empfänger sichtbare `decision_share_id` verwendet. Die eigentliche Entscheidung wird anschließend über die bestehende Supabase-RLS-geschützte Abfrage geladen.
