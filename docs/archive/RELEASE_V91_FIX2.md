# together V91 Fix2

## Fix

Der Test `V91 öffnet die Beilage-Auswahl` wartete nach der Navigation nur einen einzelnen Frame ab. Da `IngredientCategoryPage` die Lebensmittel asynchron lädt, konnte der Test noch den Loading-Zustand prüfen.

Der Test verwendet jetzt `pumpAndSettle()`, bevor Titel und Beschreibung der Beilage-Auswahl geprüft werden.

## App-Funktionalität

Keine Änderung an der V91-App-Implementierung. Die Kategorien Beilage, Gemüse und Favoriten sowie die Mehrfachauswahl bleiben unverändert.
