// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_type.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/app_logo.dart';
import '../widgets/category_icon_picker_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  final CashBookViewModel viewModel;

  const CategoriesScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddEditCategoryDialog({CategoryModel? categoryToEdit, TransactionType? defaultType}) async {
    final isEditing = categoryToEdit != null;
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    TransactionType type = categoryToEdit?.type ?? defaultType ?? (_tabController.index == 0 ? TransactionType.expense : TransactionType.income);
    int selectedIconCode = categoryToEdit?.iconCodePoint ??
        (type == TransactionType.income ? Icons.account_balance_wallet_rounded.codePoint : Icons.shopping_bag_rounded.codePoint);
    int selectedColor = categoryToEdit?.colorValue ??
        (type == TransactionType.income ? AppConstants.defaultIncomeCategoryColor : AppConstants.defaultExpenseCategoryColor);

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Category' : 'Add Category'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector
                    if (!isEditing) ...[
                      SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.expense,
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_upward_rounded, color: Colors.red),
                          ),
                          ButtonSegment(
                            value: TransactionType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_downward_rounded, color: Colors.green),
                          ),
                        ],
                        selected: {type},
                        onSelectionChanged: (set) {
                          setDialogState(() {
                            type = set.first;
                            if (type == TransactionType.income) {
                              selectedColor = AppConstants.defaultIncomeCategoryColor;
                              selectedIconCode = Icons.account_balance_wallet_rounded.codePoint;
                            } else {
                              selectedColor = AppConstants.defaultExpenseCategoryColor;
                              selectedIconCode = Icons.shopping_bag_rounded.codePoint;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Subscriptions, Freelance',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          color: Color(selectedColor),
                          child: Icon(
                            IconData(selectedIconCode, fontFamily: 'MaterialIcons'),
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.palette_rounded, size: 18),
                          label: const Text('Change Icon/Color'),
                          onPressed: () async {
                            final result = await showDialog<Map<String, int>>(
                              context: context,
                              builder: (_) => CategoryIconPickerDialog(
                                initialIconCode: selectedIconCode,
                                initialColorValue: selectedColor,
                              ),
                            );
                            if (result != null) {
                              setDialogState(() {
                                selectedIconCode = result['iconCode']!;
                                selectedColor = result['colorValue']!;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    if (isEditing) {
                      final updated = categoryToEdit.copyWith(
                        name: name,
                        iconCodePoint: selectedIconCode,
                        colorValue: selectedColor,
                      );
                      await widget.viewModel.updateCategory(updated);
                    } else {
                      final newCat = CategoryModel(
                        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        type: type,
                        iconCodePoint: selectedIconCode,
                        colorValue: selectedColor,
                        isDefault: false,
                      );
                      await widget.viewModel.addCategory(newCat);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(CategoryModel category) async {
    final count = widget.viewModel.getTransactionCountForCategory(category.id);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: Text(
          count > 0
              ? 'This category has $count transaction(s). Deleting it will reassign these transactions to the "Other ${category.type.label}" category.\n\nDo you want to proceed?'
              : 'Are you sure you want to delete this category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await widget.viewModel.deleteCategory(category.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default categories cannot be deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final expenseCategories = widget.viewModel.expenseCategories;
        final incomeCategories = widget.viewModel.incomeCategories;

        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const AppBrandTitle(title: 'Manage Categories'),
            bottom: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  text: 'Expenses (${expenseCategories.length})',
                ),
                Tab(
                  text: 'Income (${incomeCategories.length})',
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'reset') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Categories?'),
                        content: const Text(
                            'This will restore all default categories. Custom categories will be removed.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.viewModel.resetCategoriesToDefaults();
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.restore_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Reset to Defaults'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories, TransactionType.expense),
              _buildCategoryList(incomeCategories, TransactionType.income),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'categories_screen_fab',
            onPressed: () => _openAddEditCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, TransactionType type) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No ${type.label} categories found',
              style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: isDark ? 0.22 : 0.12),
                border: Border.all(color: cat.color.withValues(alpha: isDark ? 0.45 : 0.3)),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            title: Text(
              cat.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cat.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    tooltip: 'Edit Category',
                    onPressed: () => _openAddEditCategoryDialog(categoryToEdit: cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    tooltip: 'Delete Category',
                    onPressed: () => _confirmDeleteCategory(cat),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
