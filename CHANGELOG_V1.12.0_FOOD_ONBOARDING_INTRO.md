# Schmackofatz v1.12.0 – Food Onboarding Intro

## Änderung

Das erste Onboarding für „Meine Lebensmittel einrichten“ wurde ausschließlich optisch/UX-seitig umgebaut.

- Der bestehende `TogetherBackground` mit `TogetherBackgroundType.settings` wird ohne AppBar als vollflächiger Seitenhintergrund verwendet.
- Die sichtbare Überschrift „Meine Lebensmittel einrichten“ wurde entfernt.
- Oben wird „Schmackofatz“ zentriert in einer bestehenden `AppSurface`-Box dargestellt.
- Darunter steht eine kompakte Begrüßungs- und Erklärungskarte.
- Ein Button „Lebensmittel einrichten“ wechselt innerhalb des bestehenden Onboarding-Flows in die vorhandene Lebensmittel-Auswahl.
- Die bisherige Lebensmittel-Auswahl, Suche, Kategorien, Präferenzen, Lieblingsrezept-Funktion und `completeOnboarding`-Logik bleiben erhalten.

## Technische Grenzen

Keine Änderungen an Supabase, RLS, RPCs, Datenmodellen, Repositories, Connection, Today, Restaurant Discovery, Rezeptlogik oder Lebensmittel-Datenlogik.

## Tests

Ergänzt wurde `test/regression/food_onboarding_intro_visual_test.dart` mit Regressionen für die neue Intro-Struktur und den Erhalt der bestehenden Abschlusslogik.

Flutter/Dart ist in der Ausführungsumgebung nicht installiert; `flutter analyze` und `flutter test` konnten daher hier nicht ausgeführt werden.
