import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';

/// Manages custom categories.
///
/// Keyword-based rules are no longer used — categories are resolved from MCC codes.
/// Manual overrides per transaction are still available in the transaction detail screen.
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
}
