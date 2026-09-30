# Schmackofatz Push-Benachrichtigungen

## Was jetzt implementiert ist

- FCM-Gerätetoken werden pro anonymem Schmackofatz-Benutzer in `public.push_devices` gespeichert.
- Android 13+ fragt die Systemberechtigung für Benachrichtigungen an.
- Vordergrund: Schmackofatz zeigt eine lokale Systembenachrichtigung.
- Hintergrund/geschlossene App: FCM zeigt die Systembenachrichtigung.
- Tippen auf die Benachrichtigung öffnet Schmackofatz und anschließend direkt die betreffende Nachricht in `Benachrichtigungen`.
- `app_notifications` bleibt die fachliche Quelle. Die Push-Schicht ist nur der Transport.
- Ungültige FCM-Gerätetoken werden vom Push-Edge-Function-Versand entfernt.

## Noch erforderliche externe Konfiguration

Die Flutter-App hatte bisher kein Firebase-Projekt. Ohne Firebase-Projekt kann kein Android-Gerät einen FCM-Registrierungstoken erhalten. Firebase verlangt außerdem die Android-App-Konfiguration und bei Android 13+ die Benachrichtigungsberechtigung. 

### 1. Firebase Android-App

Firebase Console: Android-App mit Paket-ID `com.example.food_app_mvp` anlegen.

Benötigte nicht-geheime Werte:

- API key
- App ID
- Messaging sender ID
- Project ID

Beim Build als `--dart-define` setzen. Beispiel:

```bash
flutter build apk \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

Alternativ kann später `flutterfire configure` verwendet werden und `lib/firebase_options.dart` durch die generierte Konfiguration ersetzt werden.

### 2. Supabase Edge Function Secrets

Für `push-notification` müssen gesetzt werden:

- `FCM_SERVICE_ACCOUNT_JSON`: kompletter Firebase-Service-Account als JSON-String
- `SUPABASE_SECRET_KEYS`: wird von Supabase Edge Functions automatisch bereitgestellt; die aktuelle Function verwendet den Default-Secret-Key für den serverseitigen REST-Zugriff
- `SUPABASE_SERVICE_ROLE_KEY`: Legacy-Fallback, falls der neue Secret-Key nicht verfügbar ist

Optional:

- `PUSH_WEBHOOK_SECRET`

Der Service-Account gehört ausschließlich in Supabase Secrets, niemals in die Flutter-App oder ins ZIP.

### 3. Datenbank-Transport (pg_net)

Die Migration `20260927090000_enable_pg_net_for_push_webhook.sql` aktiviert `pg_net`. Ohne diese Extension kann der Trigger `push_notifications_webhook()` die Edge Function nicht aufrufen.

### 4. Database Webhook

In Supabase einen Database Webhook anlegen:

- Tabelle: `public.app_notifications`
- Event: `INSERT`
- Methode: `POST`
- Ziel: Edge Function `push-notification`
- Authorization: Supabase-Service-Key für den Webhook
- Content-Type: `application/json`

Supabase dokumentiert genau dieses Muster: Database Webhooks werden nach dem Datenbank-Insert asynchron ausgelöst und können eine Edge Function zum Push-Versand aufrufen.

## Aktueller technischer Status

Die App-Registrierung funktioniert bereits: FCM-Tokens werden erfolgreich über `register_push_device` in `public.push_devices` gespeichert. Die fachlichen `app_notifications` werden ebenfalls erzeugt. Für den tatsächlichen Versand benötigt die Edge Function zusätzlich das Secret `FCM_SERVICE_ACCOUNT_JSON`.

Das Secret wird **nicht** in Git, ZIP-Dateien oder die Flutter-App gelegt. Firebase empfiehlt für Serverzugriffe einen Service-Account mit privatem JSON-Schlüssel; Supabase stellt Produktions-Secrets für Edge Functions über Dashboard oder `supabase secrets set` bereit.

**Wichtig:** Der Secret-Name muss exakt `FCM_SERVICE_ACCOUNT_JSON` lauten. Ein Name wie `Name: FCM_SERVICE_ACCOUNT_JSON` ist falsch. Das Dashboard zeigt den Secret-Namen als Environment-Variable an; zusätzliche Präfixe gehören nicht in das Namensfeld.

Die aktuelle Diagnose in der produktiven Edge Function hat bestätigt, dass unter `FCM_SERVICE_ACCOUNT_JSON` momentan kein Wert ankommt, obwohl im Dashboard ein ähnlich benannter Eintrag sichtbar ist.

Am sichersten ist es, den vorhandenen Eintrag zu löschen und neu anzulegen, mit:

- **Name:** `FCM_SERVICE_ACCOUNT_JSON`
- **Value:** der komplette Inhalt der Firebase-Service-Account-JSON

Alternativ kann das mit dem Projekt-Script erledigt werden:

```bash
./scripts/set_fcm_service_account_secret.sh /pfad/firebase-service-account.json
```

Das Script prüft vorher `project_id`, `client_email` und `private_key` und setzt anschließend exakt den richtigen Secret-Namen.

Danach ist kein Redeploy nötig, die aktuelle Push-Function ist bereits auf die neue Secret-Key-Konfiguration vorbereitet.

## Verhalten

`Entscheide Du` und `Entscheidung teilen` schreiben zuerst wie bisher eine `app_notifications`-Zeile. Der Webhook löst danach den Push-Versand aus. Ein Tipp auf den Push enthält die ID der In-App-Benachrichtigung und öffnet genau diese Nachricht.

### Firebase API-Timeout beim Setup

`setup.sh` darf bei einem Timeout der Firebase API kein neues Projekt anlegen. Wenn `flutterfire configure` deshalb den Dialog `Would you like to create a new Firebase project?` anzeigt, beantwortet das Skript ihn automatisch mit `n` und bricht mit einer Diagnose ab.

Prüfe dann:

```bash
firebase login:list
firebase projects:list --project=schmackofatz-25cce
```

Ein VPN, DNS-Filter, Proxy oder eine Firewall kann den Zugriff auf die Firebase API blockieren.
