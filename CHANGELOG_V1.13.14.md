# Schmackofatz v1.13.14+226

## Restaurant-Discovery Netzwerkfix

- `restaurant-discovery` nutzt den aktuell dokumentierten öffentlichen Overpass-Endpunkt `overpass.private.coffee` als ersten Anbieter und `overpass-api.de` als Fallback.
- Overpass-Anfragen senden einen eindeutigen `User-Agent` und akzeptieren JSON.
- Pro Overpass-Endpunkt gilt ein 9-Sekunden-Timeout, damit die Supabase Edge Function nicht unnötig lange blockiert.
- Die verständliche Fehlermeldung bleibt erhalten, wenn beide öffentlichen Datenquellen nicht erreichbar sind.
- Die 20-km-Suche, Cuisine-Filter, Lieferfilter und das Limit von 10 Ergebnissen bleiben unverändert.
