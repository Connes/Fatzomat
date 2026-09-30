# Release v39

Technische Foundation-/Hardening-Runde.

- persönliche Datenstruktur bereinigt: alte Household-, Meal-Plan- und Shopping-Tabellen aus der produktiven Supabase-Datenbank entfernt
- Lebensmittelkategorien vereinheitlicht
- Supabase-Konfiguration auf `--dart-define` umgestellt
- Repository-Schicht für Profile und Lebensmittel ergänzt
- RecipeRepository robuster gemacht, inklusive Antwortvalidierung und Rollback beim Speichern
- zentrale Fehlertexte verbessert
- echte Validierungstests für Rezeptdaten ergänzt
- Android-Studio-Setup erkennt das lokale Flutter/Dart-SDK dynamisch
- Startseite bleibt vollständig sichtbar und scrollbar-frei
- Edge Function lokal gehärtet: Auswahl, Duplikate, vegetarische Regeln und Pflichtzutaten werden validiert
