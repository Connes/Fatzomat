# Schmackofatz v1.12.0 – Profil, Lebensmittel und Rezept-Auswahl

## Änderungen

### Profil
- Die letzte Box „Über Schmackofatz“ mit dem Hinweis „Schmackofatz hilft euch dabei …“ wurde vollständig entfernt.
- Die übrigen Profilaktionen und ihre Navigation bleiben unverändert.

### Meine Lebensmittel
- Die gefilterte Lebensmittel-Liste liegt jetzt in einer gemeinsamen `AppSurface`-Box.
- Die Box hat eine responsive, begrenzte Höhe: wenige Einträge bleiben kompakt, viele Einträge werden innerhalb der Box vertikal gescrollt.
- Eine sichtbare Scrollbar erleichtert die Bedienung bei langen Listen.
- Die bestehenden Like-/Dislike-Aktionen bleiben direkt an jedem Lebensmittel erhalten.
- Es gibt keine zusätzliche verschachtelte vertikale Seite-ScrollView.

### Meine Rezepte → Für heute auswählen
Die Fehleranalyse im vorhandenen Backend-Vertrag hat eine zyklische RLS-Abhängigkeit sichtbar gemacht:

`personal_today_plans` INSERT/UPDATE prüft den Rezeptzugriff über `recipes`, während die zusätzliche `recipes resolved decision read`-Policy wiederum direkt `personal_today_plans` abfragt. Beim persönlichen Today-Schreibvorgang kann dadurch die RLS-Auswertung wieder in die Ausgangstabelle zurücklaufen.

Die Korrektur besteht aus zwei Teilen:

1. `20260921145714_fix_personal_today_recipe_selection.sql` hält die bestehende explizite Autorisierung des RPC fest: nur `auth.uid()` darf handeln und das Rezept muss dem Benutzer gehören oder von ihm gespeichert sein.
2. `20260921145849_fix_personal_today_rls_recursion.sql` kapselt ausschließlich die notwendige „bereits persönliches Rezept“-Prüfung in einer nicht öffentlich exponierten `private`-Schema-Funktion und verwendet diese in den beiden betroffenen Read-Policies.
3. Danach bleibt `set_personal_today_plan` wieder `SECURITY INVOKER`. Damit bleibt RLS weiterhin die Autorisierungsgrenze für den persönlichen Today-Pfad.

Es wurden keine Tabellen-RLS-Regeln pauschal geöffnet und keine Supabase-Sicherheitskontrollen deaktiviert.

### Tests
Neu: `test/regression/profile_food_preferences_test.dart`

Abgedeckt werden:
- Entfernen der Profil-Hilfebox
- begrenzte und scrollbar dargestellte Lebensmittel-Box
- explizite Rezeptautorisierung im Today-RPC
- Entfernung der rekursiven RLS-Abhängigkeit
- Beibehaltung des `SECURITY INVOKER`-Modells für den finalen persönlichen Today-RPC
- unveränderter Flutter-Aufruf über `PersonalTodayRepository`

## Prüfung

Die Supabase-Migrationen wurden im verbundenen Schmackofatz-Supabase-Projekt angewendet und die finale Funktion anschließend als `SECURITY INVOKER` mit Ausführungsrecht für `authenticated` verifiziert.

Das Flutter SDK ist in der aktuellen Arbeitsumgebung nicht installiert. Daher konnten `./setup.sh`, `flutter analyze` und `flutter test` hier nicht lokal ausgeführt werden. Die lokale Flutter-Prüfung bleibt für das Projektverzeichnis erforderlich.
