# Release V42

## Technische Stabilisierung der Zwei-Personen-Funktionen

- Partner können Zutaten von Rezepten aus der gemeinsamen Sammlung lesen.
- `recipe_saves` ist für Supabase Realtime aktiviert.
- Die Rezeptsammlung aktualisiert sich bei Änderungen auf dem zweiten Gerät automatisch.
- Der gemeinsame Tagesplan aktualisiert sich bei Änderungen per Realtime.
- Die gemeinsame Einkaufsliste aktualisiert sich bei Änderungen per Realtime.
- Das Entfernen eines Rezepts läuft über `remove_recipe_from_collection`. Ein Rezept wird nur endgültig gelöscht, wenn niemand es mehr gespeichert hat und es nicht mehr als aktiver Tagesplan verwendet wird.
- Ein gemeinsam gespeichertes Rezept bleibt für die andere Person erhalten, wenn eine Person es aus der eigenen Sammlung entfernt.

## Supabase

Migration `20260914193000_harden_shared_recipe_access_v42.sql` wurde live auf dem MVP-Projekt angewendet.

## Lokaler Check

Auf dem Entwicklungsrechner ausführen:

```bash
./setup.sh
flutter analyze
flutter test
```
