# together V94 Fix7

## Fix
- Die Navigation von „Neue Rezepte suchen“ erhält eine eindeutige Route `/cook/new-recipes`.
- Der V94-Test prüft die tatsächlich gepushte Route über einen `NavigatorObserver` statt über eine künstliche Wartezeit.
- Das blockierende Fake-Repository bleibt bestehen, damit `CookRecipeGenerationPage` während des Tests nicht sofort durch die Ergebnisroute ersetzt wird.
- Keine Änderung am Rezeptgenerierungsablauf selbst.

## Version
- App-Version bleibt `0.1.0+94`.
