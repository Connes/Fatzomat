# together V1.2

V1.2 konsolidiert Wartbarkeit und Offline-Verhalten nach dem V1.0/V1.1-Hardening.

- Tests nach Feature/Core/Regression strukturiert.
- Leichter Controller-Layer für asynchronen Feature-State eingeführt.
- Heute-Ansicht nutzt Cache-Fallback und reagiert nach Reconnect erneut.
- Netzwerkstatus wird global sichtbar gemacht.
- Nicht-sensitive Offline-Caches für Foods und Today eingeführt.
- Direkte Dependencies auf exakte Versionen gepinnt.
- Dependency-Review-Skript ergänzt.
- Food-Modell um strukturierte Taxonomie erweitert: Aliase, Ernährungstyp, Allergene, Protein-Typ.
- Supabase-Food-Taxonomie migriert und verifiziert: 125 Datensätze vollständig klassifiziert.
- KI-Rezeptfunktion auf strukturierte Food-Taxonomie umgestellt.
- Food-ID-Validierung an die tatsächlichen Text-IDs der Datenbank angepasst.

## Release gate

```bash
./scripts/verify_release.sh
./scripts/check_dependencies.sh
```

`shared_preferences` enthält ausschließlich nicht-sensitive Cache-Daten. Authentifizierung und Berechtigungen bleiben serverseitig.
