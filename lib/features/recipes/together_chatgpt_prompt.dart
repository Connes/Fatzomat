import '../../data/models/food.dart';

class TogetherChatGptPrompt {
  const TogetherChatGptPrompt._();

  static String build({
    required String mainChoice,
    required List<Food> selectedFoods,
    List<Food> likedFoods = const <Food>[],
    List<Food> dislikedFoods = const <Food>[],
    bool onlySelectedFoods = false,
  }) {
    final ingredientLines = selectedFoods.isEmpty
        ? 'Keine zusätzlichen Zutaten ausgewählt.'
        : selectedFoods
            .map((food) => '- ${food.name}')
            .join('\\n');

    final likedLines = likedFoods.isEmpty
        ? 'Keine gespeicherten Lieblingslebensmittel.'
        : likedFoods.map((food) => '- ${food.name}').join('\\n');
    // An explicit ingredient choice is intentional and takes precedence over
    // the saved dislike preference for this recipe.
    final selectedIds = selectedFoods.map((food) => food.id).toSet();
    final excludedDislikedFoods = dislikedFoods
        .where((food) => !selectedIds.contains(food.id))
        .toList(growable: false);
    final dislikedLines = excludedDislikedFoods.isEmpty
        ? 'Keine weiteren ausgeschlossenen Lebensmittel.'
        : excludedDislikedFoods.map((food) => '- ${food.name}${food.aliases.isEmpty ? '' : ' (auch bekannt als: ${food.aliases.join(', ')})'}').join('\\n');

    final ingredientConstraint = onlySelectedFoods
        ? '''STRIKTE ZUTATENBESCHRÄNKUNG AKTIV:
- Verwende ausschließlich die Hauptauswahl und die ausdrücklich ausgewählten Lebensmittel als Lebensmittelzutaten.
- Füge keine weiteren Lebensmittel hinzu, auch dann nicht, wenn sie üblicherweise zum Gericht passen.
- AUSNAHME: Gewürze und Kräuter dürfen zusätzlich verwendet werden, ebenso Wasser und notwendige Kochgrundlagen wie Salz und Pfeffer.
- Diese Regel gilt für alle drei Vorschläge und das spätere vollständige Rezept. Wenn die Auswahl zu keinem sinnvollen Gericht passt, schlage nur Gerichte vor, die mit genau diesen Lebensmitteln machbar sind; verschweige keine zusätzlichen Lebensmittel in Saucen, Marinaden oder Beilagen.
'''
        : '''ERGÄNZUNGEN ERLAUBT:
- Du darfst neben der Hauptauswahl und den ausgewählten Zutaten weitere Lebensmittel integrieren, wenn sie kulinarisch sinnvoll sind und das Rezept verbessern.
- Verwende keine ausgeschlossenen Lebensmittel und beachte alle übrigen Regeln.
''';

    return '''Arbeite in zwei klar getrennten Phasen. In deiner ERSTEN Antwort machst du ausschließlich drei Rezeptvorschläge. Erstelle noch KEIN vollständiges Rezept und KEINE Datei, bis ich einen Vorschlag ausgewählt habe.

$ingredientConstraint
PHASE 1 – DREI VORSCHLÄGE:
- Schlage genau drei deutlich unterschiedliche Gerichte vor, die zur Hauptauswahl, meinen ausgewählten Zutaten und meinen Vorlieben passen.
- Berücksichtige in jedem Vorschlag alle ausdrücklich ausgewählten Zutaten, soweit kulinarisch sinnvoll, und verwende keine ausgeschlossenen Lebensmittel.
- Gib pro Vorschlag einen kurzen Rezeptnamen mit höchstens 40 Zeichen, eine knappe Beschreibung, die wichtigsten Zutaten und eine ungefähre Zubereitungszeit an. Begrenze den Rezeptnamen auf maximal 40 Zeichen; kürze ihn bei Bedarf sinnvoll. Diese Grenze gilt sowohl für die drei Vorschläge als auch für recipe.title in der späteren JSON-Datei.
- Nummeriere die Vorschläge exakt mit 1, 2 und 3.
- Frage am Ende kurz, welchen Vorschlag ich wählen möchte.
- In dieser Phase keine JSON-Ausgabe, kein vollständiges Rezept, keine Datei und keine Bildgenerierung.

PHASE 2 – NACH MEINER AUSWAHL:
- Sobald ich 1, 2, 3 oder den Namen eines Vorschlags auswähle, erstelle nur für dieses Gericht das vollständige Rezept.
- Erstelle zusätzlich eine echte Datei „together_recipe.json“ im unten definierten Format Version 1, damit ich sie in der App Schmackofatz über „Rezeptdatei importieren“ auswählen kann.
- Stelle die JSON-Datei zum Download bereit. Falls Dateierstellung nicht verfügbar ist, gib das vollständige gültige JSON als Chat-Antwort aus.
- Generiere in keiner Phase ein Bild und starte keine Bildgenerierung.

DATEINAME: together_recipe.json

Hauptauswahl / Rezeptbasis:
$mainChoice

Von mir ausgewählte Zutaten:
$ingredientLines

Lebensmittel, die ich mag (bevorzugen, wenn es sinnvoll zum Rezept passt):
$likedLines

Lebensmittel, die ich NICHT mag (streng ausschließen, außer ich habe sie oben ausdrücklich ausgewählt; auch in Saucen, Gewürzmischungen, Marinaden und optionalen Zutaten):
$dislikedLines

Regeln:
1. Die Hauptauswahl ist zwingende Grundlage des Rezepts. Bei „Huhn“, „Rind“, „Schwein“ oder „Fisch“ muss eine passende Zutat dieser Kategorie im Rezept enthalten sein. Bei „Vegetarisch“ darf das Rezept kein Fleisch und keinen Fisch enthalten.
2. Verwende alle von mir ausgewählten Zutaten als Bestandteil des Rezepts. Eine ausdrücklich ausgewählte Zutat hat für dieses Rezept Vorrang vor einer gespeicherten „Mag ich nicht“-Präferenz; verwende sie trotzdem und warne nicht davor.
3. Markiere jede von mir ausgewählte Zutat mit "is_user_selected": true und "is_additional": false.
4. Du darfst sinnvolle zusätzliche Zutaten ergänzen, wenn sie für ein vollständiges Rezept nötig sind. Markiere diese mit "is_user_selected": false und "is_additional": true.
5. Verwende bei Zutaten, die als einzelne Stücke gezählt werden, KEINE Einheit. Schreibe z. B. "amount": 1, "unit": "" für eine Zwiebel, ein Ei, eine Karotte oder eine Kartoffel. Verwende niemals "Stück", "Stk." oder "Stk" als Einheit. Bei messbaren Mengen wie g, kg, ml, l, EL, TL oder Pck. soll die passende Einheit erhalten bleiben.
6. Erstelle ein realistisches Rezept für 2 Portionen mit Zubereitungs- und Kochzeit sowie einer Schwierigkeit.
7. Diese JSON-Regeln gelten ausschließlich in Phase 2, nachdem ich einen Vorschlag ausgewählt habe. Die JSON-Datei selbst enthält ausschließlich die Rezeptdaten, ohne Markdown-Codeblöcke, Einleitung oder Erklärung.
8. Verwende exakt dieses Format und diese Feldnamen:
{
  "format": "together_recipe",
  "version": 1,
  "recipe": {
    "title": "Kurzer Rezeptname mit maximal 40 Zeichen",
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
14. Der Rezeptname im Feld recipe.title darf höchstens 40 Zeichen enthalten. Prüfe die Länge vor der Ausgabe und kürze ihn nötigenfalls sinnvoll auf maximal 40 Zeichen. Erst nach meiner Auswahl: Gib das vollständige Rezept gemäß dem oben definierten Schema aus. Fülle recipe.title, recipe.description, servings, prep_time_minutes, cook_time_minutes, difficulty, ingredients und steps sinnvoll aus. Lasse kein Feld und keine Zubereitungsschritte weg.
15. Erst nach meiner Auswahl: Erzeuge „together_recipe.json“ und stelle die Datei zum Download bereit. Prüfe, dass die JSON-Datei gültiges JSON im together_recipe-Format Version 1 enthält. Wenn Dateierstellung nicht verfügbar ist, gib ersatzweise das vollständige rohe JSON als Chat-Antwort aus, damit ich es als together_recipe.json speichern kann.
16. Behandle jedes Lebensmittel in der Liste „NICHT mag“ als verboten. Verwende es nicht als Zutat und schlage keinen direkten Ersatz vor, der dasselbe Lebensmittel enthält. Prüfe alle Zutaten einschließlich Saucen, Marinaden, Gewürzmischungen und optionaler Bestandteile vor der Ausgabe.
17. Bevorzuge Lebensmittel aus der Liste „mag ich“, sofern sie zum Rezept passen und nicht mit der Hauptauswahl oder anderen Regeln kollidieren. Du musst nicht alle Lieblingslebensmittel verwenden.
18. WICHTIG: Diese Anfrage dient ausschließlich der Rezept- und Dateierstellung. Generiere kein Bild und rufe keine Bildgenerierung auf. Die Bildgenerierung wird in einem getrennten Schritt angefordert, nachdem das Rezept vorliegt.
''';
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
