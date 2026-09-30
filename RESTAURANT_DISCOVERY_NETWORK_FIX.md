# Restaurant Discovery Netzwerkfehler

## Ergebnis

Der Fehler wurde auf der Authentifizierungsgrenze der Supabase Edge Function untersucht und behoben.

### Befund

Die App ruft `restaurant-discovery` über `supabase.functions.invoke()` auf. Die Funktion war live auf Version 2 mit `verify_jwt = true` konfiguriert. Supabase dokumentiert inzwischen, dass die eingebaute Legacy-JWT-Prüfung mit Projekten mit modernen/asymmetrischen Auth-Schlüsseln inkompatibel sein kann. Die aktuelle App verwendet die moderne Publishable-Key-Konfiguration und meldet sich zusätzlich anonym über Supabase Auth an.

Die bisherige Funktion selbst hatte keine eigene Authentifizierungsprüfung. Damit hing die Erreichbarkeit vollständig an der Plattform-Legacy-JWT-Prüfung. Ein solcher Auth-Fehler kann im Flutter-Aufrufer als allgemeiner Function-/Netzwerkfehler enden, obwohl die eigentliche externe Restaurantsuche noch gar nicht erreicht wurde.

Eine direkte externe HTTP-Reproduktion war aus der Ausführungsumgebung nicht möglich, weil dort DNS/Internetzugriff für `supabase.co` nicht verfügbar ist. Deshalb wird im Bericht nicht behauptet, dass ein realer Benutzer-Request hier lokal erfolgreich reproduziert wurde.

## Änderung

`restaurant-discovery` wurde auf Version 3 aktualisiert:

- `verify_jwt` auf `false` gesetzt, damit die veraltete Plattform-Legacy-JWT-Prüfung nicht mehr die moderne Authentifizierung blockiert.
- Im Function-Code wird jetzt jede Anfrage mit `createSupabaseContext(req, { auth: 'user' })` authentifiziert.
- Nur Anfragen mit einer gültigen User-Identität erreichen die Restaurantlogik.
- Damit bleibt die Funktion geschützt, ohne die alte Legacy-JWT-Prüfung als alleinige Authentifizierung zu verwenden.
- Die bestehende 20-km-Suche, Cuisine-Zuordnung, Overpass-Fallbacks, Deduplication und das Limit von 10 Ergebnissen bleiben erhalten.
- Keine Fake-Restaurants oder Fake-Koordinaten wurden eingeführt.

## Live-Verifikation

Supabase-Projekt: `oidxezjdwqktpxuypbfb`

Edge Function: `restaurant-discovery`

- Status: ACTIVE
- Live-Version: 3
- `verify_jwt`: false
- Custom Auth im Function-Code: `createSupabaseContext(..., { auth: 'user' })`
- Live-SHA: `9413d80b0eeefd698c668ab13abab13fa0585a30c64886c5adac7dc572eb85ae`

## Flutter

Der bestehende Aufruf über `supabase.functions.invoke('restaurant-discovery', ...)` bleibt erhalten. Der Request-Vertrag bleibt:

- `latitude`
- `longitude`
- `cuisine`
- `delivery_only`
- `limit` 1..10
- `radius_km` = 20

Die lokale Repository-Schicht prüft weiterhin Session, Radius, Response-Struktur und Fehlerdetails.

## Tests

In der verfügbaren Ausführungsumgebung stehen weder Flutter/Dart noch Deno zur Verfügung. Daher wurden `flutter analyze` und `flutter test` hier nicht ausgeführt und werden nicht als erfolgreich behauptet.

Die Live-Supabase-Funktion wurde dagegen nach dem Deployment mit `get_edge_function` verifiziert und meldet ACTIVE, Version 3 und die erwartete Auth-Konfiguration.
