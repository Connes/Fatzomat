# together V92

## Zutaten-Auswahl präzisiert

- „Weitere Zutaten“ bietet weiterhin genau die drei Bereiche Beilage, Gemüse und Favoriten.
- Beilage ist bewusst auf Reis, Nudeln/Pasta und Kartoffelvarianten begrenzt.
- Gemüse nutzt die bestehende Kategorie „Gemüse“ und schließt Kartoffelvarianten aus.
- Favoriten werden unabhängig von ihrer Food-Kategorie über `user_food_preferences.preference = 'like'` geladen.
- Mehrfachauswahl und die Übergabe der ausgewählten Food-IDs bleiben erhalten.
- Die bestehenden Together-Hintergründe und das UI-System werden weiterverwendet.
- Keine Supabase-Migration erforderlich.

## Tests

Die V92-Tests decken Kategorien, Beilage-Filter, Gemüse-Ausschluss, Favoritenfilter und die Auswahlübergabe ab.

Version: `0.1.0+92`
