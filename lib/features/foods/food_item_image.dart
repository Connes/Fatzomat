import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FoodItemImage extends StatelessWidget {
  final String foodName;
  final double size;

  const FoodItemImage({super.key, required this.foodName, this.size = 46});

  static const Map<String, String> _emoji = {
    'Backpulver':'🧁','Kakao':'🍫','Marmelade':'🍓','Mehl':'🌾','Vanillezucker':'🍨','Zucker':'🍚',
    'Forelle':'🐟','Garnelen':'🍤','Kabeljau':'🐟','Lachs':'🍣','Thunfisch':'🐟','Hackfleisch':'🥩',
    'Hähnchen':'🍗','Hähnchenbrust':'🍗','Putenbrust':'🍗','Rinderhackfleisch':'🥩','Rindersteak':'🥩',
    'Salami':'🥓','Schinken':'🥩','Schweinefleisch':'🥩','Speck':'🥓','Würstchen':'🌭',
    'Aubergine':'🍆','Avocado':'🥑','Blumenkohl':'🥦','Brokkoli':'🥦','Champignons':'🍄','Cherrytomaten':'🍅',
    'Erbsen':'🫛','Grüne Bohnen':'🫛','Gurke':'🥒','Karotte':'🥕','Karotten':'🥕','Kartoffel':'🥔',
    'Kartoffeln':'🥔','Knoblauch':'🧄','Kürbis':'🎃','Lauch':'🥬','Mais':'🌽','Paprika':'🫑',
    'Rosenkohl':'🥬','Spinat':'🥬','Süßkartoffeln':'🍠','Tomate':'🍅','Tomaten':'🍅','Zucchini':'🥒',
    'Zwiebel':'🧅','Zwiebeln':'🧅','Brot':'🍞','Bulgur':'🌾','Couscous':'🍚','Gnocchi':'🥔',
    'Haferflocken':'🥣','Nudeln':'🍝','Penne':'🍝','Quinoa':'🌾','Reis':'🍚','Spaghetti':'🍝',
    'Toast':'🍞','Tortillas':'🌯','Basilikum':'🌿','Chili':'🌶️','Currypulver':'🟡','Oregano':'🌿',
    'Paprikapulver':'🟥','Petersilie':'🌿','Pfeffer':'⚫','Rosmarin':'🌿','Salz':'🧂','Sesam':'🌾',
    'Thymian':'🌿','Zimt':'🪵','Kichererbsen':'🫘','Kidneybohnen':'🫘','Linsen':'🫘','Weiße Bohnen':'🫘',
    'Butter':'🧈','Ei':'🥚','Eier':'🥚','Feta':'🧀','Frischkäse':'🧀','Gouda':'🧀',
    'Griechischer Joghurt':'🥣','Milch':'🥛','Mozzarella':'🧀','Naturjoghurt':'🥣','Parmesan':'🧀',
    'Quark':'🥣','Sahne':'🥛','Cashews':'🥜','Erdnüsse':'🥜','Haselnüsse':'🌰','Kürbiskerne':'🌱',
    'Mandeln':'🥜','Pistazien':'🥜','Sonnenblumenkerne':'🌻','Walnüsse':'🌰','Ananas':'🍍','Apfel':'🍎',
    'Banane':'🍌','Birne':'🍐','Erdbeeren':'🍓','Heidelbeeren':'🫐','Himbeeren':'🍓','Limette':'🍋',
    'Mandarine':'🍊','Mango':'🥭','Orange':'🍊','Pfirsich':'🍑','Trauben':'🍇','Zitrone':'🍋',
    'Currypaste':'🟡','Essig':'🫗','Gemüsebrühe':'🍲','Honig':'🍯','Ketchup':'🍅','Mayonnaise':'🥣',
    'Olivenöl':'🫒','Passierte Tomaten':'🍅','Pesto':'🌿','Senf':'🟡','Sojasauce':'🫗',
    'Sonnenblumenöl':'🌻','Tomatenmark':'🍅','Kokosmilch':'🥥',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _emoji[foodName] ?? '🍽️';
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
