class Food {
  final String id;
  final String name;
  final String category;
  final List<String> searchTerms;
  final List<String> aliases;
  final String defaultUnit;
  final String dietaryType;
  final List<String> allergens;
  final String? proteinType;
  final String? createdBy;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    this.searchTerms = const [],
    this.aliases = const [],
    this.defaultUnit = 'Stück',
    this.dietaryType = 'omnivore',
    this.allergens = const [],
    this.proteinType,
    this.createdBy,
  });

  factory Food.fromMap(Map<String, dynamic> map) => Food(
        id: map['id'].toString(),
        name: map['name']?.toString() ?? '',
        category: map['category']?.toString() ?? '',
        searchTerms: _strings(map['search_terms']),
        aliases: _strings(map['aliases']),
        defaultUnit: map['default_unit']?.toString() ?? 'Stück',
        dietaryType: map['dietary_type']?.toString() ?? 'omnivore',
        allergens: _strings(map['allergens']),
        proteinType: map['protein_type']?.toString(),
        createdBy: map['created_by']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'search_terms': searchTerms,
        'aliases': aliases,
        'default_unit': defaultUnit,
        'dietary_type': dietaryType,
        'allergens': allergens,
        'protein_type': proteinType,
        'created_by': createdBy,
      };

  static List<String> _strings(dynamic value) => value is List
      ? value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList(growable: false)
      : value is String && value.trim().isNotEmpty
          ? [value.trim()]
          : const [];
}
