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
            .join('\n');

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
7. Die Datei muss ein gültiges JSON-Objekt enthalten. Keine Markdown-Codeblöcke, keine Einleitung und keine Erklärung innerhalb oder außerhalb der Datei.
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
14. Gib nach Möglichkeit ausschließlich die Datei zum Download aus. Wenn die Dateierstellung in deiner aktuellen Umgebung technisch nicht verfügbar ist, gib ersatzweise das vollständige rohe JSON ohne Markdown aus, damit ich es als together_recipe.json speichern kann.
15. Nachdem die Rezeptdatei erfolgreich erstellt wurde, bleiben die vollständigen Rezeptdaten in diesem Chat erhalten. Wenn ich danach schreibe „Erstelle jetzt anhand des gerade erzeugten Rezepts ein Bild des fertigen Gerichts.“, verwende genau dieses Rezept als Grundlage für die Bildgenerierung. Ich möchte das Rezept dafür nicht erneut übergeben müssen.
16. Die Bildgenerierung ist bewusst getrennt von der JSON-Datei. Füge kein Bild, keine Base64-Daten und keinen Bildpfad in die JSON ein.''';
  }

  static String buildPhotoImportPrompt() {
    return '''Lies das angehängte Foto eines Rezepts vollständig aus und erstelle daraus eine gültige together_recipe.json für die App Schmackofatz.

WICHTIG:
- Das angehängte Bild ist die einzige Quelle für die Rezeptdaten.
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
