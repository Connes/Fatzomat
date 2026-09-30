# Release v27

## `flutter analyze` bereinigt

Die sieben bisherigen Lint-Hinweise wurden behoben:

- `use_super_parameters`
- `curly_braces_in_flow_control_structures`
- `use_build_context_synchronously`

Bei asynchronen UI-Aktionen werden BuildContexts jetzt mit `context.mounted` abgesichert, wo der Kontext aus einer Build-Methode stammt.

Erwartetes Ergebnis:

```text
No issues found!
```

Das vorhandene Setup richtet weiterhin Android, Dart SDK und die Android-Studio-Run-Konfiguration automatisch ein.
