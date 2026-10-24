/// Shared food-name normalization for search, filters and preference matching.
class FoodNameNormalizer {
  const FoodNameNormalizer._();

  static const Map<String, String> _pluralForms = {
    'tomaten': 'tomate',
    'kidneybohnen': 'kidneybohne',
    'champignons': 'champignon',
    'cashews': 'cashew',
    'erbsen': 'erbse',
    'erdbeeren': 'erdbeere',
    'erdnuesse': 'erdnuss',
    'garnelen': 'garnele',
    'heidelbeeren': 'heidelbeere',
    'himbeeren': 'himbeere',
    'kichererbsen': 'kichererbse',
    'linsen': 'linse',
    'mandeln': 'mandel',
    'pistazien': 'pistazie',
    'trauben': 'traube',
    'walnuesse': 'walnuss',
    'zuckerschoten': 'zuckerschote',
    'suesskartoffeln': 'suesskartoffel',
    'kidney bohnen': 'kidney bohne',
    'weisse bohnen': 'weisse bohne',
    'grune bohnen': 'grune bohne',
    'haselnuesse': 'haselnuss',
    'kuerbiskerne': 'kuerbiskern',
    'sonnenblumenkerne': 'sonnenblumenkern',
    'tortillas': 'tortilla',
    'oliven': 'olive',
    'kartoffeln': 'kartoffel',
    'karotten': 'karotte',
    'zwiebeln': 'zwiebel',
    'gurken': 'gurke',
    'aepfel': 'apfel',
    'birnen': 'birne',
    'bananen': 'banane',
  };

  static String normalize(String value) {
    var result = value.toLowerCase().trim();
    const replacements = <String, String>{
      'ä': 'ae',
      'ö': 'oe',
      'ü': 'ue',
      'ß': 'ss',
    };
    replacements.forEach((from, to) => result = result.replaceAll(from, to));
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Maps known plural forms to their canonical singular form for matching.
  /// This is search-only and never changes catalog display names.
  static String canonicalTerm(String value) {
    final normalized = normalize(value);
    final direct = _pluralForms[normalized];
    if (direct != null) return direct;

    final words = normalized.split(' ');
    return words.map((word) => _singularize(word)).join(' ');
  }

  static String _singularize(String word) {
    // Only normalize explicitly known plural forms. Generic suffix stripping
    // corrupts valid singular names such as "Champignon".
    return _pluralForms[word] ?? word;
  }

  static bool matches(String value, String query) {
    final normalizedValue = normalize(value);
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;

    // Preserve ordinary prefix/substring search for the user's typed query.
    if (normalizedValue.contains(normalizedQuery)) return true;

    final canonicalValue = canonicalTerm(value);
    final canonicalQuery = canonicalTerm(query);
    return canonicalValue.contains(canonicalQuery);
  }

  /// Matches equivalent names or a whole phrase contained in another name.
  /// It deliberately avoids reverse substring matching (e.g. Paprika matching
  /// Paprikapulver) to reduce false positives in preference checks.
  static bool equivalentOrContains(String left, String right) {
    final a = canonicalTerm(left);
    final b = canonicalTerm(right);
    if (a == b) return true;
    if (a.isEmpty || b.isEmpty) return false;
    return (' $a ').contains(' $b ');
  }
}
