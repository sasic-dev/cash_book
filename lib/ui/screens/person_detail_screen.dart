import 'package:flutter/material.dart';
import '../../data/models/split_expense_model.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/add_edit_person_dialog.dart';
import '../widgets/settle_up_dialog.dart';
import 'add_edit_split_expense_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final CashBookViewModel viewModel;
  final String personId;

  const PersonDetailScreen({
    super.key,
    required this.viewModel,
    required this.personId,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final person = viewModel.getPersonById(personId);
        if (person == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Person Details')),
            body: const Center(child: Text('Person not found')),
          );
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final currentUserId = viewModel.currentUser.id;
        final balance = viewModel.getPairwiseBalanceWith(person.id);

        // Filter shared expenses
        final sharedExpenses = viewModel.splitExpenses.where((e) {
          final isPayer = e.paidByPersonId == person.id || e.paidByPersonId == currentUserId;
          return isPayer && (e.paidByPersonId == person.id
              ? e.splits.any((s) => s.personId == currentUserId)
              : e.splits.any((s) => s.personId == person.id));
        }).toList();

        // Filter settlements between current user and this person
        final sharedSettlements = viewModel.settlements.where((s) {
          return (s.payerId == person.id && s.receiverId == currentUserId) ||
              (s.payerId == currentUserId && s.receiverId == person.id);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(person.name),
            actions: [
              if (!person.isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    AddEditPersonDialog.show(
                      context,
                      viewModel: viewModel,
                      initialPerson: person,
                    );
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Person Profile Card
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        color: person.color,
                        alignment: Alignment.center,
                        child: Text(
                          person.initials,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        person.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (person.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          person.phoneNumber!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Balance Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: balance > 0.01
                              ? (isDark
                                  ? const Color(0xFF14532D).withValues(alpha: 0.35)
                                  : Colors.green.withValues(alpha: 0.12))
                              : (balance < -0.01
                                  ? (isDark
                                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                                      : Colors.red.withValues(alpha: 0.12))
                                  : (isDark
                                      ? const Color(0xFF334155).withValues(alpha: 0.4)
                                      : Colors.grey.withValues(alpha: 0.12))),
                          border: Border.all(
                            color: balance > 0.01
                                ? (isDark
                                    ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                                    : Colors.green.withValues(alpha: 0.4))
                                : (balance < -0.01
                                    ? (isDark
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                        : Colors.red.withValues(alpha: 0.4))
                                    : (isDark
                                        ? const Color(0xFF475569)
                                        : Colors.grey.withValues(alpha: 0.4))),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              balance > 0.01
                                  ? 'OWES YOU'
                                  : (balance < -0.01 ? 'YOU OWE' : 'STATUS'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: balance > 0.01
                                    ? (isDark ? const Color(0xFF4ADE80) : Colors.green.shade700)
                                    : (balance < -0.01
                                        ? (isDark ? const Color(0xFFF87171) : Colors.red.shade700)
                                        : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              balance.abs() > 0.01
                                  ? AppFormatters.currency(balance.abs())
                                  : 'All Settled Up',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: balance > 0.01
                                    ? (isDark ? const Color(0xFF4ADE80) : Colors.green.shade800)
                                    : (balance < -0.01
                                        ? (isDark ? const Color(0xFFF87171) : Colors.red.shade800)
                                        : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Action Buttons
                      if (!person.isCurrentUser)
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF16A34A) : Colors.green.shade700,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                icon: const Icon(Icons.handshake_rounded),
                                label: const Text('Settle Up'),
                                onPressed: () {
                                  SettleUpDialog.show(
                                    context,
                                    viewModel: viewModel,
                                    initialPayerId: balance > 0 ? person.id : currentUserId,
                                    initialReceiverId: balance > 0 ? currentUserId : person.id,
                                    suggestedAmount: balance.abs() > 0.01 ? balance.abs() : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Expense'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditSplitExpenseScreen(
                                        viewModel: viewModel,
                                        preselectedPersonId: person.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Shared Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (sharedExpenses.isEmpty && sharedSettlements.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No shared expenses or settlements yet',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // List of expenses
                ...sharedExpenses.map((exp) {
                  final youPaid = exp.paidByPersonId == currentUserId;
                  final payer = viewModel.getPersonById(exp.paidByPersonId);
                  final personSplit = exp.splits.firstWhere(
                    (s) => s.personId == person.id,
                    orElse: () => const ExpenseSplitItem(personId: '', amount: 0.0),
                  );
                  final yourSplit = exp.splits.firstWhere(
                    (s) => s.personId == currentUserId,
                    orElse: () => const ExpenseSplitItem(personId: '', amount: 0.0),
                  );

                  return Card(
                    elevation: 1.5,
                    shadowColor: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.08),
                    margin: const EdgeInsets.only(bottom: 10),
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
                          Icons.receipt_long_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        exp.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${AppFormatters.date(exp.date)} • ${youPaid ? "You paid" : "${payer?.name ?? 'Friend'} paid"} ${AppFormatters.currency(exp.totalAmount)}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : null,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (youPaid)
                            Text(
                              '+${AppFormatters.currency(personSplit.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade700,
                              ),
                            )
                          else
                            Text(
                              '-${AppFormatters.currency(yourSplit.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF87171) : Colors.red.shade700,
                              ),
                            ),
                          Text(
                            youPaid ? 'they owe' : 'you owe',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // List of settlements
                ...sharedSettlements.map((st) {
                  final youReceived = st.receiverId == currentUserId;
                  return Card(
                    elevation: 1,
                    shadowColor: const Color(0xFF15803D).withValues(alpha: isDark ? 0.2 : 0.08),
                    margin: const EdgeInsets.only(bottom: 10),
                    color: isDark
                        ? const Color(0xFF14532D).withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        color: isDark ? const Color(0xFF22C55E) : Colors.green.shade700,
                        alignment: Alignment.center,
                        child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        youReceived
                            ? '${person.name} paid you'
                            : 'You paid ${person.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${AppFormatters.date(st.date)} via ${st.paymentMethod}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : null,
                        ),
                      ),
                      trailing: Text(
                        AppFormatters.currency(st.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF4ADE80) : Colors.green,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
