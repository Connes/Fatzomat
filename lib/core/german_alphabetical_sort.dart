/// Shared German alphabetical ordering for lists of food names.
String germanAlphabeticalKey(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss');

int compareGermanAlphabetically(String a, String b) {
  final byKey = germanAlphabeticalKey(a).compareTo(germanAlphabeticalKey(b));
  return byKey != 0 ? byKey : a.toLowerCase().compareTo(b.toLowerCase());
}

List<T> sortByGermanName<T>(
  Iterable<T> values,
  String Function(T value) nameOf,
) {
  final result = values.toList();
  result.sort((a, b) => compareGermanAlphabetically(nameOf(a), nameOf(b)));
  return result;
}
