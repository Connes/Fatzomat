# V1.12.0 – Food-Onboarding: Add-Aktion repositioniert

## Änderung

- Den bisherigen Plus-Button aus dem oberen Setup-Header entfernt.
- Die bestehende `addFood()`-Aktion in die Zählerzeile verschoben, an die Stelle des bisherigen „Später änderbar“-Hinweises.
- „Später änderbar“ entfernt.
- Die bestehende „Kurz einrichten“-Box rückt dadurch ohne zusätzlichen Header nach oben.

## Unverändert

- FoodRepository, Profil-/Onboarding-Abschluss, Präferenzen und Navigation.
- Lebensmittel-Auswahl, Kategorien, Like/Dislike und „Los geht’s“.
- App-Hintergrund, AppDesign, AppSurface und vorhandenes App-Logo.

## Tests

Der Regressionstest prüft die neue Position der bestehenden Add-Food-Aktion und das Entfernen des alten Header-/Hinweis-Elements. Flutter/Dart ist in der Bearbeitungsumgebung nicht installiert; `flutter analyze` und `flutter test` konnten hier daher nicht ausgeführt werden.
