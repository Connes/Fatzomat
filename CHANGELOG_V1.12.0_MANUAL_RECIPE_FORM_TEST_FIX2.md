# Schmackofatz v1.12.0 – Manual Recipe Form Test Fix 2

- Behebt den verbleibenden Widget-Testfehler in `add_recipe_page_visual_test.dart`.
- Der Zutatenbereich wird in der `ListView` zunächst über den Abschnittstitel `Zutaten` sichtbar gemacht.
- Erst danach wird das tatsächlich aufgebaute `Zutat`-Textfeld eindeutig gesucht.
- Keine Änderung an Produktionslogik, Modellen, Repository, Navigation, Supabase, Assets oder Dependencies.
