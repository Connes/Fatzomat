# V56 – Design Polish

## Ziel
Visuelle Konsistenz und bessere Bedienbarkeit ohne neue Produktlogik.

## Umgesetzt
- ruhigeres Card-/Surface-System ohne flächendeckende Rahmen
- konsistentere Button-Radien und Touch-Ziele
- klarere Typografie-Hierarchie
- wiederverwendbare `AppSurface`- und `MetaPill`-Komponenten
- Startseite mit klarerem visuellen Fokus
- Rezeptdetail mit Hero-Bereich, Metadaten-Pills und klar getrennten Zutaten-/Zubereitungssektionen
- Zubereitungsschritte mit besserem Fortschrittsfeedback
- Eingaben und Navigation mit mindestens 44 px Touch-Zielen
- keine neuen Daten-/Produktfunktionen

## Bewusst nicht enthalten
- Dark Mode, da die bestehenden Feature-Screens noch mehrere harte Light-Farben verwenden
- externe Food-Bild-API, da dafür eine belastbare Bildquelle und Caching-Strategie nötig wären
