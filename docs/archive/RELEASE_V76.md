# V76 – Stabilisierung & Startseite finalisieren

## Startseite
- Kein Header, Logo oder zusätzlicher Erklärungstext.
- Vier freigegebene Karten-Assets bleiben unverändert und werden als vollständige Karten verwendet.
- Fotorealistischer Food-Hintergrund aus der freigegebenen Vorlage bleibt aktiv.
- Statusleisten-Icons auf der Startseite sind hell, damit sie auf dem dunkleren Fotobereich oben lesbar bleiben.
- Vier Auswahlkarten sind als echte Buttons mit Semantics-Labels bedienbar.
- Layout bleibt responsiv und erhält das 2×2-Verhältnis der 540×480-Karten.

## Launch
- Der Launchscreen ist auf exakt 4 Sekunden Gesamtpräsentation ausgelegt.
- Der 350-ms-Übergang ist in die 4 Sekunden eingerechnet, nicht zusätzlich oben drauf.

## Stabilität
- Setup prüft alle fünf für die Startseite benötigten PNGs vor dem Build.
- Kotlin-Kompilierung läuft in-process.
- Gradle-Daemon ist für stabilere lokale Debug-Builds deaktiviert.
- Kotlin-Incremental-Compilation ist für lokale Stabilität deaktiviert.
- Setup führt `flutter analyze`, `flutter test` und anschließend `flutter build apk --debug` aus.
- Asset-Tests prüfen PNG-Gültigkeit, Dimensionen und die vier zugänglichen Startseiten-Aktionen.
- `setup.sh` ist als kompatibler Einstiegspunkt vorhanden und ruft das eigentliche Setup auf.
