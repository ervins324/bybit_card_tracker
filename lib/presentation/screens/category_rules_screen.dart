import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bybit_card_tracker/core/constants/merchant_categories.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';

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
        onPressed: () => _showRuleDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add rule'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text(
            'Assign categories automatically by matching keywords in merchant names.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Your categories',
            action: TextButton.icon(
              onPressed: () => _showAddCategoryDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New category'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: settings.allCategories.map((name) {
              final isCustom = settings.customCategories.contains(name);
              final isPredefined = MerchantCategories.predefinedCategories.contains(name);
              return InputChip(
                label: Text(name),
                deleteIcon: (isCustom && !isPredefined) ? const Icon(Icons.close, size: 16) : null,
                onDeleted: (isCustom && !isPredefined)
                    ? () {
                        final index = settings.customCategories.indexOf(name);
                        if (index >= 0) {
                          ref
                              .read(settingsProvider.notifier)
                              .removeCustomCategoryAt(index);
                        }
                      }
                    : null,
                onPressed: (isCustom && !isPredefined)
                    ? () => _showRenameCategoryDialog(context, name)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Built-in rules'),
          const SizedBox(height: 8),
          ...MerchantCategories.builtInRules.map(
            (rule) => _RuleCard(
              category: rule.category,
              keywords: rule.keywords.join(', '),
              isBuiltIn: true,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Your rules'),
          const SizedBox(height: 8),
          if (settings.categoryRules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No custom rules yet. Tap "Add rule" to create one.',
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            ...settings.categoryRules.asMap().entries.map(
                  (entry) => _RuleCard(
                    category: entry.value.category,
                    keywords: entry.value.keywords.join(', '),
                    onEdit: () => _showRuleDialog(
                      context,
                      index: entry.key,
                      existing: entry.value,
                    ),
                    onDelete: () => ref
                        .read(settingsProvider.notifier)
                        .removeCategoryRuleAt(entry.key),
                  ),
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
              ref.read(settingsProvider.notifier).renameCustomCategory(
                    index,
                    name,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRuleDialog(
    BuildContext context, {
    int? index,
    MerchantCategoryRule? existing,
  }) async {
    final settings = ref.read(settingsProvider);
    final isEditing = existing != null && index != null;

    var category = existing?.category ?? settings.allCategories.first;
    final keywordsController = TextEditingController(
      text: existing?.keywords.join(', ') ?? '',
    );
    final customCategoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text(isEditing ? 'Edit rule' : 'Add rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: settings.allCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Or create new category',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () {
                        final name = customCategoryController.text.trim();
                        if (name.isEmpty) return;
                        ref.read(settingsProvider.notifier).addCustomCategory(
                              name,
                            );
                        setDialogState(() => category = name);
                        customCategoryController.clear();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keywordsController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant keywords',
                    hintText: 'varus, atb, silpo',
                    helperText: 'Comma-separated. Case-insensitive.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final keywords = keywordsController.text
                    .split(',')
                    .map((k) => k.trim().toLowerCase())
                    .where((k) => k.isNotEmpty)
                    .toList();

                if (keywords.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter at least one keyword.'),
                    ),
                  );
                  return;
                }

                final rule = MerchantCategoryRule(
                  category: category,
                  keywords: keywords,
                );

                final notifier = ref.read(settingsProvider.notifier);
                if (isEditing) {
                  notifier.updateCategoryRuleAt(index, rule);
                } else {
                  notifier.addCategoryRule(rule);
                }

                Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    keywordsController.dispose();
    customCategoryController.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        ?action,
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String category;
  final String keywords;
  final bool isBuiltIn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RuleCard({
    required this.category,
    required this.keywords,
    this.isBuiltIn = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(keywords, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (isBuiltIn)
            Text(
              'Built-in',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gold,
                  ),
            )
          else ...[
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppTheme.gold,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppTheme.red,
                onPressed: onDelete,
              ),
          ],
        ],
      ),
    );
  }
}
