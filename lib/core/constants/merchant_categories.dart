/// Category resolution based solely on MCC code.
///
/// Name-based keyword matching has been removed — the asset-records API
/// provides mccCode on every transaction, which is authoritative.
/// Manual per-transaction overrides are still supported via customCategory.
class MerchantCategoryRule {
  final String category;
  final String pattern;
  final bool exactMatch;

  const MerchantCategoryRule({
    required this.category,
    required this.pattern,
    this.exactMatch = false,
  });

  MerchantCategoryRule copyWith({String? category, String? pattern, bool? exactMatch}) {
    return MerchantCategoryRule(
      category: category ?? this.category,
      pattern: pattern ?? this.pattern,
      exactMatch: exactMatch ?? this.exactMatch,
    );
  }

  Map<String, dynamic> toMap() => {
    'category': category,
    'pattern': pattern,
    'exactMatch': exactMatch,
  };

  factory MerchantCategoryRule.fromMap(Map<dynamic, dynamic> map) {
    String p = map['pattern']?.toString() ?? '';
    if (p.isEmpty && map['keywords'] is List) {
      final list = map['keywords'] as List;
      if (list.isNotEmpty) p = list.first.toString();
    }
    return MerchantCategoryRule(
      category: map['category']?.toString() ?? 'Other',
      pattern: p,
      exactMatch: map['exactMatch'] == true,
    );
  }
}

class MerchantCategories {
  MerchantCategories._();

  static const String fallbackCategory = 'Other';

  static const List<String> predefinedCategories = [
    'Supermarkets & Food',
    'Restaurants & Bars',
    'Fast Food',
    'Transport',
    'Gas Stations',
    'Electronics',
    'Clothing & Accessories',
    'Pharmacies & Health',
    'Hotels & Travel',
    'Entertainment',
    'Stationery & Office',
    'Utilities & Telecom',
    'Auto & Vehicles',
    'Beauty & Personal Care',
    'Home & Garden',
    'Education',
    'Finance & Insurance',
    'Government & Taxes',
    'Charity & Social',
    'Other',
  ];

  // No built-in keyword rules — MCC is the source of truth.
  static const List<MerchantCategoryRule> builtInRules = [];

  /// Full MCC → category mapping based on the Ukrainian MCC catalogue.
  static String? _categoryFromMcc(String? mccCode) {
    final mcc = int.tryParse(mccCode ?? '');
    if (mcc == null) return null;

    return switch (mcc) {
      // ── Agriculture & Veterinary ─────────────────────────────────
      742 || 763 || 780 => 'Other',

      // ── Construction ─────────────────────────────────────────────
      1520 ||
      1711 ||
      1731 ||
      1740 ||
      1750 ||
      1761 ||
      1771 ||
      1799 => 'Home & Garden',

      // ── Publishing ───────────────────────────────────────────────
      2741 || 2791 || 2842 => 'Stationery & Office',

      // ── Airlines ─────────────────────────────────────────────────
      3000 || 4511 || 4582 => 'Hotels & Travel',

      // ── Car Rental ───────────────────────────────────────────────
      3351 => 'Transport',

      // ── Hotels & Accommodation ───────────────────────────────────
      3501 || 7011 || 7012 || 7032 || 7033 => 'Hotels & Travel',

      // ── Rail & Local Transport ───────────────────────────────────
      4011 || 4111 || 4112 || 4119 || 4121 || 4131 => 'Transport',

      // ── Freight & Courier ────────────────────────────────────────
      4214 || 4215 || 4225 || 4304 => 'Other',

      // ── Cruises & Boats ──────────────────────────────────────────
      4411 || 4457 || 4468 => 'Hotels & Travel',

      // ── Tourism ──────────────────────────────────────────────────
      4722 || 4723 || 4729 => 'Hotels & Travel',

      // ── Roads & Tolls ────────────────────────────────────────────
      4784 || 4789 => 'Transport',

      // ── Telecom & Internet ───────────────────────────────────────
      4812 ||
      4813 ||
      4814 ||
      4815 ||
      4816 ||
      4821 ||
      4899 => 'Utilities & Telecom',

      // ── Money Transfers ──────────────────────────────────────────
      4829 => 'Finance & Insurance',

      // ── Utilities ────────────────────────────────────────────────
      4900 => 'Utilities & Telecom',

      // ── Wholesale / B2B ──────────────────────────────────────────
      5013 ||
      5021 ||
      5039 ||
      5044 ||
      5045 ||
      5046 ||
      5047 ||
      5051 ||
      5065 ||
      5072 ||
      5074 ||
      5085 => 'Other',

      // ── Jewelry & Watches ────────────────────────────────────────
      5094 || 5944 => 'Clothing & Accessories',

      // ── Stationery & Office ──────────────────────────────────────
      5111 || 5943 => 'Stationery & Office',

      // ── Pharmacies ───────────────────────────────────────────────
      5122 || 5912 => 'Pharmacies & Health',

      // ── Textiles & Clothing wholesale ────────────────────────────
      5131 || 5137 || 5139 => 'Clothing & Accessories',

      // ── Fuel / Oil ───────────────────────────────────────────────
      5172 || 5983 => 'Gas Stations',

      // ── Books & Periodicals ──────────────────────────────────────
      5192 || 5942 || 5994 => 'Entertainment',

      // ── Home & Garden wholesale/retail ───────────────────────────
      5193 ||
      5198 ||
      5199 ||
      5200 ||
      5211 ||
      5231 ||
      5251 ||
      5261 ||
      5712 ||
      5713 ||
      5714 ||
      5719 => 'Home & Garden',

      // ── Marketplaces & General Retail ────────────────────────────
      5262 ||
      5271 ||
      5297 ||
      5298 ||
      5300 ||
      5309 ||
      5310 ||
      5311 ||
      5331 ||
      5399 => 'Other',

      // ── Supermarkets & Food ──────────────────────────────────────
      5411 ||
      5412 ||
      5422 ||
      5451 ||
      5462 ||
      5499 ||
      5811 => 'Supermarkets & Food',

      // ── Auto Sales & Parts ───────────────────────────────────────
      5511 ||
      5521 ||
      5531 ||
      5532 ||
      5533 ||
      5551 ||
      5561 ||
      5571 ||
      5592 ||
      5598 ||
      5599 => 'Auto & Vehicles',

      // ── Gas Stations (retail) ────────────────────────────────────
      5541 || 5542 || 9752 => 'Gas Stations',

      // ── EV Charging ──────────────────────────────────────────────
      5552 => 'Auto & Vehicles',

      // ── Clothing & Accessories (retail) ──────────────────────────
      5611 ||
      5621 ||
      5631 ||
      5641 ||
      5651 ||
      5655 ||
      5661 ||
      5681 ||
      5691 ||
      5697 ||
      5698 ||
      5699 => 'Clothing & Accessories',

      // ── Appliances & Electronics ─────────────────────────────────
      5722 || 5732 || 5733 || 5734 || 5735 => 'Electronics',

      // ── Digital Goods ────────────────────────────────────────────
      5815 || 5816 || 5817 || 5818 => 'Entertainment',

      // ── Restaurants & Bars ───────────────────────────────────────
      5812 || 5813 => 'Restaurants & Bars',

      // ── Fast Food ────────────────────────────────────────────────
      5814 => 'Fast Food',

      // ── Liquor, Tobacco, misc food ───────────────────────────────
      5715 || 5718 || 5921 || 5993 => 'Other',

      // ── Second-hand & Pawn ───────────────────────────────────────
      5931 || 5932 || 5933 || 5935 || 5937 => 'Other',

      // ── Sports, Hobbies, Arts ────────────────────────────────────
      5940 ||
      5941 ||
      5945 ||
      5946 ||
      5949 ||
      5950 ||
      5970 ||
      5971 ||
      5972 ||
      5973 => 'Entertainment',

      // ── Gifts & Flowers ──────────────────────────────────────────
      5947 || 5992 => 'Other',

      // ── Leather & Travel Goods ───────────────────────────────────
      5948 => 'Clothing & Accessories',

      // ── Direct Marketing ─────────────────────────────────────────
      5960 ||
      5961 ||
      5962 ||
      5963 ||
      5964 ||
      5965 ||
      5966 ||
      5967 ||
      5968 ||
      5969 => 'Other',

      // ── Optical & Medical Supplies ───────────────────────────────
      5975 || 5976 => 'Pharmacies & Health',

      // ── Cosmetics ────────────────────────────────────────────────
      5977 => 'Beauty & Personal Care',

      // ── Other Retail ─────────────────────────────────────────────
      5978 || 5995 || 5996 || 5997 || 5998 || 5999 => 'Other',

      // ── Finance ──────────────────────────────────────────────────
      6009 ||
      6010 ||
      6011 ||
      6012 ||
      6050 ||
      6051 ||
      6211 ||
      6300 ||
      6381 ||
      6513 ||
      6532 ||
      6533 ||
      6535 ||
      6536 ||
      6537 ||
      6538 ||
      6540 ||
      6611 ||
      6760 => 'Finance & Insurance',

      // ── Personal & Beauty Services ───────────────────────────────
      7210 ||
      7211 ||
      7216 ||
      7217 ||
      7221 ||
      7230 ||
      7251 ||
      7297 ||
      7298 => 'Beauty & Personal Care',

      // ── Misc Personal Services ───────────────────────────────────
      7261 || 7273 || 7276 || 7277 || 7278 || 7296 || 7299 => 'Other',

      // ── Business & IT Services ───────────────────────────────────
      7311 ||
      7321 ||
      7333 ||
      7338 ||
      7339 ||
      7342 ||
      7349 ||
      7361 ||
      7372 ||
      7375 ||
      7379 ||
      7389 ||
      7392 ||
      7393 ||
      7394 ||
      7395 ||
      7399 => 'Other',

      // ── Car Rental & Parking ─────────────────────────────────────
      7512 || 7513 || 7519 || 7523 => 'Transport',

      // ── Auto Repair ──────────────────────────────────────────────
      7531 || 7534 || 7535 || 7538 || 7542 || 7549 => 'Auto & Vehicles',

      // ── Repairs ──────────────────────────────────────────────────
      7622 || 7623 || 7629 || 7631 || 7641 || 7692 || 7699 => 'Other',

      // ── Gambling & Lotteries ─────────────────────────────────────
      7800 ||
      7801 ||
      7802 ||
      7829 ||
      7932 ||
      7933 ||
      7995 ||
      9406 ||
      9754 => 'Entertainment',

      // ── Entertainment & Culture ──────────────────────────────────
      7832 ||
      7841 ||
      7911 ||
      7922 ||
      7929 ||
      7941 ||
      7991 ||
      7992 ||
      7993 ||
      7994 ||
      7996 ||
      7997 ||
      7998 ||
      7999 => 'Entertainment',

      // ── Healthcare ───────────────────────────────────────────────
      8011 ||
      8021 ||
      8031 ||
      8041 ||
      8042 ||
      8043 ||
      8049 ||
      8050 ||
      8062 ||
      8071 ||
      8099 => 'Pharmacies & Health',

      // ── Legal ────────────────────────────────────────────────────
      8111 => 'Other',

      // ── Education ────────────────────────────────────────────────
      8211 || 8220 || 8241 || 8244 || 8249 || 8299 || 8351 => 'Education',

      // ── Charity & Social ─────────────────────────────────────────
      8398 || 8641 || 8651 || 8661 || 8675 || 8699 => 'Charity & Social',

      // ── Professional Services ────────────────────────────────────
      8734 || 8911 || 8931 || 8999 => 'Other',

      // ── Government & Taxes ───────────────────────────────────────
      9211 ||
      9222 ||
      9223 ||
      9311 ||
      9399 ||
      9402 ||
      9405 ||
      9751 => 'Government & Taxes',

      // ── Internal / Intra-company ─────────────────────────────────
      9950 => 'Other',

      _ => null,
    };
  }

  static List<String> allCategories(List<String> customCategories) {
    final set = {...predefinedCategories, ...customCategories};
    final list = set.toList()..sort();
    if (list.remove(fallbackCategory)) list.add(fallbackCategory);
    return list;
  }

  /// Resolves a category for a transaction.
  ///
  /// Priority: mccCode → apiCategory → Other.
  /// [merchName] and [userRules] are accepted for signature compatibility
  /// but are not used — manual overrides are handled via customCategory on the entity.
  static String resolve(
    String? merchName, {
    String? apiCategory,
    String? mccCode,
    List<MerchantCategoryRule> userRules = const [],
  }) {
    if (merchName != null && merchName.trim().isNotEmpty) {
      final lowerName = merchName.toLowerCase();
      for (final rule in userRules) {
        if (rule.pattern.isEmpty) continue;
        final patternLower = rule.pattern.toLowerCase();
        if (rule.exactMatch) {
          if (lowerName == patternLower) return rule.category;
        } else {
          if (lowerName.contains(patternLower)) return rule.category;
        }
      }
    }

    final fromMcc = _categoryFromMcc(mccCode);
    if (fromMcc != null) return fromMcc;

    if (apiCategory != null && apiCategory.trim().isNotEmpty) {
      return apiCategory.trim();
    }

    return fallbackCategory;
  }
}
