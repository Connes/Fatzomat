# v9

Umgesetzt:

- echte 7-Tage-Wochenansicht mit Tageskarten
- Wochenansicht zeigt alle geplanten Rezepte und Personenzahlen
- Einkauf kann direkt aus der Wochenansicht neu konsolidiert werden
- Haushalt bietet Wochenansicht zusätzlich zur bisherigen Tagesansicht
- eigener Einladungscode-Beitritts-Screen
- serverseitige sichere Invite-Code-Abfrage vorbereitet
- `source_label` für zukünftige Herkunftsanzeige der Einkaufspositionen

Neue Migration:
`supabase/migrations/202609090008_week_board_and_invite.sql`

Nächster Block:
- Einkauf nach Tag/Rezept/Herkunft filtern
- Wunsch-Detail mit Stimmen und Rezept
- Mehrheits-/Akzeptanzlogik
- Deep-Link Parsing
- SQL- und Flutter-Tests
- CI/Build und Produktions-Security
