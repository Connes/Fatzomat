# V86 – Hintergrund-Assets für Unterseiten

## Umfang

V86 liefert die erste Asset-Runde für die visuellen Hintergründe der Unterseiten. Der bestehende Startseiten-Hintergrund bleibt unverändert und wird bewusst nicht dupliziert.

### Neue Hintergründe

- Rezepte und Rezeptdetail
- Heute
- Entscheidungsanfrage und Ergebnis
- Benachrichtigungen und Detail
- Profil und Profil bearbeiten
- Einstellungen
- Hilfe & Support
- Rechtliches
- Login, Registrierung und Passwort zurücksetzen
- Fehler, Offline und leerer Zustand
- Suche und Filter
- Teilen
- Über die App
- Update

Alle Assets liegen unter `assets/together/clean/background/` und sind über die bereits vorhandene Verzeichnis-Asset-Deklaration in `pubspec.yaml` eingebunden.

## Designprinzipien

Die Motive orientieren sich an der Startseite: warme Food-/Naturästhetik, organische Flächen, dezente Texturen, ruhige Bereiche für UI-Inhalte und keine eingebetteten UI-Texte oder Logos.

## Qualitätssicherung

`test/v86_background_assets_test.dart` prüft, dass alle 23 neuen Hintergrund-Assets vorhanden und nicht leer sind. Die bestehenden Regressionstests wurden auf die aktuelle App-Version `0.1.0+86` aktualisiert.

## Bewusst nicht enthalten

Die Integration der neuen Hintergründe in die einzelnen Flutter-Seiten ist **nicht Bestandteil dieser Runde**. Sie folgt in der nächsten V86-Implementierungsstufe über eine zentrale `TogetherBackground`-Komponente.

## Punkt 3 – Zentrales Background-System

V86 enthält jetzt `TogetherBackgroundType`, `TogetherBackgroundAssets` und `TogetherBackground` als zentrale technische Struktur für alle 24 Hintergrundgruppen. Die Startseite ist dabei ausdrücklich enthalten und verwendet weiterhin unverändert `home_photo_background.png`.

Die einzelnen Unterseiten werden erst im nächsten Integrationsschritt auf die jeweilige Background-Variante umgestellt.

## Punkt 4 – Integration

Alle bestehenden App-Screens verwenden nun den zentralen `TogetherScaffold` mit dem jeweils passenden Hintergrundtyp. Die Startseite bleibt im gemeinsamen System und verwendet weiterhin ihren bestehenden Home-Hintergrund. Der AppShell-Hintergrund wurde transparent gesetzt, damit die Screen-Hintergründe sichtbar bleiben.

Abgedeckte Screen-Gruppen: Food-Modi, Lebensmittel-Onboarding/-Einstellungen, Rezept-Builder/-Detail/-Sammlung, Profil/Konto/Diagnostik/Benachrichtigungen, Verbindung, Entscheidungsanfrage/-ergebnis sowie Heute/Einkauf.


## Fotorealistische Einzelbilder

Die 23 Unterseiten-Hintergründe wurden als einzelne fotorealistische Portrait-Assets eingesetzt. Die vorhandene Home-Grafik bleibt unverändert. Alle 23 Unterseiten-Assets wurden auf 1080×1920 PNG vereinheitlicht und nicht aus Collagen zugeschnitten.
