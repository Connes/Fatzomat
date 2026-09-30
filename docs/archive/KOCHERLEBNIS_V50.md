# V50 – Kocherlebnis

## Ziel
Der Kochbereich führt ohne Zusatzkomplexität von drei Vorschlägen zu einem kochbaren Rezept und anschließend zu Heute.

## Umgesetzt
- Rezeptvorschläge können direkt neu generiert werden, ohne den Ergebnis-Screen zu verlassen.
- Generierte Rezepte zeigen eine visuelle Rezeptkarte und einen Kochfortschritt pro Zubereitungsschritt.
- Zubereitungsschritte sind antippbar und werden mit Fortschritt/Abschluss dargestellt.
- Portionsanpassung ist typisiert und skaliert beim Speichern auch die Zutatenmengen.
- „Für uns heute festlegen“ bleibt die primäre Aktion.
- Gespeicherte Rezepte haben ebenfalls einen Kochfortschritt und können, wenn sie für heute geplant sind, als gekocht markiert werden.
- Der Heute-/Einkaufsfluss bleibt die einzige interne Folgeaktion; Bestellung und Restaurant-Discovery bleiben externe Weiterleitungen.
- Neue Regressionstest-Abdeckung für Portionsskalierung.

## Bewusst nicht enthalten
- Keine eigene Bestell-/Lieferfunktion.
- Keine erfundenen Food-Bilder oder externe Bild-API.
- Keine dauerhafte Speicherung des Schrittfortschritts, solange dafür kein Produktbedarf besteht.
