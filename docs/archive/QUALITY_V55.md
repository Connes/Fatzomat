# V55 – Qualitäts- und Robustheitsrunde

## Ziel
V55 stärkt die bestehende App ohne neue Produktbereiche einzuführen. Fokus sind nachvollziehbare Fehlerzustände, Retry-Flows und eine kleine zusätzliche Testschicht.

## Umgesetzt
- Wiederverwendbarer `AppErrorView` für fehlgeschlagene Datenabrufe.
- Retry direkt in Heute, Einkauf und Rezeptdetail.
- Ladefehler werden als Zustand gehalten statt nur als SnackBar gemeldet.
- Erfolgreiche Reloads löschen den Fehlerzustand wieder.
- Einheitliche, deutschsprachige Fehlermeldungen.
- Unit-Tests für die Fehlerklassifikation.
- CI bleibt bei `flutter analyze` und `flutter test`.

## Bewusst nicht enthalten
- Keine Vorratsverwaltung.
- Keine Rezeptänderung aus der Einkaufsliste.
- Keine Bestell- oder Reservierungslogik.
- Keine neue Backend-Abhängigkeit.

## Release-Gates
```text
flutter pub get
flutter analyze
flutter test
flutter build apk
```

Zusätzlich manuell testen: Netzwerk während Heute/Einkauf/Rezeptdetail deaktivieren, Retry ausführen und danach bei wiederhergestellter Verbindung erneut laden.
