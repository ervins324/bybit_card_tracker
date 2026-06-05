import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:bybit_card_tracker/core/constants/merchant_categories.dart';

/// Application settings (currency toggle, exchange rate, category rules).
class AppSettings {
  final bool showInUah;
  final double exchangeRate;
  final List<MerchantCategoryRule> categoryRules;
  final List<String> customCategories;

  const AppSettings({
    this.showInUah = false,
    this.exchangeRate = 41.0,
    this.categoryRules = const [],
    this.customCategories = const [],
  });

  AppSettings copyWith({
    bool? showInUah,
    double? exchangeRate,
    List<MerchantCategoryRule>? categoryRules,
    List<String>? customCategories,
  }) {
    return AppSettings(
      showInUah: showInUah ?? this.showInUah,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      categoryRules: categoryRules ?? this.categoryRules,
      customCategories: customCategories ?? this.customCategories,
    );
  }

  List<String> get allCategories =>
      MerchantCategories.allCategories(customCategories);
}

// ── Hive keys ────────────────────────────────────────────────────────────
const _kBoxName = 'settings';
const _kShowInUah = 'show_in_uah';
const _kExchangeRate = 'exchange_rate';
const _kCategoryRules = 'category_rules';
const _kCustomCategories = 'custom_categories';

/// Provider for the settings notifier.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Manages persistent user preferences via a Hive settings box.
class SettingsNotifier extends Notifier<AppSettings> {
  late final Box _box;

  @override
  AppSettings build() {
    _box = Hive.box(_kBoxName);
    final rawRules = _box.get(_kCategoryRules) as List?;
    final rawCategories = _box.get(_kCustomCategories) as List?;
    return AppSettings(
      showInUah: _box.get(_kShowInUah, defaultValue: false) as bool,
      exchangeRate:
          (_box.get(_kExchangeRate, defaultValue: 41.0) as num).toDouble(),
      categoryRules: rawRules
              ?.whereType<Map>()
              .map(MerchantCategoryRule.fromMap)
              .toList() ??
          const [],
      customCategories: rawCategories
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  void toggleCurrency() {
    final newValue = !state.showInUah;
    _box.put(_kShowInUah, newValue);
    state = state.copyWith(showInUah: newValue);
  }

  void setExchangeRate(double rate) {
    _box.put(_kExchangeRate, rate);
    state = state.copyWith(exchangeRate: rate);
  }

  void addCategoryRule(MerchantCategoryRule rule) {
    final updated = [...state.categoryRules, rule];
    _persistCategoryRules(updated);
  }

  void updateCategoryRuleAt(int index, MerchantCategoryRule rule) {
    final updated = [...state.categoryRules];
    updated[index] = rule;
    _persistCategoryRules(updated);
  }

  void removeCategoryRuleAt(int index) {
    final updated = [...state.categoryRules]..removeAt(index);
    _persistCategoryRules(updated);
  }

  void addCustomCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.allCategories
        .any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    final updated = [...state.customCategories, trimmed];
    _persistCustomCategories(updated);
  }

  void renameCustomCategory(int index, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || index >= state.customCategories.length) return;

    final oldName = state.customCategories[index];
    final updatedCategories = [...state.customCategories];
    updatedCategories[index] = trimmed;

    final updatedRules = state.categoryRules
        .map(
          (rule) => rule.category == oldName
              ? rule.copyWith(category: trimmed)
              : rule,
        )
        .toList();

    _box.put(_kCustomCategories, updatedCategories);
    _box.put(_kCategoryRules, updatedRules.map((r) => r.toMap()).toList());
    state = state.copyWith(
      customCategories: updatedCategories,
      categoryRules: updatedRules,
    );
  }

  void removeCustomCategoryAt(int index) {
    if (index >= state.customCategories.length) return;
    final removed = state.customCategories[index];
    final updatedCategories = [...state.customCategories]..removeAt(index);
    final updatedRules = state.categoryRules
        .where((rule) => rule.category != removed)
        .toList();

    _box.put(_kCustomCategories, updatedCategories);
    _box.put(_kCategoryRules, updatedRules.map((r) => r.toMap()).toList());
    state = state.copyWith(
      customCategories: updatedCategories,
      categoryRules: updatedRules,
    );
  }

  void _persistCategoryRules(List<MerchantCategoryRule> rules) {
    _box.put(_kCategoryRules, rules.map((r) => r.toMap()).toList());
    state = state.copyWith(categoryRules: rules);
  }

  void _persistCustomCategories(List<String> categories) {
    _box.put(_kCustomCategories, categories);
    state = state.copyWith(customCategories: categories);
  }
}
