import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../../data/services/report_export_service.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/app_logo.dart';

enum ReportPeriod {
  daily('Daily', Icons.calendar_today_outlined),
  weekly('Weekly', Icons.view_week_outlined),
  monthly('Monthly', Icons.calendar_month_outlined),
  custom('Custom', Icons.date_range_outlined);

  final String label;
  final IconData icon;
  const ReportPeriod(this.label, this.icon);
}

class ReportsScreen extends StatefulWidget {
  final CashBookViewModel viewModel;

  const ReportsScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  DateTime _anchorDate = DateTime.now();
  DateTimeRange? _customDateRange;
  int _viewModeIndex = 0; // 0 = Summary, 1 = Transactions

  // Date Calculation Helpers
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 0, 0, 0);
  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  DateTime _startOfWeek(DateTime d) {
    final start = d.subtract(Duration(days: d.weekday - 1));
    return DateTime(start.year, start.month, start.day, 0, 0, 0);
  }

  DateTime _endOfWeek(DateTime d) {
    final start = _startOfWeek(d);
    final end = start.add(const Duration(days: 6));
    return DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
  }

  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1, 0, 0, 0);
  DateTime _endOfMonth(DateTime d) {
    final nextMonth = DateTime(d.year, d.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  DateTime get _periodStartDate {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return _startOfDay(_anchorDate);
      case ReportPeriod.weekly:
        return _startOfWeek(_anchorDate);
      case ReportPeriod.monthly:
        return _startOfMonth(_anchorDate);
      case ReportPeriod.custom:
        return _customDateRange?.start ?? _startOfMonth(_anchorDate);
    }
  }

  DateTime get _periodEndDate {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return _endOfDay(_anchorDate);
      case ReportPeriod.weekly:
        return _endOfWeek(_anchorDate);
      case ReportPeriod.monthly:
        return _endOfMonth(_anchorDate);
      case ReportPeriod.custom:
        return _customDateRange != null ? _endOfDay(_customDateRange!.end) : _endOfMonth(_anchorDate);
    }
  }

  String get _periodLabel {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        final sameDay = _anchorDate.year == now.year &&
            _anchorDate.month == now.month &&
            _anchorDate.day == now.day;
        final yesterday = now.subtract(const Duration(days: 1));
        final isYesterday = _anchorDate.year == yesterday.year &&
            _anchorDate.month == yesterday.month &&
            _anchorDate.day == yesterday.day;

        if (sameDay) {
          return 'Today • ${AppFormatters.date(_anchorDate)}';
        } else if (isYesterday) {
          return 'Yesterday • ${AppFormatters.date(_anchorDate)}';
        } else {
          return AppFormatters.date(_anchorDate);
        }

      case ReportPeriod.weekly:
        final start = _periodStartDate;
        final end = _periodEndDate;
        return '${AppFormatters.date(start)} - ${AppFormatters.date(end)}';

      case ReportPeriod.monthly:
        return AppFormatters.monthYear(_anchorDate);

      case ReportPeriod.custom:
        if (_customDateRange != null) {
          return '${AppFormatters.date(_customDateRange!.start)} - ${AppFormatters.date(_customDateRange!.end)}';
        }
        return 'Select Date Range';
    }
  }

  void _navigatePrevious() {
    setState(() {
      switch (_selectedPeriod) {
        case ReportPeriod.daily:
          _anchorDate = _anchorDate.subtract(const Duration(days: 1));
          break;
        case ReportPeriod.weekly:
          _anchorDate = _anchorDate.subtract(const Duration(days: 7));
          break;
        case ReportPeriod.monthly:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, 1);
          break;
        case ReportPeriod.custom:
          _pickCustomDateRange();
          break;
      }
    });
  }

  void _navigateNext() {
    setState(() {
      switch (_selectedPeriod) {
        case ReportPeriod.daily:
          _anchorDate = _anchorDate.add(const Duration(days: 1));
          break;
        case ReportPeriod.weekly:
          _anchorDate = _anchorDate.add(const Duration(days: 7));
          break;
        case ReportPeriod.monthly:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
          break;
        case ReportPeriod.custom:
          _pickCustomDateRange();
          break;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: _startOfMonth(_anchorDate),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = ReportPeriod.custom;
      });
    }
  }

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _anchorDate = picked;
      });
    }
  }

  Future<void> _handleDownloadAndOpenPdf(
    BuildContext context, {
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
    PdfGroupingMode groupingMode = PdfGroupingMode.none,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await ReportExportService.exportPdfWithLocationPicker(
      periodTitle: '${_selectedPeriod.label} Report',
      dateRangeLabel: _periodLabel,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: netBalance,
      transactions: transactions,
      categoriesMap: categoriesMap,
      groupingMode: groupingMode,
    );

    if (result.isCancelled) {
      return;
    }

    if (result.isSuccess) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B5E20),
          content: InkWell(
            onTap: () {
              ReportExportService.openPdf(
                filePath: result.filePath,
                fileUri: result.fileUri,
              );
            },
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PDF Downloaded to Downloads',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        result.fileName ?? 'Tap OPEN to view statement',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.amberAccent,
            onPressed: () {
              ReportExportService.openPdf(
                filePath: result.filePath,
                fileUri: result.fileUri,
              );
            },
          ),
        ),
      );

      // Proactively trigger opening the PDF in the system viewer
      await ReportExportService.openPdf(
        filePath: result.filePath,
        fileUri: result.fileUri,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Download failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDownloadFormatBottomSheet(
    BuildContext context, {
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                              : const Color(0xFFEEF2FF),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                                : const Color(0xFFC7D2FE),
                          ),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Download Statement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose how to format and organize transactions:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFF94A3B8) : null,
                        ),
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Full List (Without Group)
                  _buildFormatOptionTile(
                    context: bottomSheetContext,
                    icon: Icons.format_list_bulleted_rounded,
                    iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                    iconBg: isDark
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                        : const Color(0xFFEEF2FF),
                    title: 'Without Group (Full List)',
                    subtitle: 'Single chronological list of all transactions',
                    badgeText: 'Full List',
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      _handleDownloadAndOpenPdf(
                        context,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        netBalance: netBalance,
                        transactions: transactions,
                        categoriesMap: categoriesMap,
                        groupingMode: PdfGroupingMode.none,
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Group by Date (Dates List)
                  _buildFormatOptionTile(
                    context: bottomSheetContext,
                    icon: Icons.calendar_today_rounded,
                    iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                    iconBg: isDark
                        ? const Color(0xFF14532D).withValues(alpha: 0.35)
                        : const Color(0xFFF0FDF4),
                    title: 'Group by Date (Dates List)',
                    subtitle: 'Transactions grouped day-by-day with daily totals',
                    badgeText: 'Daily',
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      _handleDownloadAndOpenPdf(
                        context,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        netBalance: netBalance,
                        transactions: transactions,
                        categoriesMap: categoriesMap,
                        groupingMode: PdfGroupingMode.byDate,
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Group by Category
                  _buildFormatOptionTile(
                    context: bottomSheetContext,
                    icon: Icons.category_rounded,
                    iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                    iconBg: isDark
                        ? const Color(0xFF78350F).withValues(alpha: 0.35)
                        : const Color(0xFFFFFBEB),
                    title: 'Group by Category',
                    subtitle: 'Transactions grouped under each category with subtotals',
                    badgeText: 'Category',
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      _handleDownloadAndOpenPdf(
                        context,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        netBalance: netBalance,
                        transactions: transactions,
                        categoriesMap: categoriesMap,
                        groupingMode: PdfGroupingMode.byCategory,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormatOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: iconBg,
                          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final start = _periodStartDate;
        final end = _periodEndDate;

        // Filter transactions strictly for this period
        final periodTransactions = widget.viewModel.transactions.where((tx) {
          return (tx.date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
              tx.date.isBefore(end.add(const Duration(milliseconds: 1))));
        }).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final totalIn = periodTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalOut = periodTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final netFlow = totalIn - totalOut;

        // Group expenses by category
        final expenseTransactions =
            periodTransactions.where((t) => t.type == TransactionType.expense).toList();
        final Map<String, double> expenseByCategory = {};
        for (final tx in expenseTransactions) {
          expenseByCategory[tx.categoryId] =
              (expenseByCategory[tx.categoryId] ?? 0.0) + tx.amount;
        }
        final sortedExpenseEntries = expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Group income by category
        final incomeTransactions =
            periodTransactions.where((t) => t.type == TransactionType.income).toList();
        final Map<String, double> incomeByCategory = {};
        for (final tx in incomeTransactions) {
          incomeByCategory[tx.categoryId] =
              (incomeByCategory[tx.categoryId] ?? 0.0) + tx.amount;
        }
        final sortedIncomeEntries = incomeByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          appBar: AppBar(
            title: const AppBrandTitle(title: 'Reports & Statements'),
            // Note: Header PDF download removed as requested
          ),
          body: Column(
            children: [
              // Top Period Selector (Daily | Weekly | Monthly | Custom)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: _buildPeriodSelector(context),
              ),

              // Interactive Date Navigator Bar (< [Calendar] Date >)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: _buildDateNavigator(context),
              ),

              // View Mode Selector (Summary vs Transactions)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: _buildViewModeSelector(context, periodTransactions.length),
              ),

              // Content View (Summary Dashboard vs Transactions List)
              Expanded(
                child: _viewModeIndex == 0
                    ? _buildOverviewTab(
                        context,
                        totalIn: totalIn,
                        totalOut: totalOut,
                        netFlow: netFlow,
                        periodTransactions: periodTransactions,
                        sortedExpenseEntries: sortedExpenseEntries,
                        sortedIncomeEntries: sortedIncomeEntries,
                      )
                    : _buildTransactionListTab(
                        context,
                        periodTransactions: periodTransactions,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Period Selector (Daily, Weekly, Monthly, Custom)
  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ReportPeriod.values.map((p) {
          final isSelected = _selectedPeriod == p;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (p == ReportPeriod.custom) {
                  _pickCustomDateRange();
                } else {
                  setState(() => _selectedPeriod = p);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? theme.colorScheme.primary.withValues(alpha: 0.25)
                          : const Color(0xFFEEF2FF))
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                          color: isDark
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : const Color(0xFFC7D2FE),
                          width: 1,
                        )
                      : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? Icons.check_rounded : p.icon,
                      size: 14,
                      color: isSelected
                          ? (isDark ? theme.colorScheme.primary : const Color(0xFF3730A3))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? theme.colorScheme.primary : const Color(0xFF3730A3))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 2. Date Navigator Bar (< [Date] >)
  Widget _buildDateNavigator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 22,
              color: isDark ? const Color(0xFFCBD5E1) : null,
            ),
            tooltip: 'Previous ${_selectedPeriod.label}',
            onPressed: _navigatePrevious,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: InkWell(
              onTap: _selectedPeriod == ReportPeriod.custom
                  ? _pickCustomDateRange
                  : _pickAnchorDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _periodLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: isDark ? const Color(0xFFCBD5E1) : null,
            ),
            tooltip: 'Next ${_selectedPeriod.label}',
            onPressed: _navigateNext,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // 3. View Mode Sub-tabs (Summary vs Transactions)
  Widget _buildViewModeSelector(BuildContext context, int txCount) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          // Summary Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _viewModeIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewModeIndex == 0
                      ? (isDark
                          ? theme.colorScheme.primary.withValues(alpha: 0.25)
                          : const Color(0xFFEEF2FF))
                      : Colors.transparent,
                  border: _viewModeIndex == 0
                      ? Border.all(
                          color: isDark
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : const Color(0xFFC7D2FE),
                        )
                      : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_rounded,
                      size: 15,
                      color: _viewModeIndex == 0
                          ? (isDark ? theme.colorScheme.primary : const Color(0xFF3730A3))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _viewModeIndex == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _viewModeIndex == 0
                            ? (isDark ? theme.colorScheme.primary : const Color(0xFF3730A3))
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Transactions Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _viewModeIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewModeIndex == 1
                      ? (isDark
                          ? theme.colorScheme.primary.withValues(alpha: 0.25)
                          : const Color(0xFFEEF2FF))
                      : Colors.transparent,
                  border: _viewModeIndex == 1
                      ? Border.all(
                          color: isDark
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : const Color(0xFFC7D2FE),
                        )
                      : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 15,
                      color: _viewModeIndex == 1
                          ? (isDark ? theme.colorScheme.primary : const Color(0xFF3730A3))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Transactions ($txCount)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _viewModeIndex == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _viewModeIndex == 1
                            ? (isDark ? theme.colorScheme.primary : const Color(0xFF3730A3))
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Main Overview Tab (matches screenshot)
  Widget _buildOverviewTab(
    BuildContext context, {
    required double totalIn,
    required double totalOut,
    required double netFlow,
    required List<TransactionModel> periodTransactions,
    required List<MapEntry<String, double>> sortedExpenseEntries,
    required List<MapEntry<String, double>> sortedIncomeEntries,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4a. Net Cash Flow Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon + Net Cash Flow label + Big Amount
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? (netFlow >= 0 ? const Color(0xFF14532D) : const Color(0xFF7F1D1D))
                              : (netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: isDark
                              ? (netFlow >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171))
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Net Cash Flow',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                netFlow >= 0
                                    ? '+ ${AppFormatters.currency(netFlow)}'
                                    : '- ${AppFormatters.currency(-netFlow)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? (netFlow >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171))
                                      : (netFlow >= 0 ? const Color(0xFF15803D) : const Color(0xFFDC2626)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge Pill (Positive / Negative / Neutral)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (netFlow >= 0
                            ? const Color(0xFF14532D).withValues(alpha: 0.5)
                            : const Color(0xFF7F1D1D).withValues(alpha: 0.5))
                        : (netFlow >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        netFlow >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: isDark
                            ? (netFlow >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171))
                            : (netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        netFlow >= 0 ? 'Positive' : 'Negative',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? (netFlow >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171))
                              : (netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4b. Total Cash In & Total Cash Out (Side by Side)
          Row(
            children: [
              // Total Cash In Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF14532D) : const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          color: isDark ? const Color(0xFF4ADE80) : Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Cash In',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppFormatters.currency(totalIn),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Total Cash Out Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: isDark ? const Color(0xFFF87171) : Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Cash Out',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppFormatters.currency(totalOut),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4c. Cash Flow Chart Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cash Flow',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cash In',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cash Out',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bar Chart View
                _CashFlowBarChart(
                  periodTransactions: periodTransactions,
                  period: _selectedPeriod,
                  anchorDate: _anchorDate,
                  startDate: _periodStartDate,
                  endDate: _periodEndDate,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4d. Category Breakdowns: Expense & Income side-by-side
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumn = constraints.maxWidth >= 340;

              final expenseCard = _buildCategoryBreakdownCard(
                context,
                title: 'Expense by Category',
                totalAmount: totalOut,
                totalColor: const Color(0xFFDC2626),
                entries: sortedExpenseEntries,
                isIncome: false,
                emptyMessage: 'No expenses in this period',
              );

              final incomeCard = _buildCategoryBreakdownCard(
                context,
                title: 'Income by Category',
                totalAmount: totalIn,
                totalColor: const Color(0xFF16A34A),
                entries: sortedIncomeEntries,
                isIncome: true,
                emptyMessage: 'No income in this period',
              );

              if (isTwoColumn) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: expenseCard),
                    const SizedBox(width: 10),
                    Expanded(child: incomeCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    expenseCard,
                    const SizedBox(height: 10),
                    incomeCard,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // 4e. Download PDF Statement Action Button
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : const Color(0xFFEEF2FF),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : const Color(0xFFC7D2FE),
              ),
            ),
            child: InkWell(
              onTap: () {
                final categoriesMap = {
                  for (final c in widget.viewModel.categories) c.id: c,
                };
                _showDownloadFormatBottomSheet(
                  context,
                  totalIncome: totalIn,
                  totalExpense: totalOut,
                  netBalance: netFlow,
                  transactions: periodTransactions,
                  categoriesMap: categoriesMap,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: isDark ? theme.colorScheme.primary : const Color(0xFF1E40AF),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Download PDF Statement',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? theme.colorScheme.primary : const Color(0xFF1E40AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? theme.colorScheme.primary : const Color(0xFF1E40AF),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build Category Breakdown Card (Expense / Income)
  Widget _buildCategoryBreakdownCard(
    BuildContext context, {
    required String title,
    required double totalAmount,
    required Color totalColor,
    required List<MapEntry<String, double>> entries,
    required bool isIncome,
    required String emptyMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Category Title and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Total: ${AppFormatters.currency(totalAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? (isIncome ? const Color(0xFF4ADE80) : const Color(0xFFF87171))
                        : totalColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Items or Empty
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...entries.map((entry) {
              final cat = widget.viewModel.getCategoryById(entry.key);
              final percentage = totalAmount > 0 ? (entry.value / totalAmount) : 0.0;
              final catColor = cat?.color ??
                  (isIncome ? const Color(0xFF16A34A) : const Color(0xFFEF4444));
              final catIcon = cat?.icon ?? (isIncome ? Icons.arrow_downward : Icons.arrow_upward);
              final catName = cat?.name ?? 'Other';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Small circular icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(catIcon, color: catColor, size: 13),
                    ),
                    const SizedBox(width: 6),

                    // Title + Bar + Amount + Percent
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  catName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppFormatters.currency(entry.value),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: percentage.clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFF1F5F9),
                                    valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(percentage * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 5. Transaction List Tab
  Widget _buildTransactionListTab(
    BuildContext context, {
    required List<TransactionModel> periodTransactions,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (periodTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: isDark ? const Color(0xFF475569) : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No transactions found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'There are no income or expense records for $_periodLabel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: periodTransactions.length,
      itemBuilder: (context, index) {
        final tx = periodTransactions[index];
        final cat = widget.viewModel.getCategoryById(tx.categoryId);
        final isIncome = tx.type == TransactionType.income;
        final catColor = cat?.color ?? (isIncome ? Colors.green : Colors.red);
        final catIcon = cat?.icon ?? (isIncome ? Icons.arrow_downward : Icons.arrow_upward);

        return Card(
          elevation: isDark ? 0 : 1,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                border: Border.all(color: catColor.withValues(alpha: 0.3)),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            title: Text(
              tx.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Text(
                  AppFormatters.date(tx.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    tx.paymentMode,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Text(
              isIncome
                  ? '+${AppFormatters.currency(tx.amount)}'
                  : '-${AppFormatters.currency(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isIncome
                    ? (isDark ? const Color(0xFF4ADE80) : Colors.green.shade700)
                    : (isDark ? const Color(0xFFF87171) : Colors.red.shade700),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Data point for Cash Flow Chart
class _ChartDataPoint {
  final String label;
  final bool showLabel;
  final double cashIn;
  final double cashOut;

  const _ChartDataPoint({
    required this.label,
    required this.showLabel,
    required this.cashIn,
    required this.cashOut,
  });
}

// Interactive & pixel-perfect grouped Bar Chart
class _CashFlowBarChart extends StatelessWidget {
  final List<TransactionModel> periodTransactions;
  final ReportPeriod period;
  final DateTime anchorDate;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDark;

  const _CashFlowBarChart({
    required this.periodTransactions,
    required this.period,
    required this.anchorDate,
    required this.startDate,
    required this.endDate,
    this.isDark = false,
  });

  List<_ChartDataPoint> _buildPoints() {
    final points = <_ChartDataPoint>[];

    if (period == ReportPeriod.monthly) {
      final daysInMonth = DateTime(anchorDate.year, anchorDate.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        double dayIn = 0;
        double dayOut = 0;
        for (final tx in periodTransactions) {
          if (tx.date.day == day) {
            if (tx.type == TransactionType.income) {
              dayIn += tx.amount;
            } else {
              dayOut += tx.amount;
            }
          }
        }
        final showLabel = (day == 1 ||
            day == 5 ||
            day == 10 ||
            day == 15 ||
            day == 20 ||
            day == 25 ||
            day == 30 ||
            day == daysInMonth);
        points.add(_ChartDataPoint(
          label: '$day',
          showLabel: showLabel,
          cashIn: dayIn,
          cashOut: dayOut,
        ));
      }
    } else if (period == ReportPeriod.weekly) {
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 0; i < 7; i++) {
        final d = startDate.add(Duration(days: i));
        double dayIn = 0;
        double dayOut = 0;
        for (final tx in periodTransactions) {
          if (tx.date.year == d.year && tx.date.month == d.month && tx.date.day == d.day) {
            if (tx.type == TransactionType.income) {
              dayIn += tx.amount;
            } else {
              dayOut += tx.amount;
            }
          }
        }
        points.add(_ChartDataPoint(
          label: weekDays[i],
          showLabel: true,
          cashIn: dayIn,
          cashOut: dayOut,
        ));
      }
    } else if (period == ReportPeriod.daily) {
      final intervals = [
        {'label': '6 AM', 'start': 0, 'end': 6},
        {'label': '10 AM', 'start': 6, 'end': 10},
        {'label': '2 PM', 'start': 10, 'end': 14},
        {'label': '6 PM', 'start': 14, 'end': 18},
        {'label': '10 PM', 'start': 18, 'end': 22},
        {'label': '12 AM', 'start': 22, 'end': 24},
      ];
      for (final intv in intervals) {
        double dayIn = 0;
        double dayOut = 0;
        for (final tx in periodTransactions) {
          final h = tx.date.hour;
          if (h >= (intv['start'] as int) && h < (intv['end'] as int)) {
            if (tx.type == TransactionType.income) {
              dayIn += tx.amount;
            } else {
              dayOut += tx.amount;
            }
          }
        }
        points.add(_ChartDataPoint(
          label: intv['label'] as String,
          showLabel: true,
          cashIn: dayIn,
          cashOut: dayOut,
        ));
      }
    } else {
      // Custom date range
      final diff = endDate.difference(startDate).inDays + 1;
      final step = math.max(1, (diff / 7).ceil());
      for (int i = 0; i < diff; i += step) {
        final curr = startDate.add(Duration(days: i));
        final next = startDate.add(Duration(days: math.min(diff, i + step)));
        double dayIn = 0;
        double dayOut = 0;
        for (final tx in periodTransactions) {
          if (tx.date.isAfter(curr.subtract(const Duration(milliseconds: 1))) &&
              tx.date.isBefore(next)) {
            if (tx.type == TransactionType.income) {
              dayIn += tx.amount;
            } else {
              dayOut += tx.amount;
            }
          }
        }
        points.add(_ChartDataPoint(
          label: '${curr.day}/${curr.month}',
          showLabel: true,
          cashIn: dayIn,
          cashOut: dayOut,
        ));
      }
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(points: points, isDark: isDark),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_ChartDataPoint> points;
  final bool isDark;

  _BarChartPainter({required this.points, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    const double labelAreaHeight = 22.0;
    final double chartHeight = size.height - labelAreaHeight;

    // Background horizontal gridlines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final baselinePaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, chartHeight * 0.25), Offset(size.width, chartHeight * 0.25), gridPaint);
    canvas.drawLine(Offset(0, chartHeight * 0.60), Offset(size.width, chartHeight * 0.60), gridPaint);
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), baselinePaint);

    if (points.isEmpty) return;

    double maxVal = 0.0;
    for (final p in points) {
      if (p.cashIn > maxVal) maxVal = p.cashIn;
      if (p.cashOut > maxVal) maxVal = p.cashOut;
    }
    if (maxVal <= 0) maxVal = 1000.0;

    final int n = points.length;
    final double slotWidth = size.width / n;
    final double barWidth = (slotWidth * 0.35).clamp(2.0, 7.0);

    final inPaint = Paint()..color = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    final outPaint = Paint()..color = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

    for (int i = 0; i < n; i++) {
      final p = points[i];
      final centerX = (i + 0.5) * slotWidth;

      // Draw Cash In Bar (green)
      if (p.cashIn > 0) {
        final inHeight = ((p.cashIn / maxVal) * (chartHeight - 8)).clamp(4.0, chartHeight - 4);
        final inRect = Rect.fromLTRB(
          centerX - barWidth - 0.6,
          chartHeight - inHeight,
          centerX - 0.6,
          chartHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            inRect,
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          inPaint,
        );
      }

      // Draw Cash Out Bar (red/coral)
      if (p.cashOut > 0) {
        final outHeight = ((p.cashOut / maxVal) * (chartHeight - 8)).clamp(4.0, chartHeight - 4);
        final outRect = Rect.fromLTRB(
          centerX + 0.6,
          chartHeight - outHeight,
          centerX + barWidth + 0.6,
          chartHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            outRect,
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          outPaint,
        );
      }

      // X Axis Label
      if (p.showLabel && p.label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: p.label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(centerX - (textPainter.width / 2), chartHeight + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.isDark != isDark;
  }
}
