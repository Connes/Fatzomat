# together Food App V92 Fix1

## Korrektur

Der V92-Test für die Rückgabe ausgewählter Food-IDs verwendete den Navigator über `tester.state(find.byType(Navigator))`. Das war in dieser Teststruktur nicht zuverlässig und führte zu `Bad state: No element`, obwohl die eigentliche Navigation funktionierte.

Der Test verwendet jetzt einen expliziten `GlobalKey<NavigatorState>` und prüft weiterhin den vollständigen Flow:

1. Kategorie öffnen
2. „Reis“ auswählen
3. „Auswahl übernehmen (1)“ auslösen
4. Rückgabewert auf `{'rice'}` prüfen

Keine Änderung am produktiven App-Code erforderlich.
