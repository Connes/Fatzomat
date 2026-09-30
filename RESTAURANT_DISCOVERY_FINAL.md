# Schmackofatz – Restaurant & Lieferdienst Discovery Abschlussbericht

## 1. Aktueller Zustand vor der Änderung

Die bestehende „Discovery“-Funktion öffnete lediglich externe Google-Maps-/Websuche-Links. Sie lieferte keine eigene Ergebnisliste, keine verifizierte 20-km-Filterung, keine echte Standortabfrage und keine strukturierte Detailansicht.

## 2. Architekturentscheidung

Die Funktion wurde in die bestehende Personal-First-Struktur integriert:

UI
→ DiscoveryPage
→ RestaurantDiscoveryRepository
→ Supabase Edge Function `restaurant-discovery`
→ OpenStreetMap/Overpass

Die externe Discovery wird nicht als persönliche Datenbanktabelle modelliert. Restaurantdaten werden live abgefragt und nicht dauerhaft in Supabase gespeichert.

Die persönliche Entscheidung bleibt davon getrennt und wird weiterhin über den persönlichen TodayPlan mit `dine_out` bzw. `order` gespeichert.

## 3. Standort

Es wurde keine zweite Flutter-Location-Bibliothek eingeführt.

Stattdessen nutzt Schmackofatz einen kleinen nativen MethodChannel:

`schmackofatz/location`

- Android: native `LocationManager`
- iOS: native `CLLocationManager`
- Berechtigungsprüfung und -anfrage
- deaktivierte Standortdienste werden als verständlicher Fehler zurückgegeben
- 15-Sekunden-Timeout im Flutter-Layer
- keine Standortdaten werden von dieser Funktion dauerhaft gespeichert

Android- und iOS-Berechtigungen wurden ergänzt.

## 4. „Wir gehen essen"

Implementiert:

- Küche wird aus der UI-Auswahl übernommen.
- aktueller Gerätestandort wird ermittelt.
- Suche ist fest auf 20 km begrenzt.
- maximal 10 Ergebnisse.
- Ergebnisse werden nach Entfernung sortiert.
- doppelte Einträge werden serverseitig entfernt.
- Entfernung wird per Haversine-Berechnung aus Benutzer- und Anbieterkoordinaten berechnet.
- Liste zeigt Name, Ort und Entfernung.
- Detailansicht zeigt Adresse, Entfernung, Telefon, Webseite und optional Öffnungszeiten.
- Telefon und Webseite sind nur vorhanden, wenn die externe Quelle entsprechende Daten liefert.

## 5. „Wir bestellen"

Implementiert:

- gleicher Standort-/Radiusablauf.
- ausgewählte Küche wird tatsächlich an die Suche übergeben.
- maximal 10 Ergebnisse.
- nur Restaurants/Fast-Food-Einträge mit expliziter OSM-Lieferkennzeichnung `delivery=yes/only` oder `delivery:website` werden berücksichtigt.
- reine Dine-in-/Takeaway-only-Einträge werden nicht künstlich als Lieferung dargestellt.
- Bestell-/Lieferlink wird nur aus `delivery:website` oder `website:orders` übernommen.
- Telefonnummer und Webseite werden nur aus real vorhandenen Tags übernommen.

Die Datenquelle kann nur Anbieter zurückgeben, die dort entsprechend gepflegt sind. Ein fehlendes OSM-Tag bedeutet daher nicht, dass ein Restaurant tatsächlich niemals liefert, sondern nur, dass Schmackofatz es auf dieser Datenbasis nicht als Lieferanbieter ausgibt.

## 6. Externe Datenquelle

Verwendet wird OpenStreetMap/Overpass.

Overpass unterstützt Radiusabfragen über `around`; OSM dokumentiert `cuisine` für Restaurants/Fast-Food sowie `delivery`, `website`, `phone` und verwandte Kontakt-/Bestell-Tags. Die externe Suche läuft serverseitig in der Supabase Edge Function.

## 7. Supabase

Keine neue Tabelle und keine neue RLS-Struktur war für Restaurantdaten erforderlich.

Neu deployed wurde:

- Edge Function: `restaurant-discovery`
- Status: ACTIVE
- Version: 1
- JWT-Prüfung: aktiviert
- externe Restaurantdaten werden nicht persistiert

Es wurden keine SECURITY-DEFINER-Funktionen für diese Funktion eingeführt.

## 8. Personal-First / Offline

`dine_out` und `order` bleiben persönliche Entscheidungen.

Bei fehlender Netzwerkverbindung wird die persönliche Auswahl lokal zwischengespeichert und kann im persönlichen TodayPlan weiter angezeigt werden. Eine ausstehende persönliche Entscheidung wird bei späterer Verbindung zur Synchronisierung vorgemerkt.

Die externe Restaurant-/Lieferdienstsuche selbst benötigt Netzwerkzugriff.

## 9. Geänderte Dateien

Flutter:

- `lib/features/food_modes/food_mode_page.dart`
- `lib/core/services/location_service.dart`
- `lib/data/models/restaurant_discovery.dart`
- `lib/data/repositories/restaurant_discovery_repository.dart`
- `lib/data/cache/offline_cache.dart`
- `lib/data/repositories/personal_today_repository.dart`

Native Plattformen:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/food_app_mvp/MainActivity.kt`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/SceneDelegate.swift`

Supabase:

- `supabase/functions/restaurant-discovery/index.ts`
- `supabase/functions/restaurant-discovery/deno.json`

Tests:

- `test/regression/discovery_v110_test.dart`
- `test/regression/discovery_filter_test.dart`
- `test/regression/restaurant_discovery_test.dart`

## 10. Tests

Tatsächlich ausgeführt:

- statischer Architekturcheck: erfolgreich
- Repository-Hygienecheck: erfolgreich
- Dependency-/Projektstrukturcheck: erfolgreich
- Supabase Edge Function Deployment: erfolgreich
- Supabase Edge Function anschließend über MCP wieder ausgelesen: erfolgreich
- Security Advisor nach Deployment: geprüft

NICHT AUSGEFÜHRT:

- `flutter analyze`
- `flutter test`
- Android Release Build
- iOS Build
- echter mobiler GPS-Test
- echter authentifizierter Edge-Function-Integrationstest gegen Overpass

Grund: Flutter/Dart ist in der Arbeitsumgebung nicht installiert und der Container konnte keine externe DNS-/Netzwerkverbindung zu Overpass aufbauen.

Die Edge Function wurde dennoch real in Supabase deployed und serverseitig von Supabase akzeptiert.

## 11. Kritischer Selbst-Audit

Geprüft:

- aktueller Standort statt statischer Koordinaten
- fester 20-km-Radius
- maximal 10 Treffer
- serverseitige Duplikatentfernung
- Küchenfilter
- getrennte `dine_out`-/`order`-Logik
- Lieferfilter für Bestellung
- echte Telefonnummern/Webseiten/Bestelllinks aus der Datenquelle
- keine Speicherung externer Restaurantdaten in Supabase
- keine Shared-Plan-Erzeugung durch Discovery
- keine zweite Location-Bibliothek
- verständliche Fehler-/Empty-States
- externe Links werden validiert

## 12. Bekannte Risiken

1. OpenStreetMap-Daten sind nicht vollständig. Insbesondere Lieferkennzeichnungen können fehlen.
2. Die externe Overpass-Infrastruktur kann zeitweise ausgelastet oder nicht erreichbar sein.
3. Der echte Flutter-/Gerätetest konnte in dieser Umgebung nicht ausgeführt werden.
4. Der bestehende Supabase Security Advisor meldet weiterhin ältere SECURITY-DEFINER-RPCs und bereits bekannte Anonymous-Policy-Warnungen. Diese wurden in diesem Auftrag nicht pauschal verändert, weil sie nicht Teil der Restaurant-Discovery waren und ein ungezieltes Security-Refactoring die bestehende Collaboration-Architektur gefährden könnte.

## 13. Finaler Stand

Projektversion bleibt `1.12.0+211`, damit bestehende Release-/Regressionstests mit der bisherigen Versionsgrenze nicht unnötig gebrochen werden.

Der finale ZIP-Hash wird nach Erstellung dieses Berichts separat berechnet.
