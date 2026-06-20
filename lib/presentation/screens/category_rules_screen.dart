import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/core/constants/merchant_categories.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';

/// Manages custom categories and merchant rules.
///
/// Custom rules apply categorization automatically based on merchant name patterns.
class CategoryRulesScreen extends ConsumerStatefulWidget {
  const CategoryRulesScreen({super.key});

  @override
  ConsumerState<CategoryRulesScreen> createState() =>
      _CategoryRulesScreenState();
}

class _CategoryRulesScreenState extends ConsumerState<CategoryRulesScreen> {
  final _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text(
            'Categories are assigned automatically from the MCC code on each transaction. '
            'You can add custom categories and assign them manually per transaction.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('All categories', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: settings.allCategories.map((name) {
              final isCustom = settings.customCategories.contains(name);
              return InputChip(
                label: Text(name),
                deleteIcon: isCustom ? const Icon(Icons.close, size: 16) : null,
                onDeleted: isCustom
                    ? () {
                        final index = settings.customCategories.indexOf(name);
                        if (index >= 0) {
                          ref
                              .read(settingsProvider.notifier)
                              .removeCustomCategoryAt(index);
                        }
                      }
                    : null,
                onPressed: isCustom
                    ? () => _showRenameCategoryDialog(context, name)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap a custom category to rename it. Built-in categories cannot be edited.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text('Merchant Rules', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Rules automatically categorize transactions based on merchant names.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () => _showRuleDialog(context, null, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Rule'),
            ),
          ),
          const SizedBox(height: 16),
          if (settings.categoryRules.isEmpty)
             Text('No rules defined.', style: theme.textTheme.bodySmall)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settings.categoryRules.length,
              itemBuilder: (ctx, i) {
                final rule = settings.categoryRules[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(rule.pattern, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${rule.category} • ${rule.exactMatch ? "Exact" : "Partial"} Match'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _showRuleDialog(context, rule, i),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_rounded, size: 20, color: AppTheme.red),
                        onPressed: () => ref.read(settingsProvider.notifier).removeCategoryRuleAt(i),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    _newCategoryController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('New category'),
        content: TextField(
          controller: _newCategoryController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'Online shopping',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _newCategoryController.text.trim();
              if (name.isEmpty) return;
              ref.read(settingsProvider.notifier).addCustomCategory(name);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final settings = ref.read(settingsProvider);
    final index = settings.customCategories.indexOf(currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Rename category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty || index < 0) return;
              ref
                  .read(settingsProvider.notifier)
                  .renameCustomCategory(index, name);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRuleDialog(BuildContext context, MerchantCategoryRule? existingRule, int? index) {
    final patternController = TextEditingController(text: existingRule?.pattern ?? '');
    final settings = ref.read(settingsProvider);
    String selectedCategory = existingRule?.category ?? settings.allCategories.first;
    bool exactMatch = existingRule?.exactMatch ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text(existingRule == null ? 'New Rule' : 'Edit Rule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: patternController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Merchant name pattern'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Assign Category'),
                    items: settings.allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedCategory = val);
                    },
                  ),
                  DropdownButtonFormField<bool>(
                    initialValue: exactMatch,
                    decoration: const InputDecoration(labelText: 'Match Type'),
                    items: const [
                      DropdownMenuItem(
                        value: false,
                        child: Text('Partial Match (Contains)'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Exact Match'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => exactMatch = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final pattern = patternController.text.trim();
                    if (pattern.isEmpty) return;
                    final rule = MerchantCategoryRule(
                      category: selectedCategory,
                      pattern: pattern,
                      exactMatch: exactMatch,
                    );
                    if (existingRule == null) {
                      ref.read(settingsProvider.notifier).addCategoryRule(rule);
                    } else if (index != null) {
                      ref.read(settingsProvider.notifier).updateCategoryRuleAt(index, rule);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
