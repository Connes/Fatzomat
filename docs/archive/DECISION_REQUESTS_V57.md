# V57 – Du entscheidest heute / Teil 1

## Ziel

V57 Teil 1 legt die technische Grundlage für eine strukturierte Entscheidungsanfrage zwischen zwei bereits verbundenen Personen.

Die Funktion ist bewusst **kein Chat** und kein allgemeines Nachrichtensystem.

## Datenmodell

`decision_requests` enthält:

- Verbindung
- Absender
- Empfänger
- Status
- optionalen Entscheidungsmodus
- optionales Ergebnis
- Zeitstempel

Statuswerte:

- `pending`
- `accepted`
- `resolved`
- `cancelled`
- `expired`

Pro Verbindung ist maximal eine offene (`pending`) Anfrage erlaubt.

## Sicherheit

RLS beschränkt Zugriffe auf Mitglieder der jeweiligen Verbindung. Ein Erstellen über `create_decision_request()` prüft zusätzlich:

- authentifizierten Benutzer
- vorhandene Verbindung
- Empfänger gehört zur selben Verbindung
- Empfänger ist nicht der Absender
- keine bereits offene Anfrage

## Realtime

`decision_requests` wurde der Supabase-Realtime-Publication hinzugefügt. UI und Benachrichtigungslogik werden in V57 Teil 2 darauf aufbauen.

## Flutter

Neu:

- `DecisionRequest` Model
- Repository-Methoden für Partner-ID, Erstellen und Abruf offener Anfragen

Noch nicht Bestandteil von Teil 1:

- Startseiten-Button
- Empfänger-Screen
- Entscheidung durchführen
- automatische Übernahme in „Heute“
- Push Notifications
