# Schmackofatz – Bewertung & Umsetzung: Entscheidung, Rezept-Detail, Rezeptvorschläge

## Ergebnis

### 1. „Entscheidung ändern“ vs. „Entscheidung entfernen"

**Bewertung: sinnvoll, „Entscheidung ändern“ zu entfernen.**

Die fachlich saubere Personal-First-Logik ist:

1. aktuelle persönliche Entscheidung entfernen
2. anschließend über die normale Today-Auswahl eine neue Entscheidung treffen

Damit bleibt keine zweite, parallele Änderungslogik neben dem normalen Entscheidungsfluss bestehen. Die bestehende persönliche Entfernung bleibt für alle Entscheidungstypen erhalten.

Die sichtbare Aktion **„Entscheidung ändern“ wurde aus der Today-Ergebnisansicht entfernt**. Die Aktion **„Entscheidung entfernen“ bleibt bestehen**.

Die persönliche Historie und die persönliche Einkaufsliste werden weiterhin durch die bestehende `cancel_personal_today_plan`-Logik behandelt.

### 2. Bereits heute ausgewähltes Rezept

**Bewertung: sinnvoll.**

Wenn Recipe Detail genau das Rezept zeigt, das aktuell im persönlichen TodayPlan als `decisionType = recipe` ausgewählt ist, wird nicht erneut „Für heute festlegen“ angeboten.

Stattdessen zeigt die Seite:

**„Für heute ausgewählt“**

Bei einem anderen Rezept bleibt **„Für heute festlegen“** verfügbar.

Das ist eine Zustandsanzeige, keine Sperrlogik. Die persönliche Auswahl bleibt unabhängig von einer Connection möglich.

### 3. Rezeptvorschläge im Connection-Modus

**Bewertung: sinnvoll und architektonisch passend.**

Rezeptvorschläge sind Collaboration-Daten und werden deshalb nicht in `personal_today_plans`, `recipe_saves` oder `shared_recipe_plans` hineingezwungen.

Es gibt dafür jetzt `recipe_suggestions` mit den Zuständen:

- `pending`
- `accepted`
- `declined`
- `cancelled`

Ein Vorschlag verändert niemals automatisch den persönlichen TodayPlan des Empfängers.

Der Rezeptbesitz bleibt beim ursprünglichen Besitzer. Der Empfänger erhält nur expliziten Zugriff auf das konkret vorgeschlagene Rezept und dessen Zutaten.

## Implementiert

### Flutter

- Today-Ergebnisansicht: „Entscheidung ändern“ entfernt.
- Today-Ergebnisansicht: „Entscheidung entfernen“ bleibt einzige Änderungsaktion.
- Recipe Detail erkennt den persönlichen Today-Zustand.
- Bereits ausgewähltes Rezept zeigt „Für heute ausgewählt“.
- Andere Rezepte zeigen weiterhin „Für heute festlegen“.
- Im Connection-Modus erscheint „Rezept vorschlagen“, wenn das Rezept für den Nutzer explizit zugänglich ist.
- Neue Seite `RecipeSuggestionsPage` für empfangene und gesendete Vorschläge.
- Empfänger kann Vorschlag öffnen, annehmen oder ablehnen.
- Realtime-Aktualisierung für Rezeptvorschläge.
- Connection-Seite enthält den Einstieg „Rezeptvorschläge“.
- Persönlicher TodayPlan wird durch Annehmen eines Vorschlags nicht automatisch verändert.
- Bestehende Funktion „Als gemeinsame Mahlzeit festlegen“ bleibt als separate Collaboration-Funktion erhalten.

### Datenmodell / Supabase

Neu:

- `public.recipe_suggestions`
- Indexe für Empfänger, Sender und Rezept
- partieller Unique-Index für doppelte offene Vorschläge derselben Rezept-/Verbindungsbeziehung
- RLS für Teilnehmer der Connection
- Insert nur durch den Vorschlagenden und nur für ein Rezept, auf das dieser expliziten Zugriff hat
- Empfänger darf einen offenen Vorschlag annehmen oder ablehnen
- Sender darf einen offenen Vorschlag zurücknehmen
- Immutable-Guard verhindert das Umschreiben von Connection, Rezept oder Teilnehmern während eines Updates

Rezeptzugriff:

- Ein empfangenes Rezept wird nicht allgemein für Connection-Mitglieder sichtbar.
- Der Empfänger erhält nur bei einem offenen oder angenommenen expliziten Vorschlag Zugriff.
- Die gleichen Regeln gelten für `recipe_ingredients`.

RPCs:

- `create_recipe_suggestion(uuid)` – SECURITY INVOKER
- `respond_to_recipe_suggestion(uuid, boolean)` – SECURITY INVOKER
- `guard_recipe_suggestion_update()` – SECURITY INVOKER Trigger-Funktion

Es wurden für diese neue Funktion keine SECURITY-DEFINER-RPCs eingeführt.

## Tests / Prüfungen

Ausgeführt:

- Architektur-Audit: **PASS**
- Repository-Hygiene: **PASS**
- Live-Supabase-Tabelle `recipe_suggestions`: **VERIFIZIERT**
- Live-RLS-Policies für `recipe_suggestions`: **VERIFIZIERT**
- Neue RPCs: **SECURITY INVOKER VERIFIZIERT**
- Realtime-Tabelle: aktiviert
- Security Advisor: ausgeführt

Nicht ausführbar in der aktuellen Umgebung:

- `flutter analyze`: **NICHT AUSGEFÜHRT**, Flutter nicht installiert
- `flutter test`: **NICHT AUSGEFÜHRT**, Flutter/Dart nicht installiert

Der Security Advisor meldet weiterhin bereits bestehende SECURITY-DEFINER-Warnungen in älteren Connection-/Collaboration-RPCs sowie die bestehende Anonymous-Access-Warnung. Diese wurden nicht blind in dieser Änderung umgebaut, weil das eine separate Funktion-für-Funktion-Sicherheitsmigration wäre.

## Kritischer Selbst-Audit

- Kein „Entscheidung ändern“-Button mehr auf Today.
- Persönliche Entscheidungen können weiterhin entfernt und danach normal neu getroffen werden.
- Ein bereits heute gewähltes Rezept zeigt keinen redundanten „Für heute festlegen“-Button.
- Ein anderes Rezept kann weiterhin persönlich für heute festgelegt werden.
- Rezeptvorschläge sind von persönlichen Today-Daten getrennt.
- Ein angenommener Vorschlag überschreibt keinen persönlichen TodayPlan.
- Rezeptbesitz wird nicht übertragen.
- Connection-Zugriff auf Rezepte ist explizit statt pauschal.
- Disconnect erhält persönliche Daten.
- Keine neuen SECURITY-DEFINER-Funktionen für die Vorschlagslogik.

## Offener Punkt

Ein echter Zwei-Benutzer-End-to-End-Test mit zwei authentifizierten Sessions konnte in dieser Umgebung nicht ausgeführt werden. Die Datenbankstruktur, RLS-Policies und RPC-Sicherheitsart wurden live geprüft.
