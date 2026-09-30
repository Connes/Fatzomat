# v11

Umgesetzt:

- Deep-Link Router für Einladungscodes vorbereitet
- InvitePage kann einen aus der URL gelesenen Code übernehmen
- Personenzahl eines geplanten Essens kann in der Wochenansicht geändert werden
- nach Änderung wird der Wochen-Einkauf neu konsolidiert
- `source_date` für Einkaufspositionen ergänzt
- SQL-RPC zum sicheren Ändern der Meal-Plan-Portionen
- erste Flutter-Unit-Tests für Invite-Parsing und deterministische Mengenskalierung

Neue Migration:
`supabase/migrations/202609090010_editable_week_plan.sql`

Vor einem Release:
- `flutter test`
- `flutter analyze`
- Supabase-Migrationen in einer Testinstanz ausführen
- RLS- und RPC-Security prüfen
- App Links / Universal Links auf iOS und Android konfigurieren
