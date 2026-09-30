# Schmackofatz v1.12.0 – Rezept-Sharing

## Umfang

Die bestehende `recipe_suggestions`-Architektur wurde zu einem vollständigen persönlichen Rezept-Sharing-Workflow erweitert.

### Sender
- In einer bestehenden Connection erscheint auf der Rezeptdetailseite die Aktion **„Rezept senden“**.
- Die bestehende `create_recipe_suggestion`-RPC prüft weiterhin Session, Connection, Empfänger und Rezeptzugriff.
- Doppelte offene Vorschläge für dasselbe Rezept/Verbindungspaar werden verhindert.

### Empfänger
- Beim erstmaligen Senden wird über die bestehende `app_notifications`-Infrastruktur eine Notification vom Typ `recipe_suggestion` erzeugt.
- Die Notification enthält Rezeptbezug und Vorschlags-ID.
- Beim Öffnen der Notification wird `Meine Rezepte` geöffnet.
- Offene eingehende Rezepte stehen dort oben im Bereich **„Neue Rezepte“** und werden per Realtime aktualisiert.
- Das Rezept kann vor der Entscheidung geöffnet/angesehen werden.

### Annehmen / Verwerfen
- **Annehmen:** serverseitig autorisiert, atomar auf `accepted` gesetzt und als persönliches Rezept des Empfängers in `recipe_saves` übernommen. `on conflict do nothing` verhindert Duplikate.
- **Verwerfen:** serverseitig autorisiert, auf `declined` gesetzt und nicht in `recipe_saves` übernommen.
- In beiden Fällen wird die zugehörige Rezept-Notification als gelesen markiert.
- Der persönliche TodayPlan wird durch das Annehmen/Verwerfen nicht verändert.

## Sicherheit

- Bestehende Connection- und RLS-Strukturen werden weiterverwendet.
- Der Empfänger kann eine Anfrage nur selbst und nur im Status `pending` beantworten.
- Die RPCs verwenden explizite `auth.uid()`- und Connection-Prüfungen.
- Keine Service-Role-Umgehung im Flutter-Client.
- Keine pauschale Öffnung von Rezept- oder Sammlungstabellen.
- Die neuen RPCs sind `SECURITY DEFINER`, weil die Annahme serverseitig atomar in die persönliche `recipe_saves`-Sammlung schreiben und die Notification erledigen muss. Die Autorisierung erfolgt innerhalb der Funktionen explizit. Der Supabase Security Advisor meldet SECURITY-DEFINER-Funktionen im Projekt bereits an mehreren bestehenden Stellen; die beiden Rezept-Sharing-RPCs sind Teil dieses bestehenden serverseitigen RPC-Musters.

## Betroffene Dateien

- `lib/data/models/app_notification.dart`
- `lib/data/repositories/collaboration_repository.dart`
- `lib/features/recipes/recipe_detail_page.dart`
- `lib/features/recipes/saved_recipes_page.dart`
- `lib/features/settings/notifications_page.dart`
- `supabase/migrations/20260921160000_recipe_sharing_v2_notifications_and_acceptance.sql`
- `test/app_notification_test.dart`
- `test/regression/recipe_suggestions_test.dart`
- `test/regression/recipe_sharing_inbox_test.dart`

## Backend

Die Migration `recipe_sharing_v2_notifications_and_acceptance` wurde auf dem verbundenen Supabase-Projekt angewendet und anschließend durch SQL-Prüfungen verifiziert.

## Prüfung

- Supabase-Migration erfolgreich angewendet.
- `create_recipe_suggestion` und `respond_to_recipe_suggestion` sind für `authenticated` ausführbar.
- Beide RPCs wurden serverseitig als `SECURITY DEFINER` geprüft.
- Die bestehenden RLS-Policies für `recipe_suggestions` bleiben bestehen.
- Statische Klammer-/Syntaxstruktur der geänderten Dart-Dateien wurde geprüft.
- Flutter/Dart ist in der Arbeitsumgebung nicht installiert; `flutter analyze` und `flutter test` konnten daher hier nicht ausgeführt werden.
