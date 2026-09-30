# V51 – Gemeinsames Essen

## Ziel
Die optionale Zwei-Personen-Funktion wird als gemeinsamer, ruhiger Arbeitsbereich behandelt. Keine Social-Features, keine Nachrichtenplattform.

## Umgesetzt
- Verbindungscode kopierbar.
- Verbindungsstatus wird auf beiden Geräten über Supabase Realtime aktualisiert.
- Wartestatus und aktiver Zwei-Personen-Status werden klar unterschieden.
- Gemeinsame gespeicherte Rezepte werden in der Rezeptsammlung angezeigt.
- Gemeinsame Rezepte erhalten ein „Gemeinsam“-Badge.
- Bestehende Realtime-Synchronisation für gespeicherte Rezepte und Heute bleibt aktiv.
- Typisiertes `ConnectionInfo`-Model ergänzt.
- `connection_members` für Realtime aktiviert.
- Verbindung trennen bleibt sicher und löscht nur die Mitgliedschaft; persönliche Rezepte bleiben erhalten.

## Produktgrenze
Die Zusammenarbeit bleibt auf Sammlung, Heute und Einkauf beschränkt. Kein Feed, keine Freunde/Follower und keine Chat-Funktion.
