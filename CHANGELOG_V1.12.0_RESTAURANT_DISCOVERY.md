# Schmackofatz V1.12.0 – Restaurant & Lieferdienst Discovery

## Food-Choice-Grafiken

- Die Auswahlkarten in „Wir kochen“, „Wir bestellen“ und „Wir gehen essen“ verwenden jetzt die neuen dedizierten Food-Choice-Assets.
- Die Zuordnung von Auswahlwert zu Asset ist zentral in `FoodChoiceAssetService` gekapselt.
- Die bestehenden vier „Wie entscheide ich mich heute?“-Referenzgrafiken bleiben unverändert.
- Die bestehende Entscheidungs-, Discovery-, Today- und Connection-Logik wurde nicht verändert.

## Implementiert

- „Wir gehen essen“ nutzt den aktuellen Gerätestandort und sucht live im festen Radius von 20 km.
- „Wir bestellen“ nutzt denselben Discovery-Ablauf, filtert aber auf explizit als Lieferung gekennzeichnete OSM-Einträge.
- Maximal 10 unterschiedliche Treffer, nach Entfernung sortiert.
- Restaurant-/Anbieterliste mit Name, Ort und Entfernung.
- Detailansicht mit tatsächlich gelieferten Telefon-, Website- und Bestelllinks.
- Telefonnummern und externe URLs werden nicht erfunden und nur geöffnet, wenn sie als gültige Daten vorliegen.
- Persönliche `dine_out`-/`order`-Entscheidung bleibt vom Collaboration-Modus getrennt.
- Restaurantdaten werden nicht dauerhaft in Supabase gespeichert.
- Externe Suche läuft gekapselt über eine Supabase Edge Function gegen OpenStreetMap/Overpass.
- Standortberechtigungen für Android und iOS ergänzt.

## Surprise Recommendations

- „Überrasch mich“ erzeugt jetzt konkrete persönliche Vorschläge statt nur einer Kategorieentscheidung.
- Kochen: bis zu 3 unterschiedliche persönliche Rezepte.
- Essen gehen: bis zu 10 echte Restauranttreffer innerhalb des bestehenden 20-km-Radius.
- Bestellen: bis zu 10 echte Liefer-/Bestelltreffer innerhalb des bestehenden 20-km-Radius.
- Die persönliche Today-Entscheidung wird erst nach Auswahl eines konkreten Vorschlags gespeichert.
- Restaurant- und Lieferdaten bleiben externe Live-Daten und werden nicht als persönliche Daten gespeichert.
