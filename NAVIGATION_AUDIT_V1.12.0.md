# Navigation Audit V1.12.0

## Ergebnis

Die App verwendet `AppShell` als globalen Container mit einer persistenten `NavigationBar` für Heute, Rezepte, Einkauf und Profil.

Vor der Korrektur wurden Unterseiten über `Navigator.push` aus den Hauptseiten geöffnet. Dadurch lag die neue Route oberhalb des `AppShell`-Scaffolds und die globale `NavigationBar` war auf diesen Unterseiten nicht sichtbar.

## Korrektur

`AppShell` besitzt jetzt einen eigenen Content-Navigator. Die globale `NavigationBar` bleibt außerhalb dieses Navigators und damit auch bei allen normalen Push-Routen sichtbar.

Beim Wechsel eines Haupttabs wird der Content-Navigator zunächst bis zur Shell-Root-Route zurückgesetzt. Dadurch bleibt keine zuvor geöffnete Detailroute über dem neu ausgewählten Hauptbereich liegen.

Der aktuell ausgewählte Hauptbereich wird über einen `ValueNotifier<int>` in der persistenten Content-Route synchron gehalten.

## Geprüfte Navigation

### Normale Seiten / Unterseiten

- Heute
- Rezepte
- Einkauf
- Profil
- Rezeptdetail
- Rezept hinzufügen
- Rezept bearbeiten / Import-Flows
- Rezeptvorschläge
- Verbindungen
- Benachrichtigungen
- Einstellungen / Profil-Unterseiten
- Food Modes
- Überraschungsseite
- Restaurant-/Bestellseiten

Diese Seiten werden aus dem App-Bereich heraus über `Navigator.push` geöffnet und profitieren vom persistenten Shell-Navigator.

### Bewusst außerhalb der globalen Navigation

- Startup-/Fehlerzustände vor dem AppShell
- Food-Onboarding vor Abschluss des Onboardings
- Dialoge und Bottom-Sheet-artige temporäre UI
- externe Systemaktionen

Diese Zustände sind keine normalen App-Unterseiten und erhalten deshalb keine globale NavigationBar.

## Back-Verhalten

Der AppShell-Back-Handler berücksichtigt jetzt zuerst den Content-Navigator. Ist eine Unterseite geöffnet, wird diese zuerst geschlossen. Ist keine Unterseite geöffnet und ein anderer Haupttab aktiv, führt Back zu Heute.

## Regressionstest

Hinzugefügt:

`test/regression/global_navigation_persistence_test.dart`

Der Test prüft die Shell-Architektur, die persistente Navigation außerhalb des Content-Navigators sowie den synchronisierten Tab-Zustand.

## Verifikation

In der verfügbaren Ausführungsumgebung waren Flutter/Dart nicht installiert. Daher wurden keine echten `flutter analyze`- oder `flutter test`-Läufe behauptet.

Die Änderung wurde statisch geprüft. Der lokale Flutter-Lauf muss anschließend auf der Entwicklerumgebung ausgeführt werden.
