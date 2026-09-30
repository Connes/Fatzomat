# Schmackofatz v1.13.6

## Zutatenabschnitte

- Rezeptimporte aus Fotos können Zutatenabschnitte wie „Teig“, „Füllung“, „Belag“, „Creme“ oder „Sauce“ strukturiert übernehmen.
- Die Abschnittsinformation ist Bestandteil jeder Rezeptzutat und bleibt beim Speichern, Skalieren, Exportieren und Bearbeiten erhalten.
- Import-Vorschau und gespeicherte Rezeptdetailansicht zeigen Zutaten getrennt nach ihren Abschnitten.
- Der manuelle Rezepteditor kann einer Zutat optional einen Zutatenabschnitt zuweisen.
- Der ChatGPT-Importprompt fordert die Erkennung und Erhaltung sichtbarer Zutatenüberschriften im Foto.
- Bestehende Rezepte ohne Abschnitt bleiben vollständig kompatibel und werden als normale Zutatenliste dargestellt.
- Supabase wurde um `recipe_ingredients.section` erweitert; die RPCs bleiben kompatibel mit der tatsächlich deployten `recipes`-Struktur ohne `updated_at` und `recipe_fingerprint`.
