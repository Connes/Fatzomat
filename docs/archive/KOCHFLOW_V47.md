# Kochflow V47

## Produkt
- Kochflow auf zwei Entscheidungen reduziert: Hauptfokus und optionale Zutaten.
- Kategorien aus dem Rezept-Builder entfernt; Suche bleibt als schneller Filter.
- Rezeptvorschläge als visuelle Karten mit klarer primärer Aktion.
- Rezeptdetail priorisiert „Für uns heute festlegen“.
- „Für uns heute“ speichert ein generiertes Rezept automatisch, falls nötig.
- Portionen bleiben direkt im Rezeptdetail veränderbar.

## Technisch
- Rezept-Rendering verwendet das Typed `Recipe`-Modell statt direkter Map-Zugriffe.
- Generated recipe flow bleibt kompatibel mit dem bestehenden Supabase-Repository.
- Keine neue externe Bild- oder API-Abhängigkeit eingeführt.

## Noch offener Release-Gate
Flutter Analyze/Test/Android Release müssen in einer Flutter-Umgebung ausgeführt werden.
