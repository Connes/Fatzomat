# V1.4 Cleanup Round

## Bereinigt

- `start_setup.sh` entfernt. `setup.sh` ist der einzige offizielle Einstiegspunkt.
- `scripts/bootstrap.sh` erzeugt oder verändert keine IDE-Konfigurationen mehr.
- `scripts/bootstrap.sh` verändert keine Android-/iOS-Dateien mehr.
- Lokales Release-Gate an die CI angeglichen und um den Android-Release-Build ergänzt.
- `.gitignore` dedupliziert.
- Repository-, Architektur- und Release-Prüfungen im lokalen Gate zusammengeführt.

## Bewusst nicht automatisch erzeugt

`pubspec.lock` sowie Android-/iOS-Plattformdateien müssen aus der tatsächlichen Flutter-Entwicklungsumgebung stammen und versioniert werden. Das Cleanup erzeugt keine künstlichen Lock- oder Plattformdateien.
