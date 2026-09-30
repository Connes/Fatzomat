# Schmackofatz v1.13.0 – Shared Recipe Collection v2

## Gemeinsame Rezeptsammlung

- Beide verbundenen Nutzer verwenden dieselbe Rezeptsammlung.
- Bestehende Rezepte des jeweils anderen Verbindungsteilnehmers werden automatisch sichtbar.
- Neue Rezepte werden zentral über `create_shared_recipe` gespeichert.
- Bearbeiten und Löschen laufen über abgesicherte Shared-Recipe-RPCs.
- `updated_at` und ein deterministischer `recipe_fingerprint` wurden ergänzt.
- Die bestehende persönliche Tagesentscheidung bleibt getrennt von der gemeinsamen Rezeptbasis.

## Duplikatschutz

- Rezeptname und normalisierte Zutaten werden für einen deterministischen Fingerprint verwendet.
- Vor dem Speichern wird auf ein identisches Rezept geprüft.
- Der Nutzer kann ein vorhandenes Rezept öffnen oder ausdrücklich trotzdem eine Variante speichern.
- Keine automatische Zusammenlegung lediglich ähnlicher Rezepte.

## Push und Realtime

- Neue gemeinsame Rezepte erzeugen die Notification `recipe_created` ausschließlich für die andere verbundene Person.
- Push-Daten enthalten `recipe_id`.
- Push-Tap öffnet direkt das Rezept.
- Realtime auf `recipes` aktualisiert die gemeinsame Rezeptliste ohne manuelles Neuladen.

## Rezept-Erstellung

- Manuelle Neuerstellung ist nicht mehr über die Rezept-UI erreichbar.
- Verfügbare Wege:
  - Mit ChatGPT erstellen
  - Rezept aus Foto erstellen
  - Rezeptdatei importieren
- Der bestehende Editor bleibt intern für das Bearbeiten gemeinsamer Rezepte erhalten.

## Foto → ChatGPT → JSON

- Fotoaufnahme oder Galerieauswahl über `image_picker`.
- Foto und der neue, schemafeste Foto-Prompt werden über den System-Teilen-Dialog übergeben.
- Der Prompt fordert die Ausgabe im vorhandenen `together_recipe` Version-1-Format und verbietet erfundene Angaben.
- Die bestehende JSON-Validierung und Rezeptvorschau werden wiederverwendet.
- Vor dem endgültigen Speichern wird auf identische Rezepte geprüft.

## Rezeptvorschläge

- Der bisherige Rezeptvorschlags-Workflow ist nicht mehr Bestandteil der aktiven Rezept-UI.
- Historische Tabellen und Migrationen bleiben erhalten, um bestehende Daten nicht rückwirkend zu beschädigen.
