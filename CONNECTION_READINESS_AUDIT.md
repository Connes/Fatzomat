# Connection Readiness Audit

## Ergebnis

**NO-GO für einen ungeplanten manuellen Zwei-Teilnehmer-Lauf.**

Der Audit hat mehrere echte Blocker gefunden und direkt behoben. Die wichtigsten Live-Flows wurden anschließend per transaktionalen Supabase-Tests mit zwei bestehenden Auth-User-Kontexten verifiziert. Flutter `analyze`/`test` konnte in dieser Umgebung nicht ausgeführt werden, da Flutter/Dart hier nicht installiert ist.

Nach dem lokalen Flutter-Lauf kann der manuelle Zwei-Teilnehmer-Test starten, sofern `flutter analyze` und `flutter test` ohne Fehler durchlaufen.

## Gefundene und behobene Blocker

### 1. Connection-Code-Erstellung war live defekt

`create_connection()` verwendete `gen_random_bytes(6)`, die im aktuellen Live-Projekt nicht verfügbar ist. Der erste direkte Live-Test schlug deshalb bereits beim Erstellen einer Connection fehl.

Behoben durch Generierung aus `gen_random_uuid()`.

### 2. Entscheidungsanfragen wurden fälschlich zu Shared Plans

`resolve_decision_request()` rief für Rezeptentscheidungen `share_recipe_for_today()` auf. Damit wurde eine Entscheidung von B für A in `shared_recipe_plans` geschrieben statt in A's persönlichem `personal_today_plans`.

Behoben: Die Entscheidung wird jetzt als persönlicher TodayPlan des Request-Erstellers gespeichert. Shared Meals bleiben eine separate explizite Collaboration-Aktion.

### 3. Bestellung/Restaurantentscheidung wurde zu früh auf Präferenzebene abgeschlossen

Bei einer Connection wurde die Entscheidungsanfrage bereits nach Auswahl von z. B. `Pizza` mit `result_type = preference` abgeschlossen. Die konkrete Restaurantauswahl konnte die Anfrage danach nicht mehr auflösen.

Behoben: Discovery erhält die `decisionRequestId`. Erst die Auswahl eines konkreten Restaurants/Lieferanbieters löst die Anfrage auf und speichert den konkreten Namen als persönliche Entscheidung.

### 4. Persönliche Bestellung/Restaurantauswahl wurde zu früh gespeichert

Ohne Connection wurde bisher bereits die Präferenz als TodayPlan gespeichert, bevor ein konkreter Anbieter ausgewählt wurde.

Behoben: Der persönliche TodayPlan wird erst nach Auswahl des konkreten Restaurants/Lieferanbieters geschrieben.

### 5. Recipe Suggestions hatten rekursive RLS-Policy

Die INSERT-Policy auf `recipe_suggestions` fragte innerhalb ihrer eigenen RLS-Auswertung erneut `recipe_suggestions` ab. PostgreSQL meldete beim realen Insert `infinite recursion detected in policy for relation recipe_suggestions`.

Behoben: Direkter INSERT wird geschlossen; die Erstellung läuft über einen explizit authentifizierten RPC. Der RPC validiert User, Connection, Empfänger und Rezeptzugriff selbst.

## Live-Verifikation

Verifiziert:

- `create_connection()` und `join_connection()` mit zwei Auth-User-Kontexten in einer Rollback-Transaktion
- zwei Connection-Mitglieder werden korrekt erzeugt
- Decision Request A → B
- B löst Rezeptentscheidung auf
- A erhält persönlichen TodayPlan
- B kann A's persönlichen TodayPlan nicht lesen
- keine `shared_recipe_plans` werden durch die Decision Request Resolution erzeugt
- Disconnect entfernt nur A aus der Connection
- A's persönlicher TodayPlan bleibt nach Disconnect erhalten
- Decision Request A → B für `order` speichert eine konkrete persönliche `order`-Entscheidung bei A
- Recipe Suggestion A → B kann erstellt und von B akzeptiert werden
- B kann ein explizit vorgeschlagenes Rezept lesen
- B kann A's Rezept nicht ändern
- direkte Abfragen auf profiles, preferences, recipe_saves, personal_today_plans und personal_decision_history zeigen für B keine Daten von A

Alle diese DB-Tests wurden innerhalb von Transaktionen ausgeführt und anschließend zurückgerollt.

## Realtime

Live aktiviert für:

- connection_members
- decision_requests
- recipe_suggestions
- shared_recipe_plans
- app_notifications

Die Flutter-Seiten abonnieren die relevanten Collaboration-Tabellen mit Realtime-Subscriptions.

## RLS / Personal First

Die Live-RLS-Policies trennen persönliche Daten grundsätzlich über `auth.uid()`.

Personal Today, History, Preferences, Profiles und persönliche Saves sind userbezogen.
Collaboration-Daten sind connectionbezogen.

## Bekannte Restpunkte

1. Flutter `analyze` und `test` müssen auf einer Flutter-Umgebung ausgeführt werden.
2. Supabase Security Advisor meldet weiterhin mehrere bestehende SECURITY-DEFINER-Warnungen. Die Collaboration-RPCs sind absichtlich geschützte RPCs mit expliziter `auth.uid()`-Autorisierung; sie wurden nicht pauschal auf Invoker umgestellt.
3. Der Advisor meldet außerdem eine Reihe von Anonymous-Policy-Warnungen, obwohl die geprüften Policies explizit `authenticated` verwenden. Das ist im aktuellen Projektstand kein nachgewiesener anonymer Datenzugriff.
4. Leaked-Password-Protection ist im Supabase Auth aktuell deaktiviert und sollte vor einem echten Produktivbetrieb separat aktiviert werden.
5. Ein vollständiger UI-Test auf zwei physischen Geräten mit echten Logins konnte hier nicht durchgeführt werden.

## Manueller Zwei-Teilnehmer-Test

### Phase 1

A und B mit zwei echten Accounts anmelden.

### Phase 2

A erstellt eine Connection und gibt den Code an B.

Erwartung: B tritt bei; beide sehen `Ihr seid verbunden`.

### Phase 3

A erstellt persönliches Rezept A1 und setzt es für heute.
B erstellt persönliches Rezept B1 und setzt es für heute.

Erwartung: Beide persönlichen TodayPlans bleiben getrennt.

### Phase 4

A sendet A1 als Rezeptvorschlag an B.

Erwartung: B erhält den Vorschlag ohne Eigentumswechsel.

### Phase 5

B nimmt A1 an.

Erwartung: B kann A1 lesen, bleibt aber Nicht-Owner.

### Phase 6

A nutzt `Entscheide Du`.

Erwartung: B erhält die Anfrage.

### Phase 7

B wählt `Wir bestellen` und anschließend einen konkreten Lieferanbieter.

Erwartung: A's persönlicher TodayPlan enthält den konkreten Anbieter. B's persönlicher TodayPlan bleibt unverändert.

### Phase 8

Wiederholen mit `Wir gehen essen` und einem konkreten Restaurant.

### Phase 9

Wiederholen mit `Wir kochen` und einem Rezept.

### Phase 10

A und B setzen jeweils eigene TodayPlans. Danach explizit ein Shared Meal erzeugen.

Erwartung: Personal Today A, Personal Today B und Shared Meal existieren gleichzeitig ohne Überschreiben.

### Phase 11

Connection trennen.

Erwartung: Persönliche Rezepte, TodayPlans, History, Shopping und Preferences bleiben erhalten.

## Lokaler Abschluss

Auf einer Flutter-Umgebung ausführen:

```bash
flutter pub get
flutter analyze
flutter test
```

Erst nach einem erfolgreichen lokalen Lauf ist der vollständige End-to-End-Test mit zwei echten Teilnehmern verifiziert.
