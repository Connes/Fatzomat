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
- Diese Regel gilt für alle Internet- und eigenen Vorschläge. Eigene Rezeptideen müssen sie erfüllen. Internetrezepte dürfen nicht verändert werden; wähle nur passende Originalrezepte aus. Wenn die Auswahl zu keinem sinnvollen Gericht passt, schlage nur Gerichte vor, die mit genau diesen Lebensmitteln machbar sind; verschweige keine zusätzlichen Lebensmittel in Saucen, Marinaden oder Beilagen.
'''
        : '''ERGÄNZUNGEN ERLAUBT:
- Du darfst neben der Hauptauswahl und den ausgewählten Zutaten weitere Lebensmittel integrieren, wenn sie kulinarisch sinnvoll sind und das Rezept verbessern.
- Verwende keine ausgeschlossenen Lebensmittel und beachte alle übrigen Regeln.
''';

    return '''Arbeite in zwei klar getrennten Phasen. In deiner ERSTEN Antwort machst du Rezeptvorschläge. Erstelle noch KEIN vollständiges Rezept und KEINE Datei, bis ich einen Vorschlag ausgewählt habe.

$ingredientConstraint
PHASE 1 – INTERNETREZEPTE UND EIGENE IDEEN:
- Suche zuerst nach passenden Originalrezepten auf genau diesen Webseiten, in dieser Reihenfolge: einfachkochen.de, chefkoch.de, emmikochteinfach.de (Emmi kocht einfach), lecker.de und essen-und-trinken.de.
- Die gesamte Internetrecherche darf höchstens 30 Sekunden dauern. Beende die Suche nach spätestens 30 Sekunden und suche danach nicht weiter. Diese Vorgabe ist eine Suchzeit-Grenze für dich; falls die verwendete ChatGPT-Suchfunktion keine echte Zeitbegrenzung unterstützt, kann dieser Prompt allein keine technisch garantierte Stoppuhr erzwingen.
- Suche nur mit der verfügbaren Websuche. Behaupte nicht, eine Webseite geprüft zu haben, wenn du sie nicht tatsächlich aufgerufen oder verifiziert hast.
- Finde höchstens drei passende Internetrezepte. Jeder Internetfund muss ein tatsächlich vorhandenes Rezept auf einer der genannten Webseiten sein, mit überprüfbarem Titel und direktem Link zur Originalseite. Erfinde niemals Quellen, Titel, Links oder angebliche Suchtreffer.
- Öffne den direkten Rezeptlink und lies die Rezeptseite tatsächlich aus, sofern sie zugänglich ist. Prüfe dort Titel, Zutatenliste und Mengen sowie die Zubereitung. Ein Suchtreffer oder Snippet allein gilt nicht als ausgelesenes Rezept. Verwende keine Angaben, die du nicht auf der Seite verifizieren konntest.
- In Phase 1 zeigst du nur Vorschlagsinformationen. Nach Auswahl erstellst du eine importierbare, eigenständig formulierte Rezeptfassung auf Grundlage der verifizierten Seite: übernimm Zutaten und Mengen sachlich korrekt, formuliere die Zubereitungsschritte in eigenen Worten und fasse sie zusammen, statt geschützte Anleitungstexte wortwörtlich zu kopieren. Erfinde keine fehlenden Quellangaben und kennzeichne diese Fassung nicht als wortgetreue Kopie. Kombiniere keine Rezepte.
- Nenne für jeden Internetfund Titel, Website und direkten Link zur Originalseite. Die Quelle muss nach dem Import erhalten bleiben: schreibe in recipe.description am Ende „Quelle: <vollständige URL>“. Erfinde niemals Quellen, Titel, Links, Mengen oder angebliche Suchtreffer.
- Wenn „Nur diese Lebensmittel verwenden“ aktiv ist, berücksichtige nur Internetrezepte, deren Zutaten die strikte Zutatenbeschränkung erfüllen. Verändere kein Originalrezept, um es passend zu machen. Wenn die Checkbox nicht aktiv ist, beachte weiterhin die Hauptauswahl, ausgewählten Zutaten und ausgeschlossenen Lebensmittel.
- Stoppe die Suche nach spätestens 30 Sekunden, auch wenn du weniger als drei passende Internetrezepte gefunden hast. Ersetze fehlende Internetfunde nicht durch erfundene Internetrezepte.
- Erstelle zusätzlich genau zwei eigenständige Rezeptideen, die du selbst entwickelst. Kennzeichne sie klar als „Eigene Rezeptidee von ChatGPT“ und gib sie niemals als Internetfund aus.
- Zeige zuerst die tatsächlich gefundenen Internetrezepte (0 bis 3) und danach die zwei eigenen Ideen. Die Gesamtzahl ist daher 2 bis 5 Vorschläge: 3 Internetfunde + 2 eigene Ideen, wenn alle drei gefunden werden; andernfalls nur die tatsächlich gefundenen Internetrezepte plus zwei eigene Ideen.
- Für jeden Vorschlag gib einen kurzen Rezeptnamen mit höchstens 40 Zeichen, eine knappe Beschreibung, die wichtigsten Zutaten und eine ungefähre Zubereitungszeit an. Begrenze jeden Rezeptnamen auf maximal 40 Zeichen; kürze ihn bei Bedarf sinnvoll. Diese Grenze gilt auch für recipe.title in der späteren JSON-Datei.
- Nummeriere alle Vorschläge fortlaufend ab 1, ohne Lücken oder doppelte Nummern.
- Frage am Ende kurz, welchen Vorschlag ich wählen möchte.
- In dieser Phase keine JSON-Ausgabe, kein vollständiges Rezept, keine Datei und keine Bildgenerierung.

PHASE 2 – NACH MEINER AUSWAHL:
- Sobald ich die Nummer oder den Namen eines Vorschlags auswähle, erstelle nur für dieses Gericht das vollständige Rezept.
- Wenn ich ein Internetrezept auswähle, öffne erneut den direkten Link und extrahiere die Zutaten und Mengen sowie die wesentlichen Kochschritte aus der tatsächlich zugänglichen Seite. Erstelle daraus ein vollständiges, importierbares Rezept in eigenen Worten. Zutaten und Mengen sollen der Quelle entsprechen; formuliere die Zubereitung knapp neu, statt die Originalanleitung wortwörtlich zu kopieren. Füge keine Zutaten hinzu, entferne keine und ändere keine Mengen, außer ich bitte ausdrücklich um eine Anpassung. Füge die vollständige Quell-URL am Ende von recipe.description als „Quelle: <URL>“ ein.
- Wenn die Seite nicht geöffnet werden kann oder wichtige Zutaten/Mengen nicht sichtbar sind, behaupte nicht, das Rezept ausgelesen zu haben. Erstelle keine erfundene oder unvollständige Datei. Bitte mich stattdessen, den Rezepttext oder Screenshots der Zutatenliste und Zubereitung in den Chat zu geben; nutze diese Angaben dann als Quelle und erstelle die JSON-Datei. Biete alternativ eine der eigenen Rezeptideen an. Verweigere die Datei nicht allein deshalb, weil die Quelle ein Internetrezept ist: eine eigenständig formulierte, quellengestützte Zusammenfassung mit korrekten Zutaten/Mengen und Quellenlink ist das gewünschte Ergebnis.
- Wenn ich eine eigene Rezeptidee auswähle, erstelle dafür das vollständige Rezept nach den Regeln und Zutatenbeschränkungen unten.
- Erstelle zusätzlich eine echte Datei „together_recipe.json“ im unten definierten Format Version 1, damit ich sie in der App Schmackofatz über „Rezeptdatei importieren“ auswählen kann. Das bestehende JSON-Schema Version 1 darf nicht geändert oder um neue Pflichtfelder erweitert werden.
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
