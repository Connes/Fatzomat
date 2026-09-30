# V42 technische Härtung

- Rezeptzutaten sind für verbundene Personen lesbar, wenn das Rezept in der gemeinsamen Sammlung liegt oder für heute geplant ist.
- `recipe_saves`, `shared_recipe_plans` und `shopping_items` werden per Supabase Realtime synchronisiert.
- Das Entfernen eines Rezepts entfernt nur den eigenen Save; ein gemeinsamer Save bleibt bestehen.
- Ein Rezept wird nur endgültig gelöscht, wenn es niemand mehr gespeichert hat und es nicht in einem aktiven Tagesplan verwendet wird.
- Die Verbindungsverwaltung zeigt jetzt den Verbindungsstatus und die Anzahl der Mitglieder.
- Eine Verbindung kann auf dem eigenen Gerät sauber getrennt werden. Eigene Rezepte und Favoriten bleiben erhalten.
- Supabase enthält `connection_info()` und `disconnect_connection()` als geschützte RPCs.
