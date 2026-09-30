# Schmackofatz v1.13.19+231

## Manuelle Rezeptbilder

- Der bestehende manuelle ChatGPT-Rezeptworkflow bleibt ohne OpenAI-API unverändert.
- Der Rezept-Prompt erklärt jetzt, dass das gerade erzeugte Rezept anschließend direkt als Grundlage für die separate Bildgenerierung verwendet werden kann.
- Rezept-JSON und Bilddatei bleiben getrennt.
- Beim JSON-Import kann optional ein Rezeptbild aus Galerie oder Kamera ausgewählt werden.
- Rezeptbilder werden in einem privaten Supabase-Storage-Bucket gespeichert.
- Zugriff auf Rezeptbilder folgt dem bestehenden Rezeptzugriff für Eigentümer und verbundene Nutzer.
- Rezeptdetailansicht unterstützt Bild hinzufügen, ersetzen und entfernen.
- Bestehende JSON-Dateien ohne Bild bleiben vollständig kompatibel.
