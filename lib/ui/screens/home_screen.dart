import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/transaction_list_tile.dart';
import '../widgets/app_logo.dart';
import '../widgets/settings_scope.dart';
import '../widgets/user_account_setup_dialog.dart';
import 'add_edit_transaction_screen.dart';
import 'categories_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'split_home_screen.dart';

class HomeScreen extends StatefulWidget {
  final CashBookViewModel viewModel;
  final SettingsViewModel? settingsViewModel;

  const HomeScreen({
    super.key,
    required this.viewModel,
    this.settingsViewModel,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _openAddTransaction(TransactionType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          viewModel: widget.viewModel,
          initialType: type,
        ),
      ),
    );
  }

  void _openEditTransaction(TransactionModel tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          viewModel: widget.viewModel,
          initialTransaction: tx,
        ),
      ),
    );
  }

  void _openSettings() {
    final settingsVm = widget.settingsViewModel ?? SettingsScope.maybeOf(context);
    if (settingsVm != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsScreen(
            settingsViewModel: settingsVm,
            cashBookViewModel: widget.viewModel,
          ),
        ),
      );
    }
  }

  // Groups transactions by day
  Map<String, List<TransactionModel>> _groupTransactionsByDate(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final key = AppFormatters.relativeDateHeader(tx.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(tx);
    }
    return grouped;
  }

  // Calculate day total
  double _calculateDayNet(List<TransactionModel> dayList) {
    double total = 0.0;
    for (final tx in dayList) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildCashBookTab(),
              SplitHomeScreen(viewModel: widget.viewModel),
              CategoriesScreen(viewModel: widget.viewModel),
              ReportsScreen(viewModel: widget.viewModel),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Cash Book',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Split',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category_rounded),
                label: 'Categories',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded),
                label: 'Reports',
              ),
            ],
          ),
          bottomSheet: _currentIndex == 0 ? _buildBottomActionButtons() : null,
        );
      },
    );
  }

  Widget _buildCashBookTab() {
    final theme = Theme.of(context);
    final settingsVm = widget.settingsViewModel ?? SettingsScope.maybeOf(context);
    final transactions = widget.viewModel.filteredTransactions;
    final grouped = _groupTransactionsByDate(transactions);
    final currentUser = widget.viewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandTitle(title: 'Cash Book'),
        actions: [
          Tooltip(
            message: 'My Account (${currentUser.name})',
            child: InkWell(
              onTap: () {
                UserAccountSetupDialog.show(
                  context,
                  cashBookViewModel: widget.viewModel,
                  settingsViewModel: settingsVm,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                width: 32,
                height: 32,
                color: currentUser.color,
                alignment: Alignment.center,
                child: Text(
                  currentUser.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Account setup banner if not yet completed
          if (!(settingsVm?.settings.hasCompletedAccountSetup ?? true))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Up Your Account',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Add your name, phone & UPI ID for quick bill splitting',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          UserAccountSetupDialog.show(
                            context,
                            cashBookViewModel: widget.viewModel,
                            settingsViewModel: settingsVm,
                          );
                        },
                        child: const Text('Set Up', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Filters Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: FilterChipBar(viewModel: widget.viewModel),
            ),
          ),

          // Transaction List or Empty State
          if (transactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 54,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + Cash In or - Cash Out below to record your first transaction.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 80), // padding for bottom bar
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Count header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  '${transactions.length} ${transactions.length == 1 ? 'entry' : 'entries'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Grouped transaction items
            ...grouped.entries.map((entry) {
              final dateHeader = entry.key;
              final dayList = entry.value;
              final dayNet = _calculateDayNet(dayList);

              return SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DateHeaderDelegate(
                      dateText: dateHeader,
                      dayNet: dayNet,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = dayList[index];
                        final cat = widget.viewModel.getCategoryById(tx.categoryId);
                        return TransactionListTile(
                          transaction: tx,
                          category: cat,
                          onTap: () => _openEditTransaction(tx),
                          onDelete: () => widget.viewModel.deleteTransaction(tx.id),
                        );
                      },
                      childCount: dayList.length,
                    ),
                  ),
                ],
              );
            }),

            // Padding at bottom so last item isn't covered by bottom action buttons
            const SliverToBoxAdapter(
              child: SizedBox(height: 90),
            ),
          ],
        ],
      ),
    );
  }

  // Flat bottom action bar with prominent "Cash In" and "Cash Out" buttons
  Widget _buildBottomActionButtons() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cash In (+ Income) Button
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 3,
                  shadowColor: const Color(0xFF15803D).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Cash In',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openAddTransaction(TransactionType.income),
              ),
            ),
            const SizedBox(width: 8),
            // Cash Out (- Expense) Button
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 3,
                  shadowColor: const Color(0xFFB91C1C).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.remove_rounded, size: 20),
                label: const Text(
                  'Cash Out',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openAddTransaction(TransactionType.expense),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String dateText;
  final double dayNet;

  _DateHeaderDelegate({
    required this.dateText,
    required this.dayNet,
  });

  @override
  double get minExtent => 34;

  @override
  double get maxExtent => 34;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPositive = dayNet >= 0;

    final dotColor = isPositive
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C));

    final badgeBg = isPositive
        ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.45) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.45) : const Color(0xFFFEF2F2));

    final badgeBorder = isPositive
        ? (isDark ? const Color(0xFF22C55E).withValues(alpha: 0.6) : const Color(0xFFBBF7D0))
        : (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.6) : const Color(0xFFFECACA));

    final textColor = isPositive
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C));

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                color: dotColor,
              ),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              border: Border.all(
                color: badgeBorder,
                width: 1,
              ),
            ),
            child: Text(
              'Daily Net: ${isPositive ? '+' : ''}${AppFormatters.currency(dayNet)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) {
    return oldDelegate.dateText != dateText || oldDelegate.dayNet != dayNet;
  }
}
