# Schmackofatz v1.13.0 – Decision Share Accept Fix 19

## Fehler
Beim Tippen auf „Übernehmen“ einer per Push geöffneten geteilten Rezeptentscheidung schlug der direkte Client-Insert in `recipe_saves` mit einer Supabase-RLS-Fehlermeldung (`42501`, USING expression) fehl.

## Ursache
Das geteilte Rezept gehört dem Sender. Der Empfänger darf deshalb nicht direkt die fremde `recipe_id` in `recipe_saves` eintragen. Die bestehende RLS-Policy blockiert diesen Insert korrekt.

## Lösung
- Neuer `SECURITY DEFINER`-RPC `accept_decision_share(uuid)` auf Supabase.
- Der RPC prüft Empfänger, Verbindung, Nachrichtentyp und Gültigkeit für heute.
- Bei Rezepten wird eine unabhängige persönliche Rezeptkopie inklusive Zutaten erzeugt und für den Empfänger gespeichert.
- Danach wird diese persönliche Kopie atomar in den persönlichen Tagesplan übernommen.
- Nicht-Rezept-Entscheidungen werden über die bestehende persönliche Entscheidungslogik übernommen.
- Wiederholtes Tippen verwendet die bereits erzeugte persönliche Rezeptkopie erneut.
- Die Flutter-Seite verwendet nicht mehr den direkten `recipe_saves`-Insert.

## Backend
Die Migration wurde auf dem produktiven Supabase-Projekt angewendet und der neue RPC ist für `authenticated` ausführbar.
