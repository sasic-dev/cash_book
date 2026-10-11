import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../utils/formatters.dart';

class TransactionListTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListTile({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C));
    final prefix = isIncome ? '+ ' : '- ';

    final catColor = category?.color ?? const Color(0xFF64748B);
    final catIcon = category?.icon ?? Icons.category_rounded;
    final catName = category?.name ?? 'General';

    final displayName = transaction.title.trim().isNotEmpty
        ? transaction.title.trim()
        : catName;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFDC2626),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: const Text('Delete Transaction?'),
            content: Text(
                'Are you sure you want to delete this ${transaction.type.label.toLowerCase()} of ${AppFormatters.currency(transaction.amount)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Category Icon in flat square container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      border: Border.all(color: catColor.withValues(alpha: isDark ? 0.45 : 0.3)),
                    ),
                    child: Icon(
                      catIcon,
                      color: catColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title, Category name, payment mode, time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                catName,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                transaction.paymentMode,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppFormatters.time(transaction.date),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$prefix${AppFormatters.currency(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
