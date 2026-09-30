# together V88

## Auswahlseiten ohne sichtbaren Text

Die Seiten für **Wir kochen** und **Wir bestellen** wurden auf eine reine Auswahlansicht reduziert.

### Änderungen
- Keine Überschrift mehr auf den Seiten **Wir kochen** und **Wir bestellen**.
- Keine sichtbaren Textlabels innerhalb der Auswahlkarten auf diesen beiden Seiten.
- Die bestehende Darstellung von **Essen gehen** bleibt unverändert.
- Die Auswahlmöglichkeiten bleiben vollständig anklickbar.
- Die bestehenden semantischen Labels bleiben für Screenreader und Accessibility erhalten.
- Die Zurück-Navigation bleibt erhalten.
- Das bestehende Together-Hintergrundsystem bleibt erhalten.
- Koch- und Bestelllogik, Überraschungsoption und Decision-Request-Auflösung bleiben unverändert.

### Tests
- `test/v88_food_mode_selection_visual_test.dart` ergänzt.
- Die Tests prüfen, dass die sichtbaren Überschriften und Auswahltexte nicht gerendert werden und die semantischen Labels weiterhin vorhanden sind.
