# V86 – Punkt 3: Zentrales Background-System

## Umsetzung

- `TogetherBackgroundType` bündelt alle 24 Screen-/Zustandsgruppen, einschließlich der Startseite.
- `TogetherBackgroundAssets` enthält die zentrale Zuordnung von Typ zu Asset.
- `TogetherBackground` stellt eine einheitliche, nicht-interaktive Hintergrundschicht bereit.
- Einheitliche Standardwerte für `BoxFit.cover`, Ausrichtung und Bildqualität.
- Optionales, dezentes Overlay für zusätzliche Textlesbarkeit.
- Die bestehende Startseiten-Grafik `home_photo_background.png` bleibt unverändert und wird lediglich über dieselbe Struktur angesprochen.
- Die neuen Unterseiten-Hintergründe werden in diesem Schritt noch nicht in die einzelnen Screens eingebaut. Das folgt bei der Screen-Integration.

## Tests

- Regressionstest stellt sicher, dass alle Background-Typen eindeutig auf ein Asset zeigen.
- Startseite bleibt explizit auf ihrem bestehenden Asset.
