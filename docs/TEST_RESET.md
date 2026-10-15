# Fatzomat Test Reset

**Destruktiver Reset ausschließlich für das dedizierte Entwicklungs-/Testprojekt. Niemals gegen Produktion ausführen.**

Das Skript `scripts/reset_test_data.sql` entfernt alle Supabase-Auth-Nutzer und die zugehörigen Anwendungsdaten. Es ist ein manuell auszuführendes Wartungsskript, kein App-Feature und keine Migration.

## Was gelöscht wird

- Alle Konten aus `auth.users` (Supabase Auth entfernt zugehörige Identitäten und Sitzungen über Foreign Keys).
- Profile und Verbindungen einschließlich Mitgliedschaften.
- Persönliche Tagespläne, Verlauf und Einkaufslisteneinträge.
- Geteilte Tages-/Rezeptpläne, Freigaben und Entscheidungsanfragen.
- Food-Präferenzen, Rezept-Saves und Rezeptvorschläge.
- Push-Geräte, Benachrichtigungen und Rezeptlöschanfragen.
- Alle Rezepte mit `created_by IS NOT NULL` sowie die dazugehörigen Zutaten, die über Foreign Keys abhängen.

## Was erhalten bleibt

- Globale/Seed-Rezepte mit `created_by IS NULL`.
- Der Food-Stammdatenbestand und sonstige globale App-Stammdaten.
- Der Storage-Bucket und alle Storage-Objekte. Supabase blockiert direkte SQL-Löschungen aus `storage.objects`; das SQL-Skript löscht daher bewusst keine Bilddateien.

## Voraussetzungen und Ausführung

1. Vorher sicherstellen, dass die verwendete Datenbank-URL zum dedizierten Testprojekt gehört. Nicht aus einer produktiven Umgebung starten.
2. Vorher einen Backup-/Snapshot erstellen, falls Daten wiederherstellbar bleiben müssen.
3. Das Skript mit der expliziten Bestätigung ausführen:

   ```sh
   psql "$TEST_DATABASE_URL" \
     -v TEST_RESET_CONFIRM=FATZOMAT_TEST_RESET \
     -f scripts/reset_test_data.sql
   ```

4. Die abschließende Ergebniszeile prüfen. Alle Zähler für Nutzer- und nutzerbezogene Daten müssen `0` sein. `user_recipe_image_objects_pending_storage_api_cleanup` zählt noch vorhandene Bilder, deren Pfad zu einem vor dem Reset nutzererstellten Rezept gehört.
5. Diese gezählten Bilder bei Bedarf anschließend über die Supabase Storage API oder das Supabase Dashboard löschen. **Nicht** direkt aus `storage.objects` löschen. Die Rezept-IDs für diese Zuordnung werden nur in einer temporären Tabelle der laufenden SQL-Sitzung gehalten; daher die Ergebnisprüfung in derselben `psql`-Sitzung durchführen.
6. Bei SQL-Fehlern nicht davon ausgehen, dass der Reset abgeschlossen ist. Da die Datenbankoperation in einer Transaktion läuft, werden Datenbankänderungen bei einem Fehler vor `COMMIT` zurückgerollt.

## Sicherheitsgrenzen

- Das Skript löscht **nicht** den gesamten Storage-Bucket und entfernt keine Storage-Objekte per SQL.
- Es löscht globale Food-/Seed-Daten nicht und setzt deren Sollbestand nicht neu auf.
- Vor dem Einsatz auf einer abweichenden Schema-Version müssen neue Tabellen und Foreign Keys geprüft werden. Das Skript ist auf die derzeit im Repository dokumentierte Supabase-Struktur ausgelegt.
- Die Bestätigung schützt vor versehentlichem Start, ersetzt aber nicht die Prüfung des Zielprojekts.
