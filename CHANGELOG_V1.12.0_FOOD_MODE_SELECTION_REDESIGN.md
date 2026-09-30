# Schmackofatz v1.12.0 – Food-Mode-Auswahl Redesign

## Umsetzung

Die drei Auswahlseiten „Wir kochen“, „Wir bestellen“ und „Wir gehen essen“ wurden ausschließlich visuell überarbeitet.

- Alle Optionen einer Seite liegen jetzt in einer gemeinsamen `AppSurface`-Box.
- Die einzelnen Auswahlkacheln verwenden vollflächige Bilder mit `BoxFit.cover`.
- Die Auswahltexte werden bei allen drei Modi direkt auf den Bildern in einer gut lesbaren, abgerundeten Beschriftungsfläche dargestellt.
- Das 2-Spalten-Layout bleibt responsiv und nutzt eine scrollbare Seitenstruktur ohne feste Bildschirmhöhe.
- Bestehende Optionen, Navigation, Callbacks, Repositories, Services, Modelle und Supabase-Logik wurden nicht verändert.
- Das Mapping für „Fisch“ verwendet die vorhandene Sushi-Grafik aus dem Restaurant-Assetset, da sie den Fischbezug klarer vermittelt als das bisherige Koch-Asset.
- Keine neuen Dependencies.

## Regression

Der bestehende Visual-Regressionstest wurde auf die neue Struktur angepasst und prüft:

- gemeinsame äußere Box
- alle Auswahltexte
- alle Auswahl-Assets
- vollflächige `BoxFit.cover`-Darstellung
- tappbare Auswahlkacheln
- unveränderte Asset-Abdeckung


## Test-Fix 1

- Corrected the cooking `Fisch` mapping to use the dedicated `assets/food_choices/cooking/fisch.png` asset instead of the restaurant Sushi asset.
- Made the option semantics an explicit container so the existing accessibility-based `Huhn` tap regression remains discoverable.
- Scoped the visual regression image finder to `assets/food_choices/` so the shared background image is not counted as a choice tile image.
- No selection, navigation, repository, model, or Supabase logic changed.
