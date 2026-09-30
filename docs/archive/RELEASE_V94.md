# together V94

## Persönliche Rezeptauswahl

- „Weitere Zutaten hinzufügen“ ist jetzt Bestandteil der Box „Meine Wahl“.
- Der bisherige Button „Rezepte finden“ wurde entfernt.
- Es gibt zwei getrennte Aktionen:
  - „Neue Rezepte suchen“ nutzt den bestehenden Rezeptgenerator und übergibt Hauptauswahl plus ausgewählte Zutaten.
  - „Aus meinen Rezepten suchen“ öffnet die gespeicherten Rezepte mit einem Auswahlfilter.
- Gespeicherte Rezepte werden anhand der vorhandenen `recipe_ingredients` auf die Hauptauswahl und ausgewählten zusätzlichen Zutaten geprüft.
- Keine neue Supabase-Migration erforderlich.
- Versionsnummer auf `0.1.0+94` erhöht.
