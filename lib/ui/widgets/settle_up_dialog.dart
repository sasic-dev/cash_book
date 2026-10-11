import 'package:flutter/material.dart';
import '../../data/models/settlement_model.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';

class SettleUpDialog extends StatefulWidget {
  final CashBookViewModel viewModel;
  final String? initialPayerId;
  final String? initialReceiverId;
  final double? suggestedAmount;
  final String? groupId;

  const SettleUpDialog({
    super.key,
    required this.viewModel,
    this.initialPayerId,
    this.initialReceiverId,
    this.suggestedAmount,
    this.groupId,
  });

  static Future<void> show(
    BuildContext context, {
    required CashBookViewModel viewModel,
    String? initialPayerId,
    String? initialReceiverId,
    double? suggestedAmount,
    String? groupId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettleUpDialog(
        viewModel: viewModel,
        initialPayerId: initialPayerId,
        initialReceiverId: initialReceiverId,
        suggestedAmount: suggestedAmount,
        groupId: groupId,
      ),
    );
  }

  @override
  State<SettleUpDialog> createState() => _SettleUpDialogState();
}

class _SettleUpDialogState extends State<SettleUpDialog> {
  late String _payerId;
  late String _receiverId;
  late TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  String _paymentMethod = 'UPI';
  bool _syncToCashBook = true;

  final List<String> _paymentMethods = ['UPI', 'Cash', 'Bank Transfer', 'Other'];

  @override
  void initState() {
    super.initState();
    final currentUserId = widget.viewModel.currentUser.id;
    final otherPeople = widget.viewModel.people.where((p) => !p.isCurrentUser).toList();
    final defaultOtherId = otherPeople.isNotEmpty ? otherPeople.first.id : currentUserId;

    _payerId = widget.initialPayerId ?? defaultOtherId;
    _receiverId = widget.initialReceiverId ?? currentUserId;

    final initialAmount = widget.suggestedAmount != null && widget.suggestedAmount! > 0
        ? widget.suggestedAmount!.toStringAsFixed(2)
        : '';
    _amountController = TextEditingController(text: initialAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveSettlement() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    if (_payerId == _receiverId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payer and receiver cannot be the same person')),
      );
      return;
    }

    final settlement = SettlementModel(
      id: 'settle_${DateTime.now().millisecondsSinceEpoch}',
      payerId: _payerId,
      receiverId: _receiverId,
      amount: amount,
      date: _date,
      groupId: widget.groupId,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    widget.viewModel.addSettlement(
      settlement,
      syncToCashBook: _syncToCashBook,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Settled ${AppFormatters.currency(amount)} successfully',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final people = widget.viewModel.people;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14532D).withValues(alpha: 0.35)
                        : Colors.green.withValues(alpha: 0.12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                          : Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.handshake_rounded,
                    color: isDark ? const Color(0xFF4ADE80) : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Record Settlement',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Payer & Receiver Selector Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Payer (Paid Money):',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _payerId,
                        underline: const SizedBox(),
                        items: people.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  color: p.color,
                                  alignment: Alignment.center,
                                  child: Text(
                                    p.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(p.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _payerId = val);
                        },
                      ),
                    ],
                  ),
                  Divider(
                    height: 20,
                    color: isDark ? const Color(0xFF334155) : null,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Receiver (Got Money):',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _receiverId,
                        underline: const SizedBox(),
                        items: people.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  color: p.color,
                                  alignment: Alignment.center,
                                  child: Text(
                                    p.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(p.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _receiverId = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              decoration: InputDecoration(
                labelText: 'Amount Settled',
                prefixText: '${AppFormatters.currencySymbol} ',
                prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method & Date
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Mode',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: _paymentMethods.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        AppFormatters.date(_date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'e.g. Paid via GPay',
                prefixIcon: Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sync to Cash Book toggle
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _syncToCashBook,
                title: const Text('Record in my Cash Book'),
                subtitle: Text(
                  _receiverId == widget.viewModel.currentUser.id
                      ? 'Adds an Income entry in your Cash Book'
                      : 'Adds an Expense entry in your Cash Book',
                  style: theme.textTheme.bodySmall,
                ),
                onChanged: (val) {
                  setState(() => _syncToCashBook = val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Action Button
            FilledButton.icon(
              onPressed: _saveSettlement,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                backgroundColor: Colors.green.shade700,
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text(
                'Confirm Settlement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
