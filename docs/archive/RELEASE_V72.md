# together V72

## Build-Stabilisierung

Behebt einen lokalen Kotlin-Daemon-RMI/JRMP-Timeout beim `flutter run` auf manchen Java/Gradle-Kombinationen.

Das Setup setzt nach der automatischen Flutter-Plattformerzeugung:

`kotlin.compiler.execution.strategy=in-process`

Damit wird die Kotlin-Kompilierung nicht mehr über den separaten Kotlin-Daemon abgewickelt. Die Java-Warnung zu `System::load` kann weiterhin erscheinen und ist davon unabhängig.
