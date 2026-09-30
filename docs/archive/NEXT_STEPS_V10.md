# v10

Umgesetzt:

- Detailansicht für Essenswünsche
- Abstimmung grafisch als Zustimmungsbalken
- klare Handlung „Annehmen & einkaufen“
- Einkaufsliste kann nach Rezept-/Quellenlabel gefiltert werden
- Herkunft automatisch erzeugter Artikel wird in der Liste angezeigt
- Deep-Link-Parser für Einladungscodes vorbereitet
- serverseitige Vote-Zusammenfassung ergänzt

Neue Migration:
`supabase/migrations/202609090009_request_detail.sql`

Nächster Block:
- echtes Deep-Link Handling auf App-Start
- Mehrheits-/Quorum-Regeln konfigurierbar machen
- Wochenplan editierbar per Drag & Drop
- Einkaufsartikel mit Herkunft und Tagesdatum
- automatisierte Tests
- CI/CD und Release-Konfiguration
