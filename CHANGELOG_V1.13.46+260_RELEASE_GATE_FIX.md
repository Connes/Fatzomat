# Schmackofatz v1.13.46+260 – Release-Gate-Fix

## Anlass
Der Release-Gate für v1.13.46+259 hat festgestellt, dass mehrere Regressionstests noch die vorherige Build-Version 1.13.46+258 erwarteten.

## Änderung
- App-Version auf `1.13.46+260` erhöht.
- Alle betroffenen Regressionstests auf `1.13.46+260` synchronisiert.
- Keine fachliche Funktionalität geändert.

## Ziel
Die Versionserwartungen müssen exakt mit der tatsächlich ausgelieferten App-Version übereinstimmen, bevor die ZIP für den Handytest freigegeben werden kann.
