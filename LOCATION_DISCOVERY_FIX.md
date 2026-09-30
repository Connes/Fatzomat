# Standortfehler bei Restaurant-/Liefer-Suche

## Befund

Der Fehler im Screenshot entsteht vor der Supabase-Edge-Function und vor der Overpass-Suche.

Der Flutter-Pfad in `DiscoveryPage._search()` ruft zuerst `LocationService.currentLocation()` auf. Erst nach erfolgreicher Standortbestimmung wird `restaurant-discovery` aufgerufen.

`DeviceLocationService` hat einen 15-Sekunden-Timeout. Die Android-Implementierung in `MainActivity.kt` verwendete zuvor ausschließlich `LocationManager.requestLocationUpdates()` und wartete damit auf einen neuen Standort-Fix. Ein bereits vorhandener Android-Standort wurde nicht über `getLastKnownLocation()` verwendet. Zusätzlich wurde bei aktivem GPS ausschließlich der GPS-Provider gewählt, obwohl der Netzwerk-Provider möglicherweise schneller einen Fix liefern konnte.

Dadurch konnte die App nach 15 Sekunden mit
`Der aktuelle Standort konnte nicht rechtzeitig ermittelt werden.`
abbrechen. Die Anzahl der Restaurant-Ergebnisse (maximal 10) wurde zu diesem Zeitpunkt noch gar nicht verarbeitet.

## Änderung

Die Android-Standortbeschaffung wurde angepasst:

1. vorhandene OS-Standorte von GPS und Netzwerk werden geprüft;
2. ein höchstens 15 Minuten alter Standort wird direkt verwendet;
3. wenn kein geeigneter letzter Standort vorhanden ist, werden GPS und Netzwerk parallel für einen neuen Fix angefragt;
4. der erste gültige Standort beendet die Anfrage;
5. bei deaktivierten Providern bleibt die bisherige verständliche Fehlermeldung erhalten.

Es werden keine Standortdaten in der App-Datenbank gespeichert.

## Unverändert

- Restaurantsuche maximal 20 km
- maximal 10 Ergebnisse
- echte OpenStreetMap/Overpass-Daten
- bestehende Personal-First-Architektur
- Supabase-Authentifizierung der Restaurant-Function
- keine Fake-GPS-Koordinaten

## Verifikation

Die Codeänderung wurde statisch geprüft. In der Ausführungsumgebung dieses Agents steht Flutter/Dart/Android SDK nicht zur Verfügung, daher wurden `flutter analyze` und `flutter test` nicht als erfolgreich ausgegeben.

Die live deployte Supabase-Function `restaurant-discovery` bleibt aktiv. Der Screenshot zeigt jedoch einen Fehler vor dem Function-Aufruf, daher war die Android-Location-Schicht der relevante Fehlerpfad.
