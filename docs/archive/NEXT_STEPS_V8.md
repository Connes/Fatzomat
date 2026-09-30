# v8

Umgesetzt:

- Haushaltsmitglieder können Essenswünsche mit 👍 / 👎 bewerten.
- Stimmen werden pro Nutzer gespeichert und per Realtime aktualisiert.
- Annahme eines Wunsches bleibt mit Rezept, Personenzahl und Einkauf verbunden.
- Einkaufsliste kann für die nächsten 7 Tage aus dem bestätigten Essensplan neu konsolidiert werden.
- Automatisch erzeugte Rezeptpositionen werden von manuellen Artikeln getrennt.
- Start-/Wunsch-Flow enthält eine Aktion zum Neuaufbau der Wochen-Einkaufsliste.

Neue Migration:
`supabase/migrations/202609090007_votes_and_weekly_shopping.sql`

Nächster Block:

1. echte Wochenansicht mit Tageskarten
2. Wunsch-/Plan-Detailseite
3. Abstimmungsstatus und Mehrheitslogik
4. Einkaufsliste nach Wochentag/Rezept gruppierbar
5. Deep-Link-Einladungen
6. Tests für die SQL-RPCs und Skalierung
7. Produktionshärtung
