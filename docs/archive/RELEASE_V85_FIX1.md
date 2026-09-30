# V85 Fix1

## Testkorrektur

Der V85-Accessibility-Test erwartete die vier Home-Labels als direktes `label:`-Argument. Die Implementierung verwendet bewusst `semanticLabel` als Übergabe an `_HomeChoiceTile` und setzt das Semantics-Label dort korrekt auf `label: semanticLabel`.

Der Test wurde deshalb auf die tatsächliche Accessibility-Struktur angepasst. Die App-Implementierung wurde nicht abgeschwächt oder umgebaut.

## Version

`0.1.0+85` bleibt unverändert.
