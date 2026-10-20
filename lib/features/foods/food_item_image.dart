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
    'Backpulver':'🥄','Kakao':'🍫','Marmelade':'🍯','Mehl':'🌾','Vanillezucker':'🥄','Zucker':'🥄',
    // Fish and seafood
    'Dorade':'🐟','Forelle':'🐟','Garnelen':'🍤','Heilbutt':'🐟','Hering':'🐟','Kabeljau':'🐟',
    'Lachs':'🐟','Makrele':'🐟','Pangasius':'🐟','Räucherlachs':'🐟','Rotbarsch':'🐟',
    'Sardellen':'🐟','Thunfisch':'🐟','Wolfsbarsch':'🐟','Krabben':'🦀','Miesmuscheln':'🦪','Tintenfisch':'🦑',
    // Meat
    'Entenbrust':'🦆','Gemischtes Hackfleisch':'🥩','Hähnchen':'🐔',
    'Hähnchenbrust':'🐔','Hähnchenflügel':'🐔','Hähnchenhackfleisch':'🐔','Hähncheninnenfilet':'🐔',
    'Kalbfleisch':'🐄','Kassler':'🐖','Lammhackfleisch':'🐑','Lammkotelett':'🐑','Putenbrust':'🐔',
    'Rinderbraten':'🐄','Rinderfilet':'🐄','Rinderhackfleisch':'🐄','Rinderrouladen':'🐄','Rindersteak':'🐄',
    'Salami':'🐖','Schinken':'🐖','Schweinebraten':'🐖','Schweinefleisch':'🐖',
    'Schweinehackfleisch':'🐖','Spareribs':'🐖','Speck':'🐖','Würstchen':'🐖',
    // Vegetables
    'Artischocke':'🥬','Aubergine':'🍆','Austernpilze':'🍄','Avocado':'🥑','Blumenkohl':'🥦',
    'Brokkoli':'🥦','Brunnenkresse':'🥬','Champignons':'🍄','Cherrytomaten':'🍅','Chicorée':'🥬',
    'Chinakohl':'🥬','Endivie':'🥬','Erbsen':'🫛','Feldsalat':'🥬','Fenchel':'🥬','Frische Chilischote':'🌶️',
    'Frühlingszwiebel':'🧅','Grüne Bohnen':'🫛','Gurke':'🥒','Karotte':'🥕','Karotten':'🥕',
    'Kartoffel':'🥔','Kartoffeln':'🥔','Knoblauch':'🧄','Knollensellerie':'🥬','Kohlrabi':'🥬',
    'Kürbis':'🎃','Lauch':'🥬','Mais':'🌽','Mangold':'🥬','Okra':'🥬','Pak Choi':'🥬','Paprika':'🫑',
    'Pastinake':'🥕','Petersilienwurzel':'🥕','Radieschen':'🫜','Rettich':'🫜','Romanesco':'🥦',
    'Rosenkohl':'🥬','Rote Bete':'🫜','Schalotte':'🧅','Shiitake-Pilze':'🍄','Spinat':'🥬','Spitzkohl':'🥬',
    'Stangensellerie':'🥬','Steckrübe':'🫜','Süßkartoffel':'🍠','Süßkartoffeln':'🍠','Tomate':'🍅',
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
    'Ananas':'🍍','Apfel':'🍎','Banane':'🍌','Wassermelone':'🍉','Birne':'🍐','Erdbeeren':'🍓','Heidelbeeren':'🫐',
    'Himbeeren':'🍓','Kiwi':'🥝','Limette':'🍋‍🟩','Mandarine':'🍊','Mango':'🥭','Orange':'🍊','Pfirsich':'🍑','Trauben':'🍇','Zitrone':'🍋',
    // Sauces and pantry basics
    'Currypaste':'🟡','Essig':'🫗','Gemüsebrühe':'🍲','Honig':'🍯','Ketchup':'🍅','Kokosmilch':'🥥',
    'Mayonnaise':'🥣','Olive':'🫒','Olivenöl':'🫒','Passierte Tomaten':'🍅','Pesto':'🌿','Senf':'🟡',
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

  static String? assetFor(String name) {
    switch (name.trim().toLowerCase()) {
      case 'apfel':
        return 'assets/foods/apfel.webp';
      case 'forelle':
        return 'assets/foods/forelle.webp';
      case 'lachs':
        return 'assets/foods/lachs.webp';
      case 'kabeljau':
        return 'assets/foods/kabeljau.webp';
      case 'makrele':
        return 'assets/foods/makrele.webp';
      case 'pangasius':
        return 'assets/foods/pangasius.webp';
      case 'räucherlachs':
      case 'raeucherlachs':
        return 'assets/foods/raeucherlachs.webp';
      case 'rotbarsch':
        return 'assets/foods/rotbarsch.webp';
      case 'dorade':
        return 'assets/foods/dorade.webp';
      case 'heilbutt':
        return 'assets/foods/heilbutt.webp';
      case 'hering':
        return 'assets/foods/hering.webp';
      case 'banane':
        return 'assets/foods/banane.webp';
      case 'zitrone':
        return 'assets/foods/zitrone.webp';
      case 'erdbeeren':
        return 'assets/foods/erdbeeren.webp';
      case 'heidelbeeren':
        return 'assets/foods/heidelbeeren.webp';
      case 'himbeeren':
        return 'assets/foods/himbeeren.webp';
      case 'birne':
        return 'assets/foods/birne.webp';
      case 'orange':
        return 'assets/foods/orange.webp';
      case 'mango':
        return 'assets/foods/mango.webp';
      case 'ananas':
        return 'assets/foods/ananas.webp';
      case 'trauben':
        return 'assets/foods/trauben.webp';
      case 'kiwi':
        return 'assets/foods/kiwi.webp';
      case 'limette':
        return 'assets/foods/limette.webp';
      case 'mandarine':
        return 'assets/foods/mandarine.webp';
      case 'pfirsich':
        return 'assets/foods/pfirsich.webp';
      case 'wassermelone':
        return 'assets/foods/wassermelone.webp';
      case 'avocado':
        return 'assets/foods/avocado.svg';
      case 'aubergine':
        return 'assets/foods/aubergine.svg';
      case 'champignons':
      case 'austernpilze':
      case 'shiitake-pilze':
        return 'assets/foods/champignons.svg';
      case 'erbsen':
        return 'assets/foods/erbsen.svg';
      case 'mais':
        return 'assets/foods/mais.svg';
      case 'kürbis':
      case 'kuerbis':
        return 'assets/foods/kuerbis.svg';
      case 'frühlingszwiebel':
      case 'fruehlingszwiebel':
        return 'assets/foods/fruehlingszwiebel.svg';
      case 'gurke':
        return 'assets/foods/gurke.svg';
      case 'paprika':
        return 'assets/foods/paprika.svg';
      case 'zucchini':
        return 'assets/foods/zucchini.svg';
      case 'blumenkohl':
        return 'assets/foods/blumenkohl.svg';
      case 'spinat':
        return 'assets/foods/spinat.svg';
      case 'knoblauch':
        return 'assets/foods/knoblauch.svg';
      case 'brokkoli':
        return 'assets/foods/brokkoli.svg';
      case 'karotte':
      case 'karotten':
        return 'assets/foods/karotte.svg';
      case 'kartoffel':
      case 'kartoffeln':
        return 'assets/foods/kartoffel.svg';
      case 'tomate':
      case 'tomaten':
      case 'cherrytomaten':
        return 'assets/foods/tomate.svg';
      case 'zwiebel':
      case 'zwiebeln':
      case 'schalotte':
        return 'assets/foods/zwiebel.svg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = emojiFor(foodName, category: category);
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
        '<circle cx="32" cy="32" r="29" fill="#FFF4E8"/>'
        '<text x="32" y="43" text-anchor="middle" font-size="32" '
        'font-family="Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji">$icon</text>'
        '</svg>';
    final asset = assetFor(foodName);
    final Widget illustration;
    if (asset == null) {
      illustration = SvgPicture.string(svg, width: size, height: size);
    } else if (asset.endsWith('.svg')) {
      illustration = SvgPicture.asset(asset, width: size, height: size, fit: BoxFit.contain);
    } else {
      illustration = Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
    }
    return Semantics(
      image: true,
      label: foodName,
      child: SizedBox(width: size, height: size, child: illustration),
    );
  }
}
