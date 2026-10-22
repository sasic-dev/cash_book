import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double? balance;
  final double totalIncome;
  final double totalExpense;
  final String periodLabel;

  const BalanceCard({
    super.key,
    this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inBoxBg = isDark
        ? AppConstants.incomeDarkBg.withValues(alpha: 0.35)
        : AppConstants.incomeLightBg;
    final inBoxBorder = isDark
        ? AppConstants.incomeGreen.withValues(alpha: 0.5)
        : AppConstants.incomeLightBorder;
    final inTextColor = isDark ? AppConstants.incomeDarkText : AppConstants.incomeGreenDark;

    final outBoxBg = isDark
        ? AppConstants.expenseDarkBg.withValues(alpha: 0.35)
        : AppConstants.expenseLightBg;
    final outBoxBorder = isDark
        ? AppConstants.expenseRed.withValues(alpha: 0.5)
        : AppConstants.expenseLightBorder;
    final outTextColor = isDark ? AppConstants.expenseDarkText : AppConstants.expenseRedDark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCardBg : AppConstants.lightCardBg,
        border: Border.all(
          color: isDark ? AppConstants.darkBorder : AppConstants.lightInputBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppConstants.darkSurface.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with section label and period selection badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TOTAL SUMMARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                  border: Border.all(
                    color: isDark ? AppConstants.darkInputBorder : AppConstants.lightInputBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 10,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      periodLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total In and Total Out horizontal split
          Row(
            children: [
              // Total In (Income)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: inBoxBg,
                    border: Border.all(
                      color: inBoxBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.incomeGreenDark.withValues(alpha: isDark ? 0.15 : 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        color: AppConstants.incomeGreen,
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total In',
                              style: TextStyle(
                                color: inTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppFormatters.currency(totalIncome),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: inTextColor,
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

              // Total Out (Expense)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: outBoxBg,
                    border: Border.all(
                      color: outBoxBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.expenseRedDark.withValues(alpha: isDark ? 0.15 : 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        color: AppConstants.expenseRed,
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Out',
                              style: TextStyle(
                                color: outTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppFormatters.currency(totalExpense),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: outTextColor,
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
        ],
      ),
    );
  }
}
