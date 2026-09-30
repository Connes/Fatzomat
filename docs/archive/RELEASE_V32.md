# Release v32

## Neues Rezept finden

Der Kernflow wurde ausgebaut:

- persönliche Lieblingslebensmittel laden
- Suche nach Lebensmitteln
- Filter nach Kategorie
- mehrere Lebensmittel auswählen
- Auswahl löschen
- Portionen von 1 bis 12
- maximale Kochzeit 20 / 30 / 45 / 60 Minuten
- drei Rezeptvorschläge statt einer langen Ergebnisliste
- Vorschlagskarten mit Zeit, Portionen und Schwierigkeit
- vollständige Rezeptdetailseite
- Rezept direkt in „Meine Rezepte“ speichern

## KI-Generierung

Die App übergibt die gewünschte maximale Gesamtzeit an die Edge Function. Die Edge Function validiert zusätzlich serverseitig, dass die KI kein Rezept zurückgibt, das diese Zeit überschreitet.

## Datenbank

Keine neue Migration erforderlich. v32 verwendet die bereits eingerichtete `foods`, `user_food_preferences` und `recipes` Struktur.

## Sicherheitsfix

Die Edge Function filtert persönliche Lebensmittelpräferenzen jetzt ausdrücklich nach dem authentifizierten Benutzer. Dadurch können bei der Rezeptgenerierung keine Lieblingslebensmittel anderer Nutzer in den erlaubten Katalog gelangen.
