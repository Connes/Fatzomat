# Migrationen

Historische Migrationen werden nicht gelöscht oder umgeschrieben.

Der aktuelle Repository-Stand enthält 63 lokale SQL-Migrationen. Die Live-Historie enthält aktuell 41 registrierte Migrationen. Die Differenz ist historisch bedingt und bereits in `docs/MIGRATION_DRIFT_RECONCILIATION.md` beschrieben.

## Zieltest

```text
leere Datenbank
-> alle lokalen Migrationen
-> Schema-/Catalog-Prüfung
-> RLS-/Policy-Prüfung
-> Realtime-Prüfung
-> supabase/tests/smoke.sql
```

Dieser vollständige Replay-Test ist in der aktuellen Umgebung noch nicht verifiziert, weil Supabase CLI und lokale PostgreSQL/Supabase Runtime fehlen.
