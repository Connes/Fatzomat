# Schmackofatz – Entscheidungs- und Flow-Audit / Implementierungsrunde

## Ausgangspunkt

Der Implementierungsauftrag wurde gegen den bereitgestellten Entscheidungs-Audit ausgeführt. Maßstab war der vollständige Stack UI → Flutter → Repository → RPC/API → Supabase DB → RLS → UI.

## Implementierte Korrekturen

### Personal Today
- `personal_today_plans` unterstützt jetzt die persönlichen Entscheidungstypen `recipe`, `order`, `dine_out` und `surprise`.
- Nicht-Rezept-Entscheidungen werden nicht mehr als Fake-Rezepte gespeichert.
- `TodayPlan` kann Rezept- und Nicht-Rezept-Zustände darstellen.
- Neue invoker-RPC `set_personal_today_decision(text,text)` persistiert persönliche Bestell-, Restaurant- und Überraschungsentscheidungen.
- Persönliche Cancel-Logik funktioniert auch für Entscheidungen ohne `recipe_id`.
- Persönliche Today-RLS bleibt owner-only und prüft bei Rezepten weiterhin Eigentum oder persönlichen Save.

### UI / Today
- „Wir bestellen“ und „Wir gehen essen“ speichern die persönliche Entscheidung vor dem Discovery-Flow.
- „Überrasch mich“ speichert die persönliche Überraschungsentscheidung.
- „Entscheide Du“ fällt ohne Connection auf den persönlichen Überraschungsflow zurück.
- Bestehende Rezeptanzeige öffnet weiterhin `RecipeDetailPage`.
- Nicht-Rezept-Entscheidungen werden auf Heute als Textentscheidung dargestellt.
- „Entscheidung entfernen“ ist jetzt über die Today-Seite erreichbar.

### Collaboration / Personal-Trennung
- Recipe-Entscheidungen innerhalb einer Decision Request schreiben nicht mehr zusätzlich in den persönlichen TodayPlan.
- Gleiches gilt für neue/importierte Rezepte innerhalb einer Collaboration-Entscheidung.
- Die gemeinsame Entscheidung wird ausschließlich über die Collaboration-Seite aufgelöst.
- Damit kann z. B. B persönlich Curry geplant haben und anschließend gemeinsam Pizza entscheiden, ohne dass Curry überschrieben wird.

### Offline
- Der Today-Cache enthält jetzt auch `decision_type` und `decision_value`.
- Es wurde keine nicht vorhandene Offline-Write-Queue vorgetäuscht. Neue Entscheidungen benötigen weiterhin Backend-Zugriff.

### Tests / Checks
- Neuer Regressionstest für Personal-Today-Entscheidungstypen und Personal/Collaboration-Grenze.
- `scripts/check_architecture.sh`: erfolgreich.
- `scripts/check_repository.sh`: erfolgreich.
- Flutter/Dart ist in der aktuellen Ausführungsumgebung nicht installiert; `flutter analyze` und `flutter test` konnten daher nicht erneut ausgeführt werden.

## Live-Supabase-Verifikation

Verifiziert wurden:
- `personal_today_plans.recipe_id` ist nullable.
- `decision_type` und `decision_value` existieren.
- die Decision-Constraints sind vorhanden.
- `set_personal_today_decision(text,text)` existiert und ist `SECURITY INVOKER`.
- die persönliche Today-RLS wurde auf Rezept- und Nicht-Rezept-Entscheidungen angepasst.
- der Security Advisor wurde nach der Änderung erneut ausgeführt.

Der Security Advisor meldet weiterhin bestehende `SECURITY DEFINER`-Warnungen bei verschiedenen Collaboration-/Legacy-RPCs. Diese wurden nicht pauschal auf `SECURITY INVOKER` umgestellt, weil das eine separate Sicherheitsmigration mit eigener Funktionsprüfung wäre und nicht blind als Nebenwirkung dieser Flow-Reparatur erfolgen sollte.

## Verbleibende Punkte

1. Vollständige Flutter-Analyse und Tests müssen in einer Umgebung mit Flutter/Dart ausgeführt werden.
2. Ein echter Zwei-Benutzer-E2E-Test gegen zwei authentifizierte Sessions sollte den Fall „A Pasta / B Curry / gemeinsam Pizza“ ausführen.
3. Die bestehenden Security-Advisor-Warnungen für privilegierte Collaboration-/Legacy-RPCs sollten in einer separaten Hardening-Runde geprüft werden.
4. Eine echte Offline-Write-Queue ist weiterhin nicht implementiert.

## Zielzustand der zentralen Trennung

```text
PERSONAL
  Today decision → personal_today_plans
  Personal recipe → recipes / recipe_saves
  Personal shopping → shopping_items.personal_today_plan_id
  Personal history → personal_decision_history

COLLABORATION
  Decision request → decision_requests
  Shared meal → shared_recipe_plans
  Shared shopping → shopping_items.shared_recipe_plan_id
  Notifications → app_notifications
```

Eine gemeinsame Mahlzeit überschreibt damit nicht den persönlichen TodayPlan.
