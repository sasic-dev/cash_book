import 'package:flutter/material.dart';
import '../../data/models/person_model.dart';
import '../../data/models/split_expense_model.dart';
import '../../data/models/split_group_model.dart';
import '../../data/services/split_strategy.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/add_edit_person_dialog.dart';
import '../widgets/app_logo.dart';

class AddEditSplitExpenseScreen extends StatefulWidget {
  final CashBookViewModel viewModel;
  final SplitExpenseModel? initialExpense;
  final String? preselectedGroupId;
  final String? preselectedPersonId;

  const AddEditSplitExpenseScreen({
    super.key,
    required this.viewModel,
    this.initialExpense,
    this.preselectedGroupId,
    this.preselectedPersonId,
  });

  @override
  State<AddEditSplitExpenseScreen> createState() => _AddEditSplitExpenseScreenState();
}

class _AddEditSplitExpenseScreenState extends State<AddEditSplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late DateTime _date;
  String? _selectedGroupId;
  String? _selectedCategoryId;
  late String _paidById;
  int _splitModeIndex = 0; // 0 = Equal, 1 = Exact, 2 = Percentage
  bool _syncToCashBook = true;

  // Selected participant IDs for split
  late Set<String> _selectedParticipants;

  // Custom amounts controllers for Exact & Percentage modes
  final Map<String, TextEditingController> _customInputControllers = {};

  @override
  void initState() {
    super.initState();
    final exp = widget.initialExpense;
    final currentUserId = widget.viewModel.currentUser.id;

    final displayTotal = exp != null ? AppFormatters.toDisplayAmount(exp.totalAmount) : null;
    _titleController = TextEditingController(text: exp?.title ?? '');
    _amountController = TextEditingController(
      text: displayTotal != null ? displayTotal.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: exp?.notes ?? '');
    _date = exp?.date ?? DateTime.now();

    final validGroupIds = widget.viewModel.groups.map((g) => g.id).toSet();
    final requestedGroupId = exp?.groupId ?? widget.preselectedGroupId;
    _selectedGroupId = (requestedGroupId != null && validGroupIds.contains(requestedGroupId))
        ? requestedGroupId
        : null;

    _selectedCategoryId = exp?.categoryId ??
        (widget.viewModel.expenseCategories.isNotEmpty
            ? widget.viewModel.expenseCategories.first.id
            : 'exp_food');

    final validPersonIds = widget.viewModel.people.map((p) => p.id).toSet();
    final requestedPaidById = exp?.paidByPersonId ?? currentUserId;
    _paidById = validPersonIds.contains(requestedPaidById) ? requestedPaidById : currentUserId;

    if (exp != null) {
      if (exp.splitType == 'exact') {
        _splitModeIndex = 1;
      } else if (exp.splitType == 'percentage') {
        _splitModeIndex = 2;
      } else {
        _splitModeIndex = 0;
      }
      _selectedParticipants = exp.splits
          .map((s) => s.personId)
          .where((pId) => validPersonIds.contains(pId))
          .toSet();
      if (_selectedParticipants.isEmpty) {
        _selectedParticipants = {currentUserId};
      }
      _syncToCashBook = exp.linkedCashBookTxId != null;

      for (final s in exp.splits) {
        if (_splitModeIndex == 1) {
          final displaySplitAmt = AppFormatters.toDisplayAmount(s.amount);
          _customInputControllers[s.personId] =
              TextEditingController(text: displaySplitAmt.toStringAsFixed(2));
        } else if (_splitModeIndex == 2) {
          _customInputControllers[s.personId] = TextEditingController(
            text: s.percentage != null ? s.percentage!.toStringAsFixed(1) : '',
          );
        }
      }
    } else {
      _splitModeIndex = 0;
      // Default participants: if group selected, use group members, else all people
      if (_selectedGroupId != null) {
        final grp = widget.viewModel.getGroupById(_selectedGroupId!);
        _selectedParticipants = Set.from(grp?.memberIds ?? [currentUserId]);
      } else if (widget.preselectedPersonId != null) {
        _selectedParticipants = {currentUserId, widget.preselectedPersonId!};
      } else {
        _selectedParticipants = widget.viewModel.people.map((p) => p.id).toSet();
      }
    }

    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final c in _customInputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<PersonModel> get _availablePeople {
    if (_selectedGroupId != null) {
      final grp = widget.viewModel.getGroupById(_selectedGroupId!);
      if (grp != null) {
        return widget.viewModel.people
            .where((p) => grp.memberIds.contains(p.id))
            .toList();
      }
    }
    return widget.viewModel.people;
  }

  void _onGroupChanged(String? newGroupId) {
    setState(() {
      _selectedGroupId = newGroupId;
      if (newGroupId != null) {
        final grp = widget.viewModel.getGroupById(newGroupId);
        if (grp != null) {
          _selectedParticipants = Set.from(grp.memberIds);
          if (!grp.memberIds.contains(_paidById)) {
            _paidById = grp.memberIds.first;
          }
        }
      } else {
        _selectedParticipants = widget.viewModel.people.map((p) => p.id).toSet();
      }
    });
  }

  Future<void> _openPaidByPickerSheet(List<PersonModel> available) async {
    final pickedPersonId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _PaidByPickerBottomSheet(
        viewModel: widget.viewModel,
        availablePeople: available,
        selectedPersonId: _paidById,
        onAddNewPerson: () async {
          Navigator.of(bottomSheetContext).pop();
          final newPerson = await AddEditPersonDialog.show(context, viewModel: widget.viewModel);
          if (newPerson != null && mounted) {
            if (_selectedGroupId != null) {
              final grp = widget.viewModel.getGroupById(_selectedGroupId!);
              if (grp != null && !grp.memberIds.contains(newPerson.id)) {
                final updatedMemberIds = List<String>.from(grp.memberIds)..add(newPerson.id);
                final updatedGroup = SplitGroupModel(
                  id: grp.id,
                  name: grp.name,
                  iconCodePoint: grp.iconCodePoint,
                  colorValue: grp.colorValue,
                  memberIds: updatedMemberIds,
                  createdAt: grp.createdAt,
                );
                await widget.viewModel.updateGroup(updatedGroup);
              }
            }
            setState(() {
              _paidById = newPerson.id;
              _selectedParticipants.add(newPerson.id);
            });
          }
        },
      ),
    );

    if (pickedPersonId != null && mounted) {
      setState(() {
        _paidById = pickedPersonId;
        _selectedParticipants.add(pickedPersonId);
      });
    }
  }

  void _saveExpense() async {
    if (widget.initialExpense != null &&
        !AppFormatters.isCurrentMonth(widget.initialExpense!.date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit split expenses from past months.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final enteredTotalAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (enteredTotalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    if (widget.initialExpense != null &&
        !AppFormatters.isCurrentMonth(_date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot change split expense date to a different month.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one person to split with')),
      );
      return;
    }

    final totalAmount = AppFormatters.fromDisplayAmount(enteredTotalAmount);
    final splitTypeStr = _splitModeIndex == 0
        ? 'equal'
        : (_splitModeIndex == 1 ? 'exact' : 'percentage');
    final strategy = SplitStrategyRegistry.getStrategy(splitTypeStr);

    final Map<String, double> customInputs = {};
    for (final pId in _selectedParticipants) {
      final ctrl = _customInputControllers[pId];
      final val = double.tryParse(ctrl?.text.trim() ?? '') ?? 0.0;
      if (_splitModeIndex == 1) {
        customInputs[pId] = AppFormatters.fromDisplayAmount(val);
      } else {
        customInputs[pId] = val;
      }
    }

    final validationError = strategy.validate(
      totalAmount: totalAmount,
      participantIds: _selectedParticipants.toList(),
      customInputs: customInputs,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final splits = strategy.calculateSplits(
      totalAmount: totalAmount,
      participantIds: _selectedParticipants.toList(),
      customInputs: customInputs,
    );

    final isEditing = widget.initialExpense != null;
    final expense = SplitExpenseModel(
      id: widget.initialExpense?.id ?? 'exp_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      totalAmount: totalAmount,
      baseInrAmount: totalAmount,
      date: _date,
      paidByPersonId: _paidById,
      groupId: _selectedGroupId,
      categoryId: _selectedCategoryId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      splitType: splitTypeStr,
      splits: splits,
      linkedCashBookTxId: widget.initialExpense?.linkedCashBookTxId,
      createdAt: widget.initialExpense?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      final success = await widget.viewModel.updateSplitExpense(
        expense,
        syncToCashBook: _syncToCashBook,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update: split expenses outside current month cannot be modified.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      await widget.viewModel.addSplitExpense(
        expense,
        syncToCashBook: _syncToCashBook,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Expense updated' : 'Expense split created',
          ),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialExpense != null;
    final isCurrentMonth = widget.initialExpense == null ||
        AppFormatters.isCurrentMonth(widget.initialExpense!.date);
    final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final available = _availablePeople;

    return Scaffold(
      appBar: AppBar(
        title: AppBrandTitle(
          title: isEditing
              ? (isCurrentMonth ? 'Edit Split Expense' : 'View Split Expense (Locked)')
              : 'New Split Expense',
          logoSize: 24,
        ),
        actions: [
          if (isEditing && isCurrentMonth)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Split Expense',
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Split Expense?'),
                    content: const Text('Are you sure you want to remove this split expense?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await widget.viewModel.deleteSplitExpense(widget.initialExpense!.id);
                  nav.pop();
                }
              },
            )
          else if (isEditing && !isCurrentMonth)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Past Month Record (Read-Only)',
                child: Icon(
                  Icons.lock_rounded,
                  color: isDark ? const Color(0xFFFACC15) : const Color(0xFFD97706),
                  size: 22,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            if (!isCurrentMonth) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF332A15) : const Color(0xFFFEF9C3),
                  border: Border.all(
                    color: isDark ? const Color(0xFF854D0E) : const Color(0xFFFDE047),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFFFACC15) : const Color(0xFF854D0E),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Past Month Record (Read-Only)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFEF08A) : const Color(0xFF713F12),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Editing and deleting are only permitted for current month data. This split expense cannot be modified.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF854D0E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Amount Input Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Text(
                    'TOTAL AMOUNT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    readOnly: !isCurrentMonth,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    autofocus: !isEditing,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '${AppFormatters.currencySymbol} ',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Enter valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              readOnly: !isCurrentMonth,
              decoration: const InputDecoration(
                labelText: 'Expense Description',
                hintText: 'e.g. Dinner at Olive, Grocery items',
                prefixIcon: Icon(Icons.receipt_long_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Please enter description'
                  : null,
            ),
            const SizedBox(height: 16),

            // Group selector (Full width to avoid horizontal overflow)
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: (_selectedGroupId != null &&
                      widget.viewModel.groups.any((g) => g.id == _selectedGroupId))
                  ? _selectedGroupId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Group (Optional)',
                prefixIcon: Icon(Icons.groups_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No Group (Direct Split)', overflow: TextOverflow.ellipsis),
                ),
                ...widget.viewModel.groups.map((g) {
                  return DropdownMenuItem<String?>(
                    value: g.id,
                    child: Text(g.name, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: isCurrentMonth ? _onGroupChanged : null,
            ),
            const SizedBox(height: 16),

            // Date picker (Full width)
            InkWell(
              onTap: isCurrentMonth
                  ? () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    }
                  : null,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Text(
                  AppFormatters.date(_date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Paid By Section Header & Selector
            Text(
              'Paid By',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Paid By Selector Tile
            Builder(
              builder: (context) {
                final payer = widget.viewModel.getPersonById(_paidById) ??
                    (available.isNotEmpty ? available.first : widget.viewModel.currentUser);
                final isYou = payer.id == widget.viewModel.currentUser.id;

                return InkWell(
                  onTap: isCurrentMonth ? () => _openPaidByPickerSheet(available) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : payer.color.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          color: payer.color,
                          alignment: Alignment.center,
                          child: Text(
                            payer.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      payer.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isYou) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF312E81)
                                            : const Color(0xFFE0E7FF),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF4338CA)
                                              : const Color(0xFFC7D2FE),
                                        ),
                                      ),
                                      child: Text(
                                        'You',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFFA5B4FC)
                                              : const Color(0xFF3730A3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Paid full amount for this expense',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentMonth)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Select',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFF0F172A),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              border: Border.all(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Locked',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                  ),
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
            const SizedBox(height: 20),

            // Split Mode Tabs
            Text(
              'Split Mode',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              style: const ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
              segments: [
                const ButtonSegment(value: 0, label: Text('Equally (=)')),
                ButtonSegment(value: 1, label: Text('Exact (${AppFormatters.currencySymbol})')),
                const ButtonSegment(value: 2, label: Text('Percent (%)')),
              ],
              selected: {_splitModeIndex},
              onSelectionChanged: isCurrentMonth
                  ? (setVal) {
                      setState(() {
                        _splitModeIndex = setVal.first;
                        // Auto-fill initial values for exact/percentage if blank
                        if (_splitModeIndex == 1 && totalAmount > 0) {
                          final share = totalAmount / (_selectedParticipants.isEmpty ? 1 : _selectedParticipants.length);
                          for (final pId in _selectedParticipants) {
                            _customInputControllers.putIfAbsent(
                              pId,
                              () => TextEditingController(text: share.toStringAsFixed(2)),
                            );
                          }
                        } else if (_splitModeIndex == 2) {
                          final pct = 100.0 / (_selectedParticipants.isEmpty ? 1 : _selectedParticipants.length);
                          for (final pId in _selectedParticipants) {
                            _customInputControllers.putIfAbsent(
                              pId,
                              () => TextEditingController(text: pct.toStringAsFixed(1)),
                            );
                          }
                        }
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),

            // Participants List & Shares
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Split Between (${_selectedParticipants.length} people)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrentMonth)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedParticipants.length == available.length) {
                          // Keep at least 1
                          _selectedParticipants = {_paidById};
                        } else {
                          _selectedParticipants = available.map((p) => p.id).toSet();
                        }
                      });
                    },
                    child: Text(_selectedParticipants.length == available.length
                        ? 'Deselect All'
                        : 'Select All'),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Participant Rows
            ...available.map((person) {
              final isSelected = _selectedParticipants.contains(person.id);
              final ctrl = _customInputControllers.putIfAbsent(
                person.id,
                () => TextEditingController(),
              );

              double calculatedShare = 0.0;
              if (isSelected && totalAmount > 0) {
                if (_splitModeIndex == 0) {
                  calculatedShare = totalAmount / _selectedParticipants.length;
                } else if (_splitModeIndex == 1) {
                  calculatedShare = double.tryParse(ctrl.text.trim()) ?? 0.0;
                } else {
                  final pct = double.tryParse(ctrl.text.trim()) ?? 0.0;
                  calculatedShare = (pct / 100) * totalAmount;
                }
              }

              return Card(
                elevation: 1,
                shadowColor: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.08),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: isCurrentMonth
                            ? (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedParticipants.add(person.id);
                                  } else {
                                    if (_selectedParticipants.length > 1) {
                                      _selectedParticipants.remove(person.id);
                                    }
                                  }
                                });
                              }
                            : null,
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        color: person.color,
                        alignment: Alignment.center,
                        child: Text(
                          person.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          person.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (_splitModeIndex == 0) ...[
                        // Equal mode: display computed share
                        if (isSelected)
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                AppFormatters.currency(calculatedShare, convertFromBase: false),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                        else
                          const Text(
                            'Excluded',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                      ] else if (_splitModeIndex == 1) ...[
                        // Exact mode: input field
                        if (isSelected)
                          SizedBox(
                            width: 88,
                            child: TextField(
                              controller: ctrl,
                              readOnly: !isCurrentMonth,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixText: '${AppFormatters.currencySymbol} ',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          )
                        else
                          const Text('Excluded', style: TextStyle(color: Colors.grey)),
                      ] else ...[
                        // Percentage mode: input field
                        if (isSelected)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 58,
                                child: TextField(
                                  controller: ctrl,
                                  readOnly: !isCurrentMonth,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    suffixText: '%',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 75),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    AppFormatters.currency(calculatedShare, convertFromBase: false),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          const Text('Excluded', style: TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Cash Book sync toggle wrapped in Material
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _syncToCashBook,
                title: const Text('Record in my Cash Book'),
                subtitle: Text(
                  _paidById == widget.viewModel.currentUser.id
                      ? 'Logs ${AppFormatters.currency(totalAmount, convertFromBase: false)} as an Expense in Cash Book'
                      : 'Only available when paid by You',
                  style: theme.textTheme.bodySmall,
                ),
                onChanged: isCurrentMonth && _paidById == widget.viewModel.currentUser.id
                    ? (val) => setState(() => _syncToCashBook = val)
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              readOnly: !isCurrentMonth,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            if (isCurrentMonth)
              FilledButton.icon(
                onPressed: _saveExpense,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isEditing ? 'Update Split Expense' : 'Save Split Expense',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else
              FilledButton.icon(
                onPressed: null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : Colors.grey.shade400,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.lock_rounded, size: 18),
                label: const Text(
                  'Locked — Past Month Record',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaidByPickerBottomSheet extends StatefulWidget {
  final CashBookViewModel viewModel;
  final List<PersonModel> availablePeople;
  final String selectedPersonId;
  final VoidCallback onAddNewPerson;

  const _PaidByPickerBottomSheet({
    required this.viewModel,
    required this.availablePeople,
    required this.selectedPersonId,
    required this.onAddNewPerson,
  });

  @override
  State<_PaidByPickerBottomSheet> createState() => _PaidByPickerBottomSheetState();
}

class _PaidByPickerBottomSheetState extends State<_PaidByPickerBottomSheet> {
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

    final filteredPeople = widget.availablePeople.where((p) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          (p.phoneNumber?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
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
                // Pull handle
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
                              'Paid By',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select who paid the upfront expense',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: widget.onAddNewPerson,
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text(
                          '+ Friend',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
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
                      hintText: 'Search person...',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),

                // People List
                Flexible(
                  child: filteredPeople.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_search_rounded,
                                size: 40,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No person found matching "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: widget.onAddNewPerson,
                                icon: const Icon(Icons.person_add_rounded, size: 16),
                                label: const Text('Add New Friend'),
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
                          itemCount: filteredPeople.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 64,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (ctx, index) {
                            final person = filteredPeople[index];
                            final isSelected = widget.selectedPersonId == person.id;
                            final isYou = person.id == widget.viewModel.currentUser.id;

                            return ListTile(
                              onTap: () {
                                Navigator.of(context).pop(person.id);
                              },
                              tileColor: isSelected
                                  ? person.color.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              leading: Container(
                                width: 38,
                                height: 38,
                                color: person.color,
                                alignment: Alignment.center,
                                child: Text(
                                  person.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      person.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isYou) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF312E81)
                                            : const Color(0xFFE0E7FF),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF4338CA)
                                              : const Color(0xFFC7D2FE),
                                        ),
                                      ),
                                      child: Text(
                                        'You',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFFA5B4FC)
                                              : const Color(0xFF3730A3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: person.phoneNumber != null && person.phoneNumber!.isNotEmpty
                                  ? Text(
                                      person.phoneNumber!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : null,
                                      ),
                                    )
                                  : null,
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
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
