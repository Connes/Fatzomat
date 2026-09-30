# Schmackofatz v1.13.1

## Build- und Analysefehler behoben

- `image_picker` als direkte Abhängigkeit ergänzt, damit der Foto-Rezeptworkflow wieder korrekt aufgelöst und analysiert werden kann.
- `share_plus` als direkte Abhängigkeit ergänzt; die bestehende `SharePlus.instance.share`-API bleibt erhalten.
- `AppException` von `sealed` auf `abstract` umgestellt, damit die fachliche `RecipeDuplicateException` in `recipe_repository.dart` weiterhin von der zentralen Fehlerhierarchie ableiten kann.
- `TextEditingController`-Constructor-Tear-off im manuellen Rezeptformular durch einen typkompatiblen Closure-Aufruf ersetzt.
- Veralteten V1.5-Hinweis im Setup-Skript korrigiert.
