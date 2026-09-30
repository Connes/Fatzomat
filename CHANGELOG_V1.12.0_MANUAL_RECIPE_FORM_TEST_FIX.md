# Changelog – v1.12.0 Manual Recipe Form Test Fix

## Fix

- Behebt den Flutter-Testfehler `Bad state: Too many elements` in `add_recipe_page_visual_test.dart`.
- Der Test scrollt nicht mehr über `find.text('Zutat')`, weil dieser Finder im aufgebauten Widget-Baum nicht eindeutig genug ist.
- Stattdessen wird das konkrete Zutaten-`TextField` anhand von `decoration.labelText == 'Zutat'` eindeutig gefunden und an dieses Widget gescrollt.

## Unverändert

- Keine Änderungen an `ManualRecipePage`, Repository, Model, Navigation oder Save-Logik.
- Keine Änderungen an Supabase, RLS, RPCs, Assets oder Dependencies.
