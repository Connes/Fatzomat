# together V84 Fix1

## Test-Stabilität

- HomePage initialisiert den Decision-Realtime-Channel nur, wenn Supabase bereits initialisiert ist.
- Nicht-initialisierte Supabase-Instanzen in Widget-Tests/Previews führen nicht mehr zu einem Mount-Crash.
- Keine Änderung an der produktiven Entscheidungslogik bei initialisiertem Supabase.

Version bleibt `0.1.0+84`.
