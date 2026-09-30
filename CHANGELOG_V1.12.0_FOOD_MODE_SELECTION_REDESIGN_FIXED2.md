# Schmackofatz v1.12.0 – Food-Mode Selection Regression Fix 2

## Änderungen

- `cook_next_step_test.dart`: Die bestehende Auswahl `Huhn` wird vor dem Tap deterministisch sichtbar gemacht. Die UI-Semantik und Auswahl-Logik bleiben unverändert.
- `food_mode_selection_visual_test.dart`: Der Bild-Finder berücksichtigt neben `assets/food_choices/` auch die bestehende Überraschungs-Grafik `assets/together/clean/icons/icon_surprise.png`. Damit werden exakt die Auswahlbilder geprüft und nicht das Seiten-Hintergrundbild.
- Keine Änderungen an Navigation, Callbacks, Repository-/Service-Logik, Datenmodellen oder Supabase.

## Verifikation

Der bereitgestellte Nutzer-Log zeigt `flutter analyze` ohne Fehler und 137 erfolgreiche Tests bei 4 Testfehlern. Dieser Patch adressiert genau diese vier Regressionstest-Ursachen. Flutter selbst kann in der Erstellungsumgebung dieses ZIPs nicht ausgeführt werden.
