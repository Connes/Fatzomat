# Entwicklung v6

Umgesetzt:

- Essenswünsche pro Haushalt
- Wunschdatum
- Realtime-Anzeige aller Wünsche
- Rezept an einen Wunsch hängen
- Wunsch annehmen und direkt in den Essensplan übernehmen
- Wunsch ablehnen
- Haushalts- und Startseite verlinken die neue Funktion
- RLS für Essenswünsche
- Realtime für Essenswünsche
- Security-definierte RPC für die Annahme inklusive Meal-Plan-Erstellung

Produktfluss:

Wunsch → Rezept → Annahme → Essensplan → Einkauf

Hinweis:
Die automatische Übernahme der Zutaten in die Einkaufsliste sollte im nächsten Block transaktional an die bestätigte Meal-Plan-Erstellung gekoppelt werden. Danach fehlen hauptsächlich UX-Polish, Tests und Deployment-Härtung.
