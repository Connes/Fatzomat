import 'package:flutter/material.dart';

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
        return 'assets/foods/avocado.webp';
      case 'aubergine':
        return 'assets/foods/aubergine.webp';
      case 'champignons':
      case 'austernpilze':
      case 'shiitake-pilze':
        return 'assets/foods/champignons.webp';
      case 'erbsen':
        return 'assets/foods/erbsen.webp';
      case 'mais':
        return 'assets/foods/mais.webp';
      case 'kürbis':
      case 'kuerbis':
        return 'assets/foods/kuerbis.webp';
      case 'fenchel':
        return 'assets/foods/fenchel.webp';
      case 'radieschen':
        return 'assets/foods/radieschen.webp';
      case 'rote bete':
        return 'assets/foods/rote_bete.webp';
      case 'pastinake':
        return 'assets/foods/pastinake.webp';
      case 'pak choi':
        return 'assets/foods/pak_choi.webp';
      case 'chinakohl':
        return 'assets/foods/chinakohl.webp';
      case 'weißkohl':
      case 'weisskohl':
        return 'assets/foods/weisskohl.webp';
      case 'frühlingszwiebel':
      case 'fruehlingszwiebel':
        return 'assets/foods/fruehlingszwiebel.webp';
      case 'gurke':
        return 'assets/foods/gurke.webp';
      case 'paprika':
        return 'assets/foods/paprika.webp';
      case 'zucchini':
        return 'assets/foods/zucchini.webp';
      case 'blumenkohl':
        return 'assets/foods/blumenkohl.webp';
      case 'spinat':
        return 'assets/foods/spinat.webp';
      case 'knoblauch':
        return 'assets/foods/knoblauch.webp';
      case 'brokkoli':
        return 'assets/foods/brokkoli.webp';
      case 'karotte':
      case 'karotten':
        return 'assets/foods/karotte.webp';
      case 'kartoffel':
      case 'kartoffeln':
        return 'assets/foods/kartoffel.webp';
      case 'tomate':
      case 'tomaten':
      case 'cherrytomaten':
        return 'assets/foods/tomate.webp';
      case 'zwiebel':
      case 'zwiebeln':
      case 'schalotte':
        return 'assets/foods/zwiebel.webp';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = emojiFor(foodName, category: category);
    final asset = assetFor(foodName);
    final Widget illustration;
    if (asset == null) {
      illustration = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF4E8),
          shape: BoxShape.circle,
        ),
        child: Text(icon, style: TextStyle(fontSize: size * 0.52)),
      );
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
