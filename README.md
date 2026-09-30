# Schmackofatz

Flutter + Supabase recipe app with anonymous device identity, personal food preferences, recipe workflows and shared food planning. Der ChatGPT-Import benötigt keine OpenAI-API im Client.

## V1.4 technical baseline

- Supabase RLS and authenticated-only client access
- Anonymous authentication without a visible login
- Typed `Food` and `Recipe` domain models
- Structured food taxonomy (`dietary_type`, `protein_type`, allergens)
- Rezeptgenerierung über den externen ChatGPT-Workflow ohne OpenAI-API-Kosten
- Last-known read cache for foods and today's shared plan
- No fake offline mutation queue claims
- CI: analyze, tests, Android debug + release build
- Release verification with `pubspec.lock` enforcement

## Anmeldung ohne Login

Die App verwendet bewusst keinen sichtbaren Login. Beim ersten Start wird über Supabase eine anonyme Benutzeridentität angelegt. Supabase ordnet diese Sitzung der Rolle `authenticated` zu, sodass die RLS-Regeln persönliche Daten schützen können.

Eine anonyme Identität ist zunächst an das Gerät gebunden. Über „Daten sichern“ können Rezepte und Präferenzen zusätzlich als lokale JSON-Sicherung exportiert werden. Über „Konto sichern“ kann die anonyme Identität mit E-Mail und Passwort für einen späteren Gerätewechsel abgesichert werden.

## Lokales Setup

1. Vollständiges Repository inklusive `android/`, `ios/` und `pubspec.lock` verwenden.
2. Die lokale Supabase-Konfiguration wird **einmalig pro Rechner** unter `~/.config/together/.env.local` gespeichert. Sie gehört nicht ins Repository und nicht in Release-ZIPs.
3. `./setup.sh` ausführen. Das Script lädt Dependencies, erzeugt das App-Icon und führt Repository-, Architektur-, Analyse- und Testprüfungen aus.
4. Für die komplette Release-Prüfung: `./setup.sh --full`.

### Lokale Konfiguration

Die Datei `~/.config/together/.env.local` enthält `SUPABASE_URL` und `SUPABASE_PUBLISHABLE_KEY`. Bei einem neuen Projekt-ZIP wird diese Konfiguration automatisch wiederverwendet. Existiert noch keine zentrale Konfiguration, übernimmt `setup.sh` beim ersten Start eine vorhandene `.env.local` aus einem benachbarten Projektordner, sofern vorhanden. Dadurch müssen die Werte beim Projektwechsel nicht erneut eingetragen werden.

Falls gar keine Konfiguration vorhanden ist, einmalig anlegen:

```bash
mkdir -p ~/.config/together
cp .env.example ~/.config/together/.env.local
chmod 600 ~/.config/together/.env.local
```

Danach `SUPABASE_URL` und `SUPABASE_PUBLISHABLE_KEY` in dieser Datei setzen.

### Ein-Befehl-Workflows

Die Shell-Skripte wechseln selbst in den Projektordner und verwenden automatisch die zentrale lokale Konfiguration. Sie können daher auch aus einem anderen aktuellen Verzeichnis gestartet werden.

```bash
./setup.sh                         # lokales Setup + Qualitätsprüfungen
./setup.sh --full                  # Setup + komplette Release-Verifikation
./scripts/run_app.sh               # App starten
./scripts/build_release.sh         # Release-APK bauen
./scripts/verify_release.sh        # vollständige Release-Gates
```

Die lokale Konfiguration bleibt außerhalb des Projekts. Der Publishable Key darf in die Flutter-App, ein Service-Role-/Secret-Key dagegen niemals.

V1.4 erzeugt Android-/iOS-Plattformdateien absichtlich nicht automatisch. Dadurch werden fehlende oder versehentlich veränderte Plattformdateien nicht stillschweigend erzeugt oder überschrieben.

## Supabase

Die Migrationen unter `supabase/migrations/` sind die Quelle für den Datenbankstand. Die V1.4-Härtung ist bereits im Projekt `oidxezjdwqktpxuypbfb` angewendet.

Die frühere serverseitige `generate-recipes`-Rezeptgenerierung ist für den privaten Produktpfad deaktiviert. Schmackofatz verwendet für neue Rezepte den externen ChatGPT-Workflow und benötigt dafür keinen OpenAI-API-Schlüssel.

## Release

Vor einem Release:

```bash
flutter pub get
./scripts/check_repository.sh
./scripts/verify_release.sh
```

Falls `pubspec.lock` fehlt, erzeugt `flutter pub get` sie in der Flutter-Umgebung. Die Lockdatei gehört anschließend ins Repository.

## Auth-Sicherheit

Wenn zusätzlich Passwort-Authentifizierung angeboten wird, muss in Supabase Auth der Schutz gegen bekannte/leaked Passwörter aktiviert werden. Für die aktuell verwendete anonyme Authentifizierung ist dieser Mechanismus nicht der Identitätsnachweis.


## Version 1.5: Eigene Rezepte importieren

Version 1.5 ergänzt drei Wege unter **Rezept hinzufügen**: manuelles Erstellen, Import einer `together_recipe`-JSON-Datei und Öffnen von ChatGPT. Der ChatGPT-Weg verwendet keine OpenAI-API. Das Importformat ist in `docs/together_recipe_format_v1.md` dokumentiert.

## V1.5.2: ChatGPT-Rezeptworkflow ohne API

Unter „Rezept hinzufügen → Mit ChatGPT“ kann eine Hauptauswahl und anschließend eine Zutaten-Auswahl aus dem bestehenden „Wir kochen“-Zutatenflow getroffen werden. Schmackofatz erstellt daraus einen strukturierten Prompt, kopiert ihn in die Zwischenablage und öffnet die ChatGPT-App auf Android beziehungsweise den Browser als Fallback. ChatGPT wird angewiesen, ein `together_recipe`-JSON v1 zurückzugeben. Dieses JSON wird anschließend über „Rezeptdatei importieren“ in Schmackofatz übernommen. Dafür ist keine OpenAI-API und kein zusätzliches API-Budget erforderlich.


## V1.5.5 / Schmackofatz und stabiler JSON-Import

Der ChatGPT-Rezeptworkflow fordert eine echte `together_recipe.json`-Datei an. Diese kann über „Rezeptdatei importieren“ validiert, geprüft und dauerhaft in „Meine Rezepte“ gespeichert werden. Importierte Rezepte verwenden dieselbe interne Rezeptstruktur und Detailansicht wie regulär gespeicherte Rezepte.


## V1.6.0 – Fatzomat Launchername

Der Name unter dem Android-App-Icon lautet **Fatzomat**. Innerhalb der App und in der Produktkommunikation bleibt der Name **Schmackofatz**.

## V1.5.6 / V1.5.7 – private Zwei-Personen-Härtung

- Der JSON-Import nutzt die aktuelle `file_picker`-API und liest Dateien mit `readAsBytes()` und einem 1-MB-Limit.
- Qualitative Mengen (`amount: null`) werden unterstützt und intern auf `1` normalisiert, damit Angaben wie „Prise“ mit dem bestehenden Datenmodell kompatibel bleiben.
- Der Rezeptimport darf die App bei ungültigen oder nicht lesbaren Dateien nicht beenden.
- „Wir kochen“ verwendet jetzt denselben ChatGPT-Importworkflow wie „Rezept hinzufügen“ und benötigt keine OpenAI-API.
- Eine Koch-Entscheidungsanfrage wird erst mit dem konkret gespeicherten Rezept aufgelöst.
- Startup unterscheidet Netzwerk-/Backendfehler vom fehlenden Onboarding.
- Der künstliche Startbildschirm wurde auf 900 ms verkürzt.
- Unter Profil → Daten sichern kann eine persönliche JSON-Sicherung von Profil, Präferenzen und gespeicherten Rezepten erzeugt werden.
- Private Release-Builds können ohne Produktions-Keystore gebaut werden; ein eigener Keystore bleibt optional möglich.
- Die nicht mehr benötigten AI-Quota-RPCs sind für Client-Rollen gesperrt.

Das Projekt ist weiterhin nicht für eine öffentliche Store-Veröffentlichung optimiert. Die technische Application-ID `com.example.food_app_mvp` bleibt für die private Nutzung bewusst unverändert.

## V1.6.3 – Einkauf & Portionsskalierung

V1.6.3 führt den Einkaufsschritt des Single-Device-Kernworkflows weiter aus. Die Einkaufsliste zeigt die aktuelle Personenzahl, Rezeptmengen werden bei einer Änderung der Personenzahl automatisch neu aufgebaut und manuelle Artikel bleiben erhalten. Zusätzlich wurde die Lebensdauer des Today-Controllers sauber an den Screen gebunden.

## V1.6.2 – Single-Device-Kernworkflow

V1.6.2 stabilisiert den lokalen Kernablauf rund um `Wir kochen`, Rezepte, `Heute` und Einkauf. `Heute` bietet bei leerem Plan direkte Einstiege in gespeicherte Rezepte und die externe ChatGPT-Rezepterstellung. Der Wechsel auf „Einkaufen“ öffnet die passende Einkaufsliste direkt.

Der Zwei-Personen-Laufzeit-Test bleibt bewusst ausgesetzt, bis ein zweites Testgerät bzw. eine zweite Person verfügbar ist.

## V1.6.1 – Backend-/Client-Reconciliation

V1.6.1 synchronisiert den aktuellen Flutter-Stand mit dem verbundenen Supabase-Projekt. Der Fokus liegt auf Decision Requests, Notifications, Today-Plan-Servings, Shopping-Quellen, Realtime und robusterem Fehlerverhalten. Historische Migrationen bleiben unverändert; die Synchronisierung erfolgt ausschließlich über eine neue Reconciliation-Migration.

## V1.6.7 – Diagnose und Release-Stabilität

Die Diagnose-Seite kann jetzt die aktuelle Supabase-Sitzung anzeigen und die Verbindung zum Backend aktiv prüfen. Dabei werden keine Sitzungstokens oder geheimen Schlüssel dargestellt. Die Prüfung verwendet ausschließlich die bereits konfigurierte App-Authentifizierung und Supabase-RLS.

## V1.6.8 – Stabilisierung

V1.6.8 konsolidiert die zentrale Fehlerbehandlung: Fehlerzustände bieten einen nachvollziehbaren Retry-Pfad, schützen UI-Fehlermeldungen gegen bereits entfernte BuildContexts und enthalten keine veralteten Nutzerhinweise auf eine nicht mehr verwendete OpenAI-/KI-Rezept-API.

## V1.7.0 – Zwei-Personen-Workflow

V1.7.0 stabilisiert den eigentlichen Zwei-Personen-Ablauf: Eingehende Entscheidungsanfragen reagieren per Supabase Realtime auf Statusänderungen, und Benachrichtigungs-Updates werden auf den angemeldeten Benutzer begrenzt. Die bestehende Decision-Request-Logik für Kochen, Bestellen, Essen gehen und Überrasch mich bleibt erhalten.

## V1.7.1 – Zwei-Personen-Realtime stabilisiert

V1.7.1 härtet den Zwei-Personen-Entscheidungsworkflow gegen Hintergrundwechsel und überlappende Aktualisierungen. Der Entscheidungsbildschirm synchronisiert sich beim Zurückkehren in den Vordergrund erneut und verwirft veraltete Antworten, wenn bereits eine neuere Aktualisierung gestartet wurde.


## V1.8.0 – Heute als Produktzentrum

V1.8.0 macht „Heute“ zum zentralen Einstieg der privaten Zwei-Personen-App. Von dort aus können gespeicherte Rezepte geöffnet, neue Rezepte über den externen ChatGPT-Workflow erstellt oder die vier gemeinsamen Modi direkt gestartet werden. Ein bestehender Tagesplan bietet außerdem einen direkten Weg zurück in die heutige Entscheidung.


## V1.9.0 – Rezeptworkflow

V1.9.0 ergänzt den stabilen Rezeptdatei-Export aus der Rezeptdetailansicht. Exportiert wird das definierte `together_recipe`-Format Version 1; die aktuell gewählte Portionszahl wird dabei berücksichtigt. Der bestehende externe ChatGPT-Workflow bleibt unverändert.

## V1.11.0 – UX-Politur

V1.11.0 verbessert kleine, aber wiederkehrende Bedienungsdetails: Benachrichtigungen zeigen beim Markieren als gelesen einen eindeutigen Busy-Zustand, erfolgreiche Verbindungsprüfungen setzen alte Fehlerzustände zurück und Portionssteuerungen verwenden präzisere Bedienhinweise.

## V1.10.0 – Bestellen und Essen gehen

V1.10.0 schärft die externe Discovery für Bestellungen und Restaurantbesuche. Lieferdienst-Suchen sind nicht mehr an einen einzelnen Anbieter gebunden. Suchradius und Preisniveau werden als Suchhinweise an externe Suchdienste übergeben. Bestellung, Bezahlung, Lieferung, Reservierung und Besuch bleiben vollständig außerhalb von Schmackofatz.
