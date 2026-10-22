import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/add_edit_group_dialog.dart';
import '../widgets/add_edit_person_dialog.dart';
import '../widgets/app_logo.dart';
import '../widgets/settings_scope.dart';
import '../widgets/user_account_setup_dialog.dart';
import 'add_edit_split_expense_screen.dart';
import 'group_detail_screen.dart';
import 'person_detail_screen.dart';

class SplitHomeScreen extends StatelessWidget {
  final CashBookViewModel viewModel;

  const SplitHomeScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = viewModel;

    return DefaultTabController(
      length: 3,
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final totalOwed = vm.totalOwedToYou;
          final totalYouOwe = vm.totalYouOwe;
          final netBalance = vm.netSplitBalance;

          return Scaffold(
            appBar: AppBar(
              title: const AppBrandTitle(title: 'Split Expenses'),
              actions: [
                // Add Friend Button: Single person silhouette with plus in primary container
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    color: theme.colorScheme.primary,
                    tooltip: 'Add Friend',
                    onPressed: () {
                      AddEditPersonDialog.show(context, viewModel: vm);
                    },
                  ),
                ),
                // New Group Button: Squad/community icon in distinct purple container
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.diversity_3_rounded),
                    color: Colors.deepPurple.shade700,
                    tooltip: 'New Group',
                    onPressed: () {
                      AddEditGroupDialog.show(context, viewModel: vm);
                    },
                  ),
                ),
                // User Account / Profile Button
                Tooltip(
                  message: 'My Account (${vm.currentUser.name})',
                  child: InkWell(
                    onTap: () {
                      final settingsVm = SettingsScope.maybeOf(context);
                      UserAccountSetupDialog.show(
                        context,
                        cashBookViewModel: vm,
                        settingsViewModel: settingsVm,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 12),
                      width: 36,
                      height: 36,
                      color: vm.currentUser.color,
                      alignment: Alignment.center,
                      child: Text(
                        vm.currentUser.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Top Balance Overview Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _buildBalanceHeaderCard(
                    context,
                    totalOwed: totalOwed,
                    totalYouOwe: totalYouOwe,
                    netBalance: netBalance,
                  ),
                ),

                // Tab Bar (Friends | Groups | Activity)
                TabBar(
                  indicatorWeight: 3,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.person_rounded, size: 20),
                      text: 'Friends',
                    ),
                    Tab(
                      icon: Icon(Icons.groups_rounded, size: 20),
                      text: 'Groups',
                    ),
                    Tab(
                      icon: Icon(Icons.receipt_long_rounded, size: 20),
                      text: 'Activity',
                    ),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFriendsTab(context),
                      _buildGroupsTab(context),
                      _buildActivityTab(context),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'split_home_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditSplitExpenseScreen(
                      viewModel: vm,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Split Expense'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceHeaderCard(
    BuildContext context, {
    required double totalOwed,
    required double totalYouOwe,
    required double netBalance,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'OVERALL SPLIT BALANCE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  netBalance >= 0
                      ? 'Net: +${AppFormatters.currency(netBalance)}'
                      : 'Net: -${AppFormatters.currency(-netBalance)}',
                  style: TextStyle(
                    color: isDark
                        ? (netBalance >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171))
                        : const Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // You are owed (Green)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14532D).withValues(alpha: 0.35)
                        : const Color(0xFFF0FDF4),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            color: isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'You are owed',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppFormatters.currency(totalOwed),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // You owe (Red)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                        : const Color(0xFFFEF2F2),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            color: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'You owe',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppFormatters.currency(totalYouOwe),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vm = viewModel;
    final user = vm.currentUser;

    return Card(
      elevation: 1.5,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.08),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          final settingsVm = SettingsScope.maybeOf(context);
          UserAccountSetupDialog.show(
            context,
            cashBookViewModel: vm,
            settingsViewModel: settingsVm,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                color: user.color,
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.upiId != null && user.upiId!.isNotEmpty
                          ? 'UPI: ${user.upiId}'
                          : (user.phoneNumber != null && user.phoneNumber!.isNotEmpty
                              ? user.phoneNumber!
                              : 'Tap to configure profile & UPI ID'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                ),
                onPressed: () {
                  final settingsVm = SettingsScope.maybeOf(context);
                  UserAccountSetupDialog.show(
                    context,
                    cashBookViewModel: vm,
                    settingsViewModel: settingsVm,
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vm = viewModel;
    final otherPeople = vm.people.where((p) => !p.isCurrentUser).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _buildCurrentUserCard(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
          child: Row(
            children: [
              Text(
                'FRIENDS (${otherPeople.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => AddEditPersonDialog.show(context, viewModel: vm),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Add Friend', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        if (otherPeople.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No friends added yet',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add friends to split bills, track shared meals, trips & rent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () => AddEditPersonDialog.show(context, viewModel: vm),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Friend'),
                ),
              ],
            ),
          )
        else
          for (final person in otherPeople) ...[
            Builder(
              builder: (context) {
                final balance = vm.getPairwiseBalanceWith(person.id);
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonDetailScreen(
                            viewModel: vm,
                            personId: person.id,
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      width: 42,
                      height: 42,
                      color: person.color,
                      alignment: Alignment.center,
                      child: Text(
                        person.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      person.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      person.phoneNumber ?? (person.upiId != null ? 'UPI: ${person.upiId}' : 'Tap to view shared activity'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (balance > 0.01) ...[
                              Text(
                                '+${AppFormatters.currency(balance)}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'owes you',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade700,
                                  fontSize: 11,
                                ),
                              ),
                            ] else if (balance < -0.01) ...[
                              Text(
                                '-${AppFormatters.currency(-balance)}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF87171) : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'you owe',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF87171) : Colors.red.shade700,
                                  fontSize: 11,
                                ),
                              ),
                            ] else ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Settled',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? const Color(0xFF64748B) : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
      ],
    );
  }

  Widget _buildGroupsTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vm = viewModel;
    final groups = vm.groups;

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.deepPurple.withValues(alpha: 0.25)
                      : Colors.deepPurple.shade50,
                  border: Border.all(
                    color: isDark
                        ? Colors.deepPurple.withValues(alpha: 0.5)
                        : Colors.deepPurple.shade200,
                  ),
                ),
                child: Icon(
                  Icons.diversity_3_rounded,
                  size: 48,
                  color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No groups created yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Organize trips, flats, or events and let the app simplify who pays whom.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final debts = vm.getGroupSimplifiedDebts(group.id);
        final expenseCount = vm.splitExpenses.where((e) => e.groupId == group.id).length;

        return Card(
          elevation: 1.5,
          shadowColor: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.08),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(
                    viewModel: vm,
                    groupId: group.id,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        color: group.color,
                        alignment: Alignment.center,
                        child: Icon(group.icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${group.memberIds.length} members • $expenseCount expense(s)',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? const Color(0xFF64748B) : Colors.grey,
                      ),
                    ],
                  ),
                  if (debts.isNotEmpty) ...[
                    Divider(
                      height: 20,
                      color: isDark ? const Color(0xFF334155) : null,
                    ),
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            debts.length == 1
                                ? '1 payment needed to settle all'
                                : '${debts.length} payments needed to settle all',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          'View Plan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vm = viewModel;
    final currentUserId = vm.currentUser.id;

    // Combine split expenses and settlements into unified activity feed
    // Filter out any orphan records whose group was deleted
    final expenses = vm.splitExpenses.where((exp) {
      if (exp.groupId != null && vm.getGroupById(exp.groupId!) == null) {
        return false;
      }
      return true;
    }).toList();

    final settlements = vm.settlements.where((st) {
      if (st.groupId != null && vm.getGroupById(st.groupId!) == null) {
        return false;
      }
      return true;
    }).toList();

    if (expenses.isEmpty && settlements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 60,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No activity yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Split an expense or record a settlement to see recent activity here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Settlements section if any
        if (settlements.isNotEmpty) ...[
          Text(
            'Recent Settlements',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...settlements.take(5).map((st) {
            final payer = vm.getPersonById(st.payerId);
            final receiver = vm.getPersonById(st.receiverId);
            final isYouPayer = st.payerId == currentUserId;
            final isYouReceiver = st.receiverId == currentUserId;

            return Card(
              elevation: 1,
              shadowColor: const Color(0xFF15803D).withValues(alpha: isDark ? 0.2 : 0.08),
              margin: const EdgeInsets.only(bottom: 8),
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
                  child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 18),
                ),
                title: Text(
                  isYouReceiver
                      ? '${payer?.name ?? "Friend"} paid You'
                      : (isYouPayer
                          ? 'You paid ${receiver?.name ?? "Friend"}'
                          : '${payer?.name ?? "Payer"} paid ${receiver?.name ?? "Receiver"}'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${AppFormatters.date(st.date)} via ${st.paymentMethod}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : null,
                  ),
                ),
                trailing: Text(
                  AppFormatters.currency(st.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF4ADE80) : Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        Text(
          'Split Expenses',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        ...expenses.map((exp) {
          final youPaid = exp.paidByPersonId == currentUserId;
          final payer = vm.getPersonById(exp.paidByPersonId);
          final group = exp.groupId != null ? vm.getGroupById(exp.groupId!) : null;

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
                      viewModel: vm,
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
                  size: 20,
                ),
              ),
              title: Text(
                exp.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${AppFormatters.date(exp.date)} • ${youPaid ? "You paid" : "${payer?.name ?? 'Friend'} paid"}${group != null ? " in ${group.name}" : ""}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : null,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.currency(exp.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${exp.splits.length} people',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  if (!AppFormatters.isCurrentMonth(exp.date)) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 10,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Past Month',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
