/// Merchant-name based category resolution.
///
/// The reward points API does not return MCC codes, so categories are inferred
/// from merchant names using built-in rules and optional user-defined rules.
class MerchantCategoryRule {
  final String category;
  final List<String> keywords;

  const MerchantCategoryRule({
    required this.category,
    required this.keywords,
  });

  MerchantCategoryRule copyWith({String? category, List<String>? keywords}) {
    return MerchantCategoryRule(
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'keywords': keywords,
      };

  factory MerchantCategoryRule.fromMap(Map<dynamic, dynamic> map) {
    return MerchantCategoryRule(
      category: map['category']?.toString() ?? 'Other',
      keywords: (map['keywords'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const [],
    );
  }
}

class MerchantCategories {
  MerchantCategories._();

  static const String fallbackCategory = 'Other';

  /// Default categories available out of the box.
  static const List<String> predefinedCategories = [
    'Supermarkets',
    'Restaurants',
    'Fast Food',
    'Transport',
    'Gas Stations',
    'Electronics',
    'Clothing',
    'Pharmacies',
    'Hotels & Travel',
    'Entertainment',
    'Stationery and office',
    'Utilities',
    'Other',
  ];

  static const List<MerchantCategoryRule> builtInRules = [
    MerchantCategoryRule(
      category: 'Supermarkets',
      keywords: [
        'varus',
        'atb',
        'silpo',
        'novus',
        'metro',
        'auchan',
        'walmart',
        'carrefour',
        'tesco',
        'lidl',
        'aldi',
      ],
    ),
    MerchantCategoryRule(
      category: 'Stationery and office',
      keywords: ['skrepka', 'office depot', 'staples'],
    ),
    MerchantCategoryRule(
      category: 'Restaurants',
      keywords: [
        'restaurant',
        'cafe',
        'coffee',
        'mcdonald',
        'kfc',
        'starbucks',
        'pizza',
        'sushi',
      ],
    ),
    MerchantCategoryRule(
      category: 'Transport',
      keywords: [
        'uber',
        'bolt',
        'taxi',
        'uklon',
        'railway',
        'bus',
      ],
    ),
    MerchantCategoryRule(
      category: 'Gas Stations',
      keywords: ['wog', 'okko', 'shell', 'bp', 'fuel', 'gas station'],
    ),
    MerchantCategoryRule(
      category: 'Electronics',
      keywords: [
        'apple',
        'amazon',
        'rozetka',
        'comfy',
        'epicentr',
        'media markt',
        'pinduoduo',
      ],
    ),
  ];

  /// All selectable categories: predefined + user-created (sorted, unique).
  static List<String> allCategories(List<String> customCategories) {
    final set = {...predefinedCategories, ...customCategories};
    final list = set.toList()..sort();
    if (list.remove(fallbackCategory)) {
      list.add(fallbackCategory);
    }
    return list;
  }

  /// Resolves a category from [merchName], optional API description, and rules.
  static String resolve(
    String? merchName, {
    String? apiCategory,
    List<MerchantCategoryRule> userRules = const [],
  }) {
    final name = merchName?.toLowerCase().trim() ?? '';

    for (final rule in [...userRules, ...builtInRules]) {
      for (final keyword in rule.keywords) {
        if (keyword.isNotEmpty && name.contains(keyword)) {
          return rule.category;
        }
      }
    }

    if (apiCategory != null && apiCategory.trim().isNotEmpty) {
      return apiCategory.trim();
    }

    return fallbackCategory;
  }
}
