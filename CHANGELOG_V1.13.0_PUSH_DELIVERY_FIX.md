# Schmackofatz v1.13.0: Push-Zustellung repariert

- Setup und App-Start konfigurieren Firebase automatisch mit FlutterFire für das bestehende Projekt `schmackofatz-25cce`.
- Push-Initialisierung bleibt bei transienten Firebase-/Berechtigungsfehlern retrybar.
- FCM-Gerätetokens werden über `register_push_device` sicher dem aktuellen authentifizierten Benutzer zugeordnet.
- Dadurch kann ein Token nach einem Wechsel der anonymen Supabase-Identität erneut registriert werden.
- Regressionstest für Firebase-Konfiguration und Token-RPC ergänzt.
