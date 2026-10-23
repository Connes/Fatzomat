# Typografie- und Textfarben-Audit

**Repository:** `Connes/Fatzomat`  
**Prüfgegenstand:** Flutter/Dart-Oberfläche  
**Stand:** 2026-10-23  
**Ziel:** Prüfen, ob Schriftfamilie, Größenhierarchie, Schriftschnitte und Textfarben konsistent über die App verwendet werden.

## Kurzfazit

Die App hat bereits ein brauchbares zentrales Designsystem in `lib/core/app_design.dart`. Eine vollständig konsequente Anwendung über alle Screens ist aber nicht belegt und anhand der geprüften Screens auch nicht gegeben. Insbesondere werden Schriftgrößen und Schriftschnitte an einzelnen Stellen direkt gesetzt. Das erzeugt lokale Abweichungen von der zentralen Typografie.

**Bewertung:** zentrale Grundlage vorhanden; Durchsetzung im gesamten UI uneinheitlich; Harmonisierung empfohlen.

## Was zentral definiert ist

In `lib/core/app_design.dart` finden sich unter anderem:

- Schriftfamilie: **Inter**
- App-Bar-Titel: **22 px**, fett, Textfarbe
- TextTheme-Größen: Display 36/32/28 px; Headline 26/23/20 px; Title 18/16/14 px; Body 16/14/12 px; Label 14/12/11 px
- Textfarben: `AppDesign.text` (#202923), `AppDesign.secondaryText` (#68736D), `AppDesign.mutedText` (#8A938E)
- Markenfarbe Gold: `AppDesign.iconGold` (#D4AF37)
- Zentrale Hilfskomponente `SectionHeader`, die Theme-Stile verwendet

Das ist eine sinnvolle Basis. Die vielen TextTheme-Stufen sind allerdings nur dann hilfreich, wenn Screens die passenden Rollen auch konsequent verwenden.

## Geprüfte Stellen und konkrete Beobachtungen

Die folgenden Dateien wurden auf explizite Textstile, Schriftgrößen und Farben geprüft:

| Datei | Beobachtung |
|---|---|
| `lib/core/app_design.dart` | Zentrale Typografie und Textfarben sind definiert. Gleichzeitig gibt es komponentenspezifische Overrides, etwa App-Bar-, Dialog-, Button- und Chip-Stile. |
| `lib/features/shared/today_page.dart` | Mehrere lokale Größen, darunter 12, 14, 17 und 18 px; außerdem ein lokaler 13-px-Override auf `bodyMedium`. |
| `lib/features/recipes/add_recipe_page.dart` | Lokale Größen 14, 15, 16, 17, 19 und 22 px sowie mehrere manuell gesetzte Schriftschnitte. Die 22-px-Stelle setzt Inter explizit erneut. |
| `lib/features/recipes/saved_recipes_page.dart` | Teilweise Nutzung direkter Textstile bzw. einzelner Farb-Overrides statt konsequenter Theme-Rollen. |
| `lib/features/shared/multi_day_shopping_list_page.dart` | Überwiegend direkte Textfarben; mehrere eigene TextStyle-Blöcke. |
| `lib/features/recipes/recipe_detail_page.dart` | Abschnittstitel wie „Zutaten“ und „Zubereitung“ setzen Gewicht direkt, statt eine klar benannte TextTheme-Rolle zu verwenden. |
| `lib/features/settings/restaurant_favorites_page.dart` | Ein 42-px-Herz als dekoratives Empty-State-Element; das ist eine legitime Sondergröße, kein gewöhnlicher Text. Andere Texte setzen Farben direkt. |
| `lib/features/shared/surprise_mode_roulette_page.dart` | Mehrere lokale TextStyle-Blöcke und ein expliziter 13-px-Stil; wegen des individuellen Roulette-Layouts teilweise nachvollziehbar, sollte aber dokumentierte Ausnahmen verwenden. |

### Wichtige Einschränkung des Prüfumfangs

Der Repository-Baum enthält 86 Dart-Dateien unter `lib/`. Die Prüfung hat den gesamten Dateibaum erfasst und die zentralen Design- sowie mehrere große und repräsentative UI-Dateien gezielt auf Quelltext-Ebene untersucht. **Nicht jede einzelne Textstelle in allen 86 Dateien wurde manuell geprüft und visuell auf einem Gerät verglichen.** Dieses Dokument ist daher ein belastbarer Architektur- und Stichproben-Audit, aber kein abgeschlossener pixelgenauer Screen-by-Screen-Abnahmetest. Es werden keine ungeprüften Trefferzahlen als vollständiges Inventar ausgegeben.

## Empfohlene verbindliche Typografie

Diese Zuordnung sollte als Standard für neue und überarbeitete Screens gelten:

| Rolle | Stil | Farbe |
|---|---|---|
| Seitentitel in App-Bar | 22 px, w700 | `AppDesign.text` |
| Große Seitenüberschrift im Inhalt | `headlineSmall` (20 px) oder bei bewusstem Hero `headlineMedium` (23 px) | `AppDesign.text` |
| Zwischenüberschrift / Abschnitt | `titleLarge` (18 px, w700) | `AppDesign.text` |
| Kartenüberschrift | `titleMedium` (16 px, w600) | `AppDesign.text` |
| Fließtext | `bodyLarge` (16 px) | `AppDesign.text` |
| Sekundärtext / erklärender Text | `bodyMedium` (14 px) | `AppDesign.secondaryText` |
| Hinweis / Metadaten | `bodySmall` (12 px) | `AppDesign.mutedText` |
| Formulareingabe-Label / kompakte Aktion | `labelLarge` (14 px, w600) | `AppDesign.text` |
| Kleine Labels / Navigation | `labelMedium` (12 px) bzw. `labelSmall` (11 px) | sekundäre Textfarbe |
| Dekorative Zahlen, Emojis, Ergebniswerte | Sonderstil nur bei Bedarf | ausreichender Kontrast |

Nicht jede Überschrift muss dieselbe Pixelgröße haben: **dieselbe semantische Rolle** muss denselben Stil nutzen. Große Hero-Titel, Zahlenanzeigen, Emojis, Timer und markante Ergebniswerte sind begründete Ausnahmen.

## Farbregeln

1. Primärer Inhaltstext: `AppDesign.text`.
2. Erklärungen und sekundäre Information: `AppDesign.secondaryText`.
3. Platzhalter, Zeitstempel und zurückhaltende Metadaten: `AppDesign.mutedText`.
4. Gold (`AppDesign.iconGold`) ist eine Akzentfarbe für Icons bzw. gezielte Hervorhebungen, nicht die Standardfarbe für längere Texte.
5. Fehler, Warnungen und Erfolg verwenden die semantischen Tokens aus `AppDesign`.
6. `Colors.black`, `Colors.white` oder beliebige Hex-Farben nur dann direkt einsetzen, wenn ein lokaler Kontrast- oder Overlay-Kontext es erfordert und der Grund erkennbar ist.
7. Farbe darf Bedeutung nicht allein vermitteln; Kontrast und Lesbarkeit müssen erhalten bleiben.

## Befunde nach Priorität

### P1 – Theme als Standard durchsetzen

- Direkte `fontSize`-Angaben bei normalem UI-Text schrittweise durch `Theme.of(context).textTheme.*` ersetzen.
- Keine neuen beliebigen Größen wie 13, 15, 17 oder 19 px für Standardtext einführen, wenn keine klare Rolle dahintersteht.
- Wenn ein bestehender Stil leicht abweicht, zunächst klären, ob die Abweichung eine bewusste UI-Rolle oder historisch gewachsen ist.

### P1 – Überschriftenrollen vereinheitlichen

- Seitentitel, Abschnittstitel und Kartenüberschriften auf die oben definierte Hierarchie abbilden.
- Abschnittstitel nicht nur über `fontWeight` formatieren, sondern eine TextTheme-Rolle nutzen.
- Einheitliche Rollen in Dialogen und Formularen ebenfalls beachten; dort können komponentenspezifische Vorgaben sinnvoll sein.

### P2 – Farben zentralisieren

- Häufige direkte Textfarben durch die zentralen Tokens ersetzen.
- Ausnahmen für Text auf farbigen Flächen dokumentieren und kontrastgerecht halten.
- Nicht pauschal jede direkte Farbe entfernen: Weiß auf einem dunklen Button oder eine Fehlerfarbe kann korrekt sein.

### P2 – Designsystem vereinfachen und dokumentieren

- Die existierenden TextTheme-Stufen beibehalten, aber ihre semantische Verwendung verbindlich dokumentieren.
- `SectionHeader` als bevorzugte Lösung für wiederkehrende Abschnittsüberschriften einsetzen.
- Für häufige Sonderrollen nur dann eigene Konstanten/Hilfswidgets ergänzen, wenn mehrere Screens sie tatsächlich benötigen.

### P3 – Regression absichern

- Widget-Tests für die zentralen Design-Tokens und wiederverwendbaren Überschriften ergänzen.
- Eine Repository-Prüfung bzw. Lint-Regel erwägen, die neue direkte `fontSize`-Angaben in Feature-Screens sichtbar macht. Eine pauschale Sperre wäre zu streng, da dekorative Sondergrößen legitim sind.
- Screens mit langen Texten, Dialogen, Formularen und kleinen Displays visuell prüfen.

## Empfohlener Migrationsablauf

1. Zuerst zentrale Theme-Rollen und ihre Bedeutung festschreiben.
2. Gemeinsame Widgets und App-Bar-/Dialog-Konfiguration vereinheitlichen.
3. Screens in kleinen, fachlich zusammenhängenden Gruppen migrieren.
4. Nach jeder Gruppe `flutter analyze` und relevante Tests ausführen.
5. Visuell auf kleinen und großen Displays sowie bei vergrößerter Systemschrift kontrollieren.
6. Änderungen über Feature-Branch und Pull Request integrieren; Merge erst nach erfolgreichen erforderlichen Checks.

## Abnahmekriterien

- [ ] Normale Überschriften verwenden festgelegte TextTheme-Rollen.
- [ ] Fließtext verwendet standardmäßig `bodyLarge` oder eine begründete kleinere Rolle.
- [ ] Sekundärtext und Metadaten verwenden konsistente Rollen und Farben.
- [ ] Direkte Größen und Farben sind entweder entfernt oder als bewusste Ausnahme begründet.
- [ ] Dialoge, Formulare, Navigation und Empty States folgen denselben semantischen Regeln.
- [ ] `flutter analyze` und relevante Tests sind erfolgreich.
- [ ] Visuelle Prüfung bestätigt Lesbarkeit, Kontrast und konsistente Hierarchie.

## Fazit

Die App besitzt bereits zentrale Design-Tokens und eine definierte Schriftfamilie. Das Problem ist nicht das Fehlen eines Systems, sondern dessen uneinheitliche Nutzung in einzelnen Screens. Der sinnvollste nächste Schritt ist eine kontrollierte Migration auf die bestehenden Theme-Rollen, keine spontane globale Ersetzung aller Schriftgrößen. Diese Änderung ist bewusst noch nicht Teil dieses Audit-Dokuments.
