# Schmackofatz v1.12.0 – Food Onboarding Welcome Redesign

## Änderung

Die Willkommensseite des Lebensmittel-Onboardings wurde ausschließlich optisch und strukturell überarbeitet:

- Vollflächiger bestehender Settings-Hintergrund bleibt erhalten.
- Die bisher separate Schmackofatz-Box und der Begrüßungsbereich wurden zu einer gemeinsamen Box zusammengeführt.
- Das bestehende `BrandMark` mit dem echten `assets/branding/app_icon.png` wird links neben „Schmackofatz“ verwendet.
- Ein Divider trennt Branding und „Willkommen!“ optisch.
- Der Begrüßungstext bleibt kurz und erklärt Zweck und Nutzen des Lebensmittel-Onboardings.
- „Lebensmittel einrichten“ ist als unterer Primär-Button angeordnet.
- `CustomScrollView`/`SliverFillRemaining` sorgt für eine flexible Darstellung und vertikales Scrollen bei kleinen Displays, ohne feste Bildschirmhöhe oder absolute Positionierung.
- Bestehende Lebensmittel-, Repository-, Onboarding-Abschluss- und Navigationslogik wurde nicht geändert.

## Regression

`test/regression/food_onboarding_intro_visual_test.dart` wurde um Prüfungen für BrandMark, Divider, gemeinsame Welcome-Box, responsive Scroll-Struktur und unveränderte Setup-/Abschlusslogik ergänzt.

Flutter/Dart sind in der Arbeitsumgebung nicht installiert; daher wurden `flutter analyze` und `flutter test` hier nicht ausgeführt.

## Korrektur nach lokalem Testlauf

- Die Regressionserwartung für `BrandMark` wurde an die tatsächlich gültige `const BrandMark(...)`-Schreibweise angepasst.
- Die Intro-Seite verwendet nicht mehr einen äußeren `SingleChildScrollView` um den eigenen `CustomScrollView`. Dadurch erhält `SliverFillRemaining` echte Viewport-Höhe und kann den Primärbutton zuverlässig am unteren Rand platzieren, ohne verschachtelte vertikale Scrollbereiche.
- Die Regression prüft zusätzlich, dass der äußere `SingleChildScrollView` nicht wieder eingeführt wird.
