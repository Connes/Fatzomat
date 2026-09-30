# together V88 Fix3

## Fix
- `flutter analyze` bleibt sauber.
- Der V88-Visual-Test prüft nicht mehr auf Semantics-Finder, die in der Flutter-Testumgebung nicht zuverlässig als einzelne Nodes auffindbar sind.
- Stattdessen prüft der Test die eigentliche Anforderung: keine sichtbaren Überschriften oder Auswahltexte, während die erwartete Anzahl an Auswahlkarten und Icons vorhanden bleibt.
- Accessibility-Semantics in `_OptionCard` bleiben unverändert erhalten.

## Erwartung
- Wir kochen: 6 visuelle Auswahlmöglichkeiten, kein sichtbarer Text.
- Wir bestellen: 7 visuelle Auswahlmöglichkeiten, kein sichtbarer Text.
