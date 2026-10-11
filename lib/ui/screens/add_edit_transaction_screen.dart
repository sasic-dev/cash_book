// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/app_logo.dart';
import '../widgets/category_icon_picker_dialog.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final CashBookViewModel viewModel;
  final TransactionModel? initialTransaction;
  final TransactionType? initialType;

  const AddEditTransactionScreen({
    super.key,
    required this.viewModel,
    this.initialTransaction,
    this.initialType,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedCategoryId;
  String _selectedPaymentMode = 'Cash';

  final List<String> _paymentModes = const [
    'Cash',
    'Online / UPI',
    'Card',
    'Bank Transfer',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;
    if (tx != null) {
      _type = tx.type;
      _amountController = TextEditingController(
          text: tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 2));
      _titleController = TextEditingController(text: tx.title);
      _selectedDate = tx.date;
      _selectedTime = TimeOfDay.fromDateTime(tx.date);
      _selectedCategoryId = tx.categoryId;
      _selectedPaymentMode = tx.paymentMode;
    } else {
      _type = widget.initialType ?? TransactionType.expense;
      _amountController = TextEditingController();
      _titleController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _setDefaultCategoryForType(_type);
    }
  }

  void _setDefaultCategoryForType(TransactionType type) {
    final available = type == TransactionType.income
        ? widget.viewModel.incomeCategories
        : widget.viewModel.expenseCategories;
    if (available.isNotEmpty) {
      _selectedCategoryId = available.first.id;
    } else {
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<CategoryModel?> _addNewCategoryQuickly() async {
    final nameController = TextEditingController();
    int selectedIconCode = Icons.category_rounded.codePoint;
    int selectedColor = _type == TransactionType.income ? 0xFF2E7D32 : 0xFFE65100;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: Text('New ${_type.label} Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Freelance, Snacks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        color: Color(selectedColor),
                        child: Icon(
                          IconData(selectedIconCode, fontFamily: 'MaterialIcons'),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (created == true && nameController.text.trim().isNotEmpty) {
      final newCat = CategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        type: _type,
        iconCodePoint: selectedIconCode,
        colorValue: selectedColor,
        isDefault: false,
      );
      await widget.viewModel.addCategory(newCat);
      if (mounted) {
        setState(() {
          _selectedCategoryId = newCat.id;
        });
      }
      return newCat;
    }
    return null;
  }

  Future<void> _openCategoryPickerSheet() async {
    final categories = _type == TransactionType.income
        ? widget.viewModel.incomeCategories
        : widget.viewModel.expenseCategories;

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _CategoryPickerBottomSheet(
        type: _type,
        categories: categories,
        selectedCategoryId: _selectedCategoryId,
        onAddNewCategory: () async {
          final newCat = await _addNewCategoryQuickly();
          if (newCat != null && bottomSheetContext.mounted) {
            Navigator.of(bottomSheetContext).pop(newCat.id);
          }
        },
      ),
    );

    if (selectedId != null && mounted) {
      setState(() {
        _selectedCategoryId = selectedId;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final title = _titleController.text.trim();

    if (widget.initialTransaction != null) {
      final updated = widget.initialTransaction!.copyWith(
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId!,
        date: combinedDateTime,
        title: title,
        paymentMode: _selectedPaymentMode,
      );
      await widget.viewModel.updateTransaction(updated);
    } else {
      final newTx = TransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId!,
        date: combinedDateTime,
        title: title,
        paymentMode: _selectedPaymentMode,
      );
      await widget.viewModel.addTransaction(newTx);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialTransaction != null;

    final categories = _type == TransactionType.income
        ? widget.viewModel.incomeCategories
        : widget.viewModel.expenseCategories;

    // Verify currently selected category belongs to current type
    if (_selectedCategoryId != null &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    return Scaffold(
      appBar: AppBar(
        title: AppBrandTitle(
          title: isEditing ? 'Edit Entry' : 'Add Cash Entry',
          logoSize: 24,
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              tooltip: 'Delete Entry',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Entry?'),
                    content: const Text(
                        'Are you sure you want to permanently delete this transaction?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await widget.viewModel
                      .deleteTransaction(widget.initialTransaction!.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Button: Cash In (Income) vs Cash Out (Expense)
              Center(
                child: SegmentedButton<TransactionType>(
                  style: const ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Cash In (+ Income)'),
                      icon: Icon(Icons.arrow_downward_rounded, color: Colors.green),
                    ),
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Cash Out (- Expense)'),
                      icon: Icon(Icons.arrow_upward_rounded, color: Colors.red),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) {
                    setState(() {
                      _type = set.first;
                      _setDefaultCategoryForType(_type);
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Amount Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _type == TransactionType.income
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _type == TransactionType.income
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      AppFormatters.currencySymbol,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _type == TransactionType.income
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        autofocus: !isEditing,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _type == TransactionType.income
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter amount';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter valid amount > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Selector Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewCategoryQuickly,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Category'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category Selector Tile
              Builder(
                builder: (context) {
                  final selectedCategory = categories
                      .where((c) => c.id == _selectedCategoryId)
                      .firstOrNull;

                  return InkWell(
                    onTap: _openCategoryPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: selectedCategory != null
                              ? selectedCategory.color.withValues(alpha: 0.45)
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (selectedCategory != null) ...[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedCategory.color
                                    .withValues(alpha: 0.14),
                                border: Border.all(
                                  color: selectedCategory.color
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(
                                selectedCategory.icon,
                                color: selectedCategory.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedCategory.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _type == TransactionType.income
                                        ? 'Cash In Category'
                                        : 'Cash Out Category',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: const Icon(
                                Icons.category_outlined,
                                color: Color(0xFF94A3B8),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Select a category',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Select',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Color(0xFF334155),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Date and Time Pickers
              Text(
                'Date & Time',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(AppFormatters.date(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(_selectedTime.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Payment Mode Selection
              Text(
                'Payment Mode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _paymentModes.map((mode) {
                    final isSelected = _selectedPaymentMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(mode),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPaymentMode = mode;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Remark / Note Input
              Text(
                'Remark / Note (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Grocery items, Monthly salary, Uber ride',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _type == TransactionType.income
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: _save,
                  child: Text(
                    isEditing ? 'Update Entry' : 'Save Entry',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerBottomSheet extends StatefulWidget {
  final TransactionType type;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final VoidCallback onAddNewCategory;

  const _CategoryPickerBottomSheet({
    required this.type,
    required this.categories,
    required this.selectedCategoryId,
    required this.onAddNewCategory,
  });

  @override
  State<_CategoryPickerBottomSheet> createState() =>
      _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState
    extends State<_CategoryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    final filteredCategories = widget.categories.where((cat) {
      if (_searchQuery.trim().isEmpty) return true;
      return cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.75,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pull Handle
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // Title Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Category',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.type == TransactionType.income
                                  ? 'Cash In (Income) categories'
                                  : 'Cash Out (Expense) categories',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: widget.onAddNewCategory,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search category...',
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),

                // Category List
                Flexible(
                  child: filteredCategories.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.category_outlined,
                                size: 40,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No category found matching "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: widget.onAddNewCategory,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add This Category'),
                                style: OutlinedButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredCategories.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 64,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (ctx, index) {
                            final cat = filteredCategories[index];
                            final isSelected =
                                widget.selectedCategoryId == cat.id;

                            return ListTile(
                              onTap: () {
                                Navigator.of(context).pop(cat.id);
                              },
                              tileColor: isSelected
                                  ? cat.color.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: isSelected
                                        ? cat.color
                                        : cat.color.withValues(alpha: 0.35),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Icon(
                                  cat.icon,
                                  color: cat.color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? cat.color
                                      : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: cat.color,
                                      size: 22,
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
