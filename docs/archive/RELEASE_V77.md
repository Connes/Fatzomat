# V77 – Entscheidungsanfrage vollständig durch den Auswahlflow führen

## Ziel

Eine Anfrage über „Du entscheidest heute“ soll nach dem Öffnen durch den normalen Essensauswahl-Flow laufen, ohne einen separaten zweiten Auswahlbildschirm. Die ausgewählte Entscheidung wird mit derselben Anfrage verknüpft und serverseitig abgeschlossen.

## Neu

- Aktive Entscheidungsanfragen des Empfängers können über `activeDecisionRequestForMe()` inklusive `pending` und `accepted` geladen werden.
- `DecisionRequestPage` übergibt die Request-ID jetzt an `FoodModePage`.
- „Wir kochen“, „Wir bestellen“ und „Wir gehen essen“ behalten die Request-ID über den gesamten Flow.
- Bei Bestellen und Essen gehen wird die Anfrage beim ausgewählten Ergebnis aufgelöst.
- Beim Kochen wird die Request-ID bis zur konkreten Rezeptauswahl weitergereicht und dort aufgelöst.
- „Überrasch mich“ behält ebenfalls die Request-ID. Nicht-Koch-Ergebnisse werden auf der Überraschungsseite aufgelöst; Koch-Ergebnisse werden bis zur Rezeptauswahl weitergeführt.
- Der veraltete separate `DecisionPreferencePage`-Flow wurde entfernt.

## Sicherheits- und UX-Grenze

- Eine Entscheidungsanfrage wird weiterhin zuerst angenommen und danach genau im bestehenden serverseitigen Resolve-RPC abgeschlossen.
- Es gibt keine Bestellung, Zahlung oder Reservierung in diesem Flow.
- Der normale Startseiten-Flow bleibt unverändert.

## Prüfungen

- Bestehende V76-Asset- und Accessibility-Tests bleiben erhalten.
- Die V76-Fix5-Semantics-Behebung bleibt enthalten.
- Vor lokalem Release: `flutter analyze`, `flutter test`, `flutter build apk --debug`.
