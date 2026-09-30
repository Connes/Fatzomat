# Schmackofatz V1.6.7

## Diagnose und Release-Stabilität

- Die Diagnose-Seite zeigt jetzt zusätzlich den Status der aktuellen Supabase-Sitzung.
- Eine explizite Verbindungsprüfung kann Supabase über die bestehende App-Session testen.
- Falls keine Session vorhanden ist, versucht die Diagnose den vorgesehenen anonymen Login erneut.
- Erfolgs- und Fehlerstatus der Prüfung werden direkt auf der Diagnose-Seite angezeigt.
- Es werden weiterhin keine Tokens, Secrets oder geheimen Schlüssel dargestellt.
- Veraltete Hinweise auf eine lokale OpenAI-Konfiguration wurden aus der Diagnose entfernt.

## Release

- Version: `1.6.7+167`
- Private Android-Version, weiterhin ohne OpenAI-API und ohne Store-Veröffentlichungsanforderungen.
