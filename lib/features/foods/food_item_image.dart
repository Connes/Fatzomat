import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared emoji illustration for catalog and custom foods.
class FoodItemImage extends StatelessWidget {
  final String foodName;
  final String? category;
  final double size;

  const FoodItemImage({super.key, required this.foodName, this.category, this.size = 46});

  static const Map<String, String> _emoji = {
    // Baking and sweets
    'Backpulver':'🧁','Kakao':'🍫','Marmelade':'🍓','Mehl':'🌾','Vanillezucker':'🍨','Zucker':'🍚',
    // Fish and seafood
    'Dorade':'🐠','Forelle':'🐟','Garnelen':'🍤','Heilbutt':'🐡','Hering':'🐟','Kabeljau':'🐠',
    'Lachs':'🍣','Makrele':'🐟','Pangasius':'🐠','Räucherlachs':'🍣','Rotbarsch':'🐡',
    'Sardellen':'🐟','Thunfisch':'🐟','Wolfsbarsch':'🐠','Krabben':'🦀','Miesmuscheln':'🦪','Tintenfisch':'🦑',
    // Meat
    'Entenbrust':'🦆','Gemischtes Hackfleisch':'🥩','Hähnchen':'🐔',
    'Hähnchenbrust':'🐔','Hähnchenflügel':'🐔','Hähnchenhackfleisch':'🐔','Hähncheninnenfilet':'🐔',
    'Kalbfleisch':'🐄','Kassler':'🐖','Lammhackfleisch':'🐑','Lammkotelett':'🐑','Putenbrust':'🐔',
    'Rinderbraten':'🐄','Rinderfilet':'🐄','Rinderhackfleisch':'🐄','Rinderrouladen':'🐄','Rindersteak':'🐄',
    'Salami':'🐖','Schinken':'🐖','Schweinebraten':'🐖','Schweinefleisch':'🐖',
    'Schweinehackfleisch':'🐖','Spareribs':'🐖','Speck':'🐖','Würstchen':'🐖',
    // Vegetables
    'Artischocke':'🌿','Aubergine':'🍆','Austernpilze':'🍄','Avocado':'🥑','Blumenkohl':'🥦',
    'Brokkoli':'🥦','Brunnenkresse':'🌿','Champignons':'🍄','Cherrytomaten':'🍅','Chicorée':'🥬',
    'Chinakohl':'🥬','Endivie':'🥬','Erbsen':'🫛','Feldsalat':'🥬','Fenchel':'🌿','Frische Chilischote':'🌶️',
    'Frühlingszwiebel':'🧅','Grüne Bohnen':'🫛','Gurke':'🥒','Karotte':'🥕','Karotten':'🥕',
    'Kartoffel':'🥔','Kartoffeln':'🥔','Knoblauch':'🧄','Knollensellerie':'🥬','Kohlrabi':'🥬',
    'Kürbis':'🎃','Lauch':'🥬','Mais':'🌽','Mangold':'🥬','Okra':'🥬','Pak Choi':'🥬','Paprika':'🫑',
    'Pastinake':'🥕','Petersilienwurzel':'🥕','Radieschen':'🔴','Rettich':'🥬','Romanesco':'🥦',
    'Rosenkohl':'🥬','Rote Bete':'🟣','Schalotte':'🧅','Shiitake-Pilze':'🍄','Spinat':'🥬','Spitzkohl':'🥬',
    'Stangensellerie':'🥬','Steckrübe':'🥔','Süßkartoffel':'🍠','Süßkartoffeln':'🍠','Tomate':'🍅',
    'Tomaten':'🍅','Weißkohl':'🥬','Zucchini':'🥒','Zuckerschoten':'🫛','Zwiebel':'🧅','Zwiebeln':'🧅',
    // Grains and sides
    'Brot':'🍞','Bulgur':'🌾','Couscous':'🍚','Gnocchi':'🥔','Haferflocken':'🥣','Nudeln':'🍝',
    'Penne':'🍝','Quinoa':'🌾','Reis':'🍚','Spaghetti':'🍝','Toast':'🍞','Tortillas':'🌯',
    // Herbs and spices
    'Basilikum':'🌿','Chili':'🌿','Currypulver':'🌿','Dill':'🌿','Estragon':'🌿','Fenchelsamen':'🌿',
    'Garam Masala':'🌿','Geräuchertes Paprikapulver':'🌿','Italienische Kräuter':'🌿','Kardamom':'🌿',
    'Koriander':'🌿','Koriandersamen':'🌿','Kräuter der Provence':'🌿','Liebstöckel':'🌿',
    'Lorbeerblatt':'🌿','Majoran':'🌿','Minze':'🌿','Nelken':'🌿','Oregano':'🌿','Paprikapulver':'🌿',
    'Petersilie':'🌿','Pfeffer':'🌿','Rosmarin':'🌿','Salbei':'🌿','Salz':'🌿','Schnittlauch':'🌿',
    'Senfkörner':'🌿','Sesam':'🌿','Thymian':'🌿','Zimt':'🌿','Zitronengras':'🌿','Zitronenmelisse':'🌿',
    // Legumes
    'Kichererbsen':'🫘','Kidneybohnen':'🫘','Linsen':'🫘','Weiße Bohnen':'🫘',
    // Dairy and eggs
    'Butter':'🧈','Ei':'🥚','Eier':'🥚','Feta':'🧀','Frischkäse':'🧀','Gouda':'🧀',
    'Griechischer Joghurt':'🥣','Milch':'🥛','Mozzarella':'🧀','Naturjoghurt':'🥣','Parmesan':'🧀','Quark':'🥣','Sahne':'🥛',
    // Nuts and seeds
    'Cashews':'🥜','Erdnüsse':'🥜','Haselnüsse':'🌰','Kürbiskerne':'🌱','Mandeln':'🥜',
    'Pistazien':'🥜','Sonnenblumenkerne':'🌻','Walnüsse':'🌰',
    // Fruit
    'Ananas':'🍍','Apfel':'🍎','Banane':'🍌','Birne':'🍐','Erdbeeren':'🍓','Heidelbeeren':'🫐',
    'Himbeeren':'🍓','Limette':'🍋','Mandarine':'🍊','Mango':'🥭','Orange':'🍊','Pfirsich':'🍑','Trauben':'🍇','Zitrone':'🍋',
    // Sauces and pantry basics
    'Currypaste':'🟡','Essig':'🫗','Gemüsebrühe':'🍲','Honig':'🍯','Ketchup':'🍅','Kokosmilch':'🥥',
    'Mayonnaise':'🥣','Olivenöl':'🫒','Passierte Tomaten':'🍅','Pesto':'🌿','Senf':'🟡',
    'Sojasauce':'🫗','Sonnenblumenöl':'🌻','Tomatenmark':'🍅',
  };

  static const Map<String, String> _categoryEmoji = {
    'fleisch':'🥩','fisch':'🐟','meeresfrüchte':'🦐','gemüse':'🥬','obst':'🍎',
    'milchprodukte':'🥛','milchprodukte & eier':'🥚','getreide & beilagen':'🌾',
    'hülsenfrüchte':'🫘','nüsse & kerne':'🥜','gewürze':'🌿','gewürze & kräuter':'🌿',
    'saucen & grundzutaten':'🫙','backen & süßes':'🧁','sonstiges':'🍽️',
  };

  static String emojiFor(String name, {String? category}) {
    final normalized = name.trim().toLowerCase();
    for (final entry in _emoji.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return _categoryEmoji[category?.trim().toLowerCase()] ?? '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    final icon = emojiFor(foodName, category: category);
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
        '<circle cx="32" cy="32" r="29" fill="#FFF4E8"/>'
        '<text x="32" y="43" text-anchor="middle" font-size="32" '
        'font-family="Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji">$icon</text>'
        '</svg>';
    return Semantics(
      image: true,
      label: foodName,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(svg, width: size, height: size),
      ),
    );
  }
}
