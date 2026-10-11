import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/add_edit_group_dialog.dart';
import '../widgets/settle_up_dialog.dart';
import 'add_edit_split_expense_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final CashBookViewModel viewModel;
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.viewModel,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final group = viewModel.getGroupById(groupId);
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Details')),
            body: const Center(child: Text('Group not found')),
          );
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final currentUserId = viewModel.currentUser.id;

        // Group expenses
        final expenses = viewModel.splitExpenses
            .where((e) => e.groupId == group.id)
            .toList();

        final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.totalAmount);

        // Group simplified debts
        final debts = viewModel.getGroupSimplifiedDebts(group.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  AddEditGroupDialog.show(
                    context,
                    viewModel: viewModel,
                    initialGroup: group,
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // Group Banner Card
              Card(
                elevation: 2,
                shadowColor: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.08),
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            color: group.color,
                            alignment: Alignment.center,
                            child: Icon(group.icon, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (group.description != null)
                                  Text(
                                    group.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL SPENT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.1,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppFormatters.currency(totalSpent),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Members Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: group.memberIds.map((mId) {
                          final person = viewModel.getPersonById(mId);
                          if (person == null) return const SizedBox();
                          return Chip(
                            avatar: Container(
                              width: 20,
                              height: 20,
                              color: person.color,
                              alignment: Alignment.center,
                              child: Text(
                                person.initials,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            label: Text(person.name),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Smart Settlement / Who owes Whom
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Smart Settlement Plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (debts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${debts.length} payment(s) to settle all',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              if (debts.isEmpty)
                Card(
                  elevation: 1,
                  shadowColor: const Color(0x1415803D),
                  color: isDark
                      ? const Color(0xFF14532D).withValues(alpha: 0.35)
                      : const Color(0xFFF0FDF4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                          : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: isDark ? const Color(0xFF4ADE80) : Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Everyone is all settled up in this group!',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF4ADE80) : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...debts.map((debt) {
                  final from = viewModel.getPersonById(debt.fromPersonId);
                  final to = viewModel.getPersonById(debt.toPersonId);
                  final isYouFrom = debt.fromPersonId == currentUserId;
                  final isYouTo = debt.toPersonId == currentUserId;

                  return Card(
                    elevation: 1.5,
                    shadowColor: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.08),
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            color: from?.color ?? Colors.grey,
                            alignment: Alignment.center,
                            child: Text(
                              from?.initials ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: isYouFrom ? 'You' : (from?.name ?? 'Someone'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: ' owes '),
                                  TextSpan(
                                    text: isYouTo ? 'You' : (to?.name ?? 'Someone'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: AppFormatters.currency(debt.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isYouFrom
                                          ? (isDark ? const Color(0xFFF87171) : Colors.red.shade700)
                                          : (isDark ? const Color(0xFF4ADE80) : Colors.green.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            onPressed: () {
                              SettleUpDialog.show(
                                context,
                                viewModel: viewModel,
                                groupId: group.id,
                                initialPayerId: debt.fromPersonId,
                                initialReceiverId: debt.toPersonId,
                                suggestedAmount: debt.amount,
                              );
                            },
                            child: const Text('Settle'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Group Expenses List
              Text(
                'Group Expenses (${expenses.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (expenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No expenses in this group yet',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...expenses.map((exp) {
                  final payer = viewModel.getPersonById(exp.paidByPersonId);
                  final youPaid = exp.paidByPersonId == currentUserId;

                  return Card(
                    elevation: 1.5,
                    shadowColor: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.08),
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditSplitExpenseScreen(
                              viewModel: viewModel,
                              initialExpense: exp,
                            ),
                          ),
                        );
                      },
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 1.0),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.receipt_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        exp.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${AppFormatters.date(exp.date)} • Paid by ${youPaid ? "You" : (payer?.name ?? 'Friend')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : null,
                        ),
                      ),
                      trailing: Text(
                        AppFormatters.currency(exp.totalAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditSplitExpenseScreen(
                    viewModel: viewModel,
                    preselectedGroupId: group.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        );
      },
    );
  }
}
