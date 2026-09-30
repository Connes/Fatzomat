# V89 Schritt 3

„Neues Rezept generieren“ ist als direkter Generierungsfluss implementiert. Die zuvor gewählte Hauptauswahl wird an den Generator übergeben. Der Generator verwendet die bestehende RecipeRepository-Logik mit drei Rezeptvorschlägen, 2 Portionen und 45 Minuten maximaler Kochzeit. Nach erfolgreicher Generierung öffnet er die bestehende RecipeResultsPage; bei einem Fehler wird eine Retry-Oberfläche angezeigt.

Der zugehörige Widget-Test prüft den neuen Loading-Route-Einstieg ohne einen echten Backend-Aufruf abzuwarten. Die Optionen „Weitere Zutaten auswählen“ und „Aus meinen Rezepten wählen“ bleiben unverändert.
