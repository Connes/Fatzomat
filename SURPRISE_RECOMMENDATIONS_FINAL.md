# Schmackofatz – Surprise Recommendations

## Umsetzung

„Überrasch mich“ erzeugt jetzt konkrete persönliche Vorschläge.

- **Wir kochen:** bis zu 3 unterschiedliche persönliche Rezepte.
- **Wir gehen essen:** bis zu 10 echte Live-Restauranttreffer im bestehenden 20-km-Radius.
- **Wir bestellen:** bis zu 10 echte Live-Liefer-/Bestelltreffer im bestehenden 20-km-Radius.
- Ein konkreter Vorschlag wird erst nach Auswahl als persönlicher TodayPlan gespeichert.
- Restaurant-/Lieferdaten werden nicht als persönliche Daten persistiert.
- Connection ist für die persönliche Überraschung nicht erforderlich.
- „Entscheidung ändern“ bleibt entfernt; die bestehende Funktion „Entscheidung entfernen“ bleibt erhalten.

## Architektur

Neue zentrale Service-Schicht:

`SurpriseRecommendationService`

Sie verwendet die bestehende `PersonalizedDecisionService`, die vorhandene `RestaurantDiscoveryRepository`-/Location-Schicht und die vorhandenen Rezeptdaten. Es wurde keine zweite Restaurant-Sucharchitektur eingeführt.

Die Restaurantdetailansicht wurde aus `food_mode_page.dart` in `restaurant_detail_page.dart` ausgelagert, damit die neue Surprise-Seite die Detailansicht ohne zirkuläre Bibliotheksabhängigkeit wiederverwenden kann.

## Supabase

Die bestehende Edge Function `restaurant-discovery` wurde auf Version 2 aktualisiert. Sie akzeptiert für die Surprise-Suche auch eine leere Cuisine und sucht dann ohne Cuisine-Filter innerhalb des bestehenden 20-km-Radius. JWT-Prüfung bleibt aktiviert.

## Tests

Ein neuer Regressionstest `test/regression/surprise_recommendation_test.dart` deckt ab:

- 3 unterschiedliche Rezeptvorschläge
- Restaurant-Suche mit 20 km und maximal 10 Ergebnissen
- Delivery-Suche mit maximal 10 Ergebnissen
- Standortweitergabe
- Delivery-Flag

Die lokale Ausführungsumgebung dieses Audits enthält kein Flutter/Dart, daher konnte `flutter analyze`/`flutter test` hier nicht erneut ausgeführt werden. Die Quellen wurden statisch auf ausgeglichene Klammer-/Parenthesenstruktur und zentrale API-Aufrufe geprüft.
