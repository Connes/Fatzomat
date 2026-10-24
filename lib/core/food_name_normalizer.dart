/// Shared food-name normalization for search, filters and preference matching.
class FoodNameNormalizer {
  const FoodNameNormalizer._();

  static String normalize(String value) {
    var result = value.toLowerCase().trim();
    const replacements = <String, String>{
      'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss',
    };
    replacements.forEach((from, to) => result = result.replaceAll(from, to));
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    return result.replaceAll(RegExp(r'\\s+'), ' ');
  }

  /// Normalizes common German singular/plural endings for matching only.
  /// It never changes the canonical display name stored in the catalog.
  static String canonicalTerm(String value) {
    final normalized = normalize(value);
    final words = normalized.split(' ');
    return words.map(_singularize).join(' ');
  }

  static String _singularize(String word) {
    if (word.length < 5) return word;
    if (word.endsWith('nen') && word.length > 6) return word.substring(0, word.length - 1);
    if (word.endsWith('en') && word.length > 5) return word.substring(0, word.length - 2);
    if (word.endsWith('ern') && word.length > 6) return word.substring(0, word.length - 1);
    if (word.endsWith('e') && word.length > 5) return word.substring(0, word.length - 1);
    if (word.endsWith('n') && word.length > 5) return word.substring(0, word.length - 1);
    return word;
  }

  static bool matches(String value, String query) {
    final normalizedValue = normalize(value);
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;
    if (normalizedValue.contains(normalizedQuery)) return true;
    final canonicalValue = canonicalTerm(value);
    final canonicalQuery = canonicalTerm(query);
    return canonicalValue.contains(canonicalQuery) ||
        canonicalQuery.contains(canonicalValue);
  }

  static bool equivalentOrContains(String left, String right) {
    final a = canonicalTerm(left);
    final b = canonicalTerm(right);
    return a == b || a.contains(b) || (b.length >= 5 && b.contains(a));
  }
}
