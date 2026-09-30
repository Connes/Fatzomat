# Security für autonome Entwicklung

## Grundprinzip

Autonomie wird in Local/Test/Staging maximiert. Production bleibt geschützt.

## Verboten

- Production-Secrets im Repository
- Service-Role-Key im Flutter-Client
- RLS lockern, nur um Tests zu ermöglichen
- Produktionsdaten als Testdaten verwenden
- Sicherheitswarnungen ohne Begründung ignorieren

## Freigabepflichtig

- Production Migration
- Production Deployment
- Datenlöschung
- Auth-Konfigurationsänderungen
- Secret Rotation/Änderung
- Lockerung von RLS
- kostenpflichtige externe Dienste
- Store Releases
