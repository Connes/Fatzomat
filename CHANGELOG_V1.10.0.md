# Schmackofatz V1.10.0

## Bestellen und Essen gehen

- Die externe Discovery für „Wir bestellen“ und „Wir gehen essen“ wird als klar abgegrenzter Übergabepunkt dargestellt.
- Lieferdienst-Suchen verwenden eine externe Suchanfrage statt eines fest verdrahteten einzelnen Anbieters.
- Suchradius und Preisniveau werden verständlich in die externe Suchanfrage übernommen.
- Die bestehenden Karten- und Websuche-Einstiege bleiben erhalten.
- Die Nutzeroberfläche macht explizit, dass aktuelle Verfügbarkeit, Preise, Bestellung, Bezahlung, Lieferung, Reservierung und Besuch beim externen Anbieter bleiben.
- Die bestehende Zwei-Personen-Entscheidungslogik und Überraschungswege bleiben unverändert.
- Keine neue Supabase-Migration.
- Kein OpenAI-API-Aufruf.

## Release

- Version: `1.10.0+200`
- Private Android-Version

## V1.10.0 Teststabilisierung

- Die Discovery-Regressionstests scrollen vor der Prüfung der Ergebnis-Karten in den relevanten Listenbereich.
- Dadurch prüfen die Tests die tatsächlich gebauten Widgets und hängen nicht vom initialen Viewport ab.
