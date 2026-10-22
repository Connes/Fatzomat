import '../../data/models/food.dart';

class TogetherChatGptPrompt {
  const TogetherChatGptPrompt._();

  static String build({
    required String mainChoice,
    required List<Food> selectedFoods,
  }) {
    final ingredientLines = selectedFoods.isEmpty
        ? 'Keine zusätzlichen Zutaten ausgewählt.'
        : selectedFoods
            .map((food) => '- ${food.name}')
            .join('\\n');

    return '''Erstelle für mich ein passendes Rezept und lege das Ergebnis als herunterladbare Datei ab.

DATEINAME: together_recipe.json

WICHTIG: Das Ergebnis muss als echte Datei „together_recipe.json“ bereitgestellt werden, damit ich diese Datei anschließend in der App Schmackofatz über „Rezeptdatei importieren“ auswählen kann. Verwende die Dateierstellung bzw. Download-Funktion von ChatGPT, falls verfügbar. Die Datei darf ausschließlich das unten definierte JSON enthalten.

Hauptauswahl / Rezeptbasis:
$mainChoice

Von mir ausgewählte Zutaten:
$ingredientLines

Regeln:
1. Die Hauptauswahl ist zwingende Grundlage des Rezepts. Bei „Huhn“, „Rind“, „Schwein“ oder „Fisch“ muss eine passende Zutat dieser Kategorie im Rezept enthalten sein. Bei „Vegetarisch“ darf das Rezept kein Fleisch und keinen Fisch enthalten.
2. Verwende alle von mir ausgewählten Zutaten als Bestandteil des Rezepts.
3. Markiere jede von mir ausgewählte Zutat mit "is_user_selected": true und "is_additional": false.
4. Du darfst sinnvolle zusätzliche Zutaten ergänzen, wenn sie für ein vollständiges Rezept nötig sind. Markiere diese mit "is_user_selected": false und "is_additional": true.
5. Verwende bei Zutaten, die als einzelne Stücke gezählt werden, KEINE Einheit. Schreibe z. B. "amount": 1, "unit": "" für eine Zwiebel, ein Ei, eine Karotte oder eine Kartoffel. Verwende niemals "Stück", "Stk." oder "Stk" als Einheit. Bei messbaren Mengen wie g, kg, ml, l, EL, TL oder Pck. soll die passende Einheit erhalten bleiben.
6. Erstelle ein realistisches Rezept für 2 Portionen mit Zubereitungs- und Kochzeit sowie einer Schwierigkeit.
7. Die Datei muss ein gültiges JSON-Objekt enthalten. Die JSON-Datei selbst enthält ausschließlich die Rezeptdaten, ohne Markdown-Codeblöcke, Einleitung oder Erklärung. Diese Einschränkung gilt nur für den Dateiinhalt, nicht für separate Chat-Ergebnisse wie das anschließend generierte Bild.
8. Verwende exakt dieses Format und diese Feldnamen:
{
  "format": "together_recipe",
  "version": 1,
  "recipe": {
    "title": "...",
    "description": "...",
    "servings": 2,
    "prep_time_minutes": 10,
    "cook_time_minutes": 20,
    "difficulty": "Einfach",
    "ingredients": [
      {
        "food_id": null,
        "name": "...",
        "amount": 200,
        "unit": "g",
        "section": "Teig",
        "is_user_selected": true,
        "is_additional": false
      }
    ],
    "steps": [
      "..."
    ]
  }
}
9. Setze "food_id" nur dann, wenn du eine passende ID sicher kennst. Sonst muss es null sein.
10. Mengen müssen als Zahlen oder null vorliegen, nicht als Text.
11. "servings", "prep_time_minutes" und "cook_time_minutes" müssen ganze Zahlen sein.
12. Bewahre bei Zutatenabschnitten die sichtbare Gruppierung. Jede Zutat erhält in „section“ den exakten bzw. sinngemäßen Abschnittsnamen; ohne Abschnitt ist „section“ null.
13. Prüfe vor dem Bereitstellen der Datei, dass das JSON syntaktisch gültig ist, mit { beginnt und mit } endet und dem together_recipe-Format Version 1 entspricht.
14. ERSTE PRIORITÄT: Erstelle das vollständige Rezept gemäß dem oben definierten Schema. Fülle insbesondere recipe.title, recipe.description, servings, prep_time_minutes, cook_time_minutes, difficulty, ingredients und steps sinnvoll aus. Lasse das Rezept nicht weg und ersetze es niemals durch ein Bild.
15. Erzeuge aus diesem vollständigen Rezept zuerst die Datei „together_recipe.json“ und stelle sie zum Download bereit. Prüfe, dass die Datei gültiges JSON im together_recipe-Format Version 1 enthält. Wenn die Dateierstellung in deiner aktuellen Umgebung technisch nicht verfügbar ist, gib ersatzweise das vollständige rohe JSON als Chat-Text ohne Markdown aus, damit ich es als together_recipe.json speichern kann. Auch in diesem Ersatzfall muss das vollständige Rezept ausgegeben werden.
16. ERST NACHDEM das vollständige Rezept erstellt und die Datei bereitgestellt (oder das rohe JSON ausgegeben) wurde, generiere AUTOMATISCH und direkt anschließend ein separates, fotorealistisches, appetitliches Bild des fertig zubereiteten Gerichts. Warte nicht auf eine weitere Aufforderung. Verwende exakt das gerade erstellte Rezept als Grundlage und bilde die beschriebenen Zutaten und Zubereitung möglichst realistisch ab. Präsentiere das Gericht wie auf einem hochwertigen professionellen Food-Foto mit natürlichem Licht und ansprechendem Anrichten.
17. Rezeptdatei und Bild sind zwei getrennte Ergebnisse: Die Rezeptdatei muss immer erstellt werden, das Bild kommt zusätzlich danach. Füge kein Bild, keine Base64-Daten und keinen Bildpfad in die JSON ein. Die JSON-Datei enthält ausschließlich die oben definierten Rezeptdaten. Die JSON-only-Regel gilt nur für den Dateiinhalt, nicht für die gesamte Chat-Antwort. Die Bildgenerierung darf die Rezeptausgabe weder ersetzen noch verhindern.''';
  }

  static String buildPhotoImportPrompt() {
    return '''Lies alle angehängten Fotos desselben Rezepts vollständig aus und erstelle daraus eine einzige gültige together_recipe.json für die App Schmackofatz.

WICHTIG:
- Verwende alle angehängten Bilder als zusammengehörige Seiten/Ausschnitte desselben Rezepts. Sie sind die einzige Quelle für die Rezeptdaten.
- Prüfe die Fotos gemeinsam, nicht isoliert. Sie können überlappende Textbereiche zeigen oder mitten in einer Zutatenliste bzw. einem Zubereitungsschritt aneinander anschließen.
- Erkenne Überlappungen anhand wiederholter Zeilen, Zutaten, Mengen, Abschnittsüberschriften oder Satzteile. Übernimm wiederholte Inhalte nur einmal. Erzeuge insbesondere keine doppelten Zutaten, wenn dieselbe Zeile auf zwei Fotos sichtbar ist.
- Führe abgeschnittene Zeilen und Sätze über mehrere Fotos hinweg zusammen, wenn der Zusammenhang eindeutig ist. Bewahre die Reihenfolge des Rezepts.
- Zähle eine Zutat nur einmal, sofern das Rezept sie nicht ausdrücklich an verschiedenen Stellen als getrennte Mengen aufführt. Wenn dieselbe Zutat tatsächlich in mehreren Abschnitten mit unterschiedlichen Mengen benötigt wird, erhalte diese getrennten Einträge und ihre Abschnittsnamen.
- Wenn sich Fotos widersprechen oder ein Bereich trotz aller Bilder unleserlich bleibt, rate nicht. Verwende null bzw. leere Textfelder gemäß Schema.
- Erfinde keine Zutaten, Mengen, Zeiten, Portionen oder Zubereitungsschritte.
- Wenn eine Angabe auf dem Foto nicht eindeutig lesbar ist, verwende null für die Menge oder eine leere Zeichenkette für Textfelder, sofern das Schema dies erlaubt.
- Erhalte die Reihenfolge der Zutaten und Zubereitungsschritte.
- Erkenne ausdrücklich Zutatenabschnitte bzw. Überschriften wie „Teig“, „Füllung“, „Belag“, „Creme“, „Sauce“, „Topping“ usw. und ordne jede Zutat dem auf dem Foto erkennbaren Abschnitt zu.
- Wenn keine Abschnittsüberschrift vorhanden ist, setze „section“ auf null.
- Erfinde keine Abschnittsnamen, wenn das Foto keinen solchen Abschnitt erkennen lässt.
- Übernimm den Rezeptnamen und die Beschreibung so genau wie möglich.
- Mengen müssen Zahlen oder null sein, niemals ausgeschriebener Text.
- food_id muss null sein, sofern keine sichere Schmackofatz-ID bekannt ist.
- Verwende is_user_selected=false und is_additional=false, sofern diese Information nicht ausdrücklich aus dem Foto hervorgeht.
- Verwende is_qualitative=true für qualitative Mengen wie „Prise“, wenn keine numerische Menge angegeben ist.
- Verwende für einzelne Stücke keine Einheit. "1 Stück Zwiebel" wird als amount=1 und unit="" ausgegeben. Verwende niemals "Stück", "Stk." oder "Stk" als Einheit.

Verwende exakt dieses JSON-Format:
{
  "format": "together_recipe",
  "version": 1,
  "recipe": {
    "title": "...",
    "description": "...",
    "servings": 2,
    "prep_time_minutes": 10,
    "cook_time_minutes": 20,
    "difficulty": "Einfach",
    "ingredients": [
      {
        "food_id": null,
        "name": "...",
        "amount": 200,
        "unit": "g",
        "section": "Teig",
        "is_user_selected": false,
        "is_additional": false,
        "is_qualitative": false
      }
    ],
    "steps": [
      "..."
    ]
  }
}

Zusätzliche Regeln:
1. Das Ergebnis muss syntaktisch gültiges JSON sein.
2. Keine Markdown-Codeblöcke.
3. Keine Einleitung und keine Erklärung außerhalb des JSON.
4. Die Datei soll „together_recipe.json“ heißen.
5. Prüfe vor der Ausgabe, dass das Ergebnis dem together_recipe-Format Version 1 entspricht.
6. Gib nur das JSON bzw. die erzeugte Datei zurück.''';
  }
}
