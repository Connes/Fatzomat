# v1.13.15+227

## Restaurant-Discovery Stabilisierung

- Restaurantsuche verwendet mehrere öffentliche Overpass-Endpunkte parallel statt seriell.
- HTTP GET wird für Overpass verwendet, um Probleme mit form-encodierten POST-Anfragen durch vorgeschaltete Netzwerkinfrastruktur zu vermeiden.
- Suchabfragen liefern höchstens 150 passende OSM-Objekte zurück und werden anschließend lokal nach Entfernung sortiert.
- Overpass-Fehler werden protokolliert und als kontrollierter Fehler an die App zurückgegeben.
- Regressionstests behalten die aktuelle App-Version `1.13.15+227` bei.
