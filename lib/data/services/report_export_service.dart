import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../config/app_constants.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../../ui/utils/formatters.dart';

class ReportExportResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? filePath;
  final String? fileUri;
  final String? fileName;
  final String? errorMessage;

  const ReportExportResult({
    required this.isSuccess,
    this.isCancelled = false,
    this.filePath,
    this.fileUri,
    this.fileName,
    this.errorMessage,
  });
}

enum PdfGroupingMode {
  none(
    'Without Group (Full List)',
    'Single chronological list of all transactions',
  ),
  byDate(
    'Group by Date (Dates List)',
    'Transactions grouped by date with daily totals',
  ),
  byCategory(
    'Group by Category',
    'Transactions grouped under each category with subtotals',
  );

  final String label;
  final String description;
  const PdfGroupingMode(this.label, this.description);
}

class ReportExportService {
  static const _channel = MethodChannel(AppConstants.pdfChannel);
  /// Generates a professional multi-page PDF financial statement
  static Future<Uint8List> generatePdf({
    required String periodTitle,
    required String dateRangeLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
    PdfGroupingMode groupingMode = PdfGroupingMode.none,
  }) async {
    final pdf = pw.Document();

    const primaryColor = PdfColor.fromInt(0xFF0D47A1); // Deep Navy Blue
    const incomeGreen = PdfColor.fromInt(0xFF1B5E20); // Dark Green
    const expenseRed = PdfColor.fromInt(0xFFB71C1C); // Dark Red
    const neutralDark = PdfColor.fromInt(0xFF212121);
    const neutralMuted = PdfColor.fromInt(0xFF757575);
    const lightGreyBg = PdfColor.fromInt(0xFFF5F7FA);
    const borderGrey = PdfColor.fromInt(0xFFE0E0E0);

    // Group expenses by category
    final expenseTransactions =
        transactions.where((t) => t.type == TransactionType.expense).toList();
    final Map<String, double> categorySums = {};
    for (final tx in expenseTransactions) {
      categorySums[tx.categoryId] =
          (categorySums[tx.categoryId] ?? 0.0) + tx.amount;
    }
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: borderGrey, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppConstants.reportStatementTitle,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${periodTitle.toUpperCase()} | $dateRangeLabel${groupingMode != PdfGroupingMode.none ? " | ${groupingMode.label.toUpperCase()}" : ""}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: neutralMuted,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${AppFormatters.date(DateTime.now())} ${AppFormatters.time(DateTime.now())}',
                      style:
                          const pw.TextStyle(fontSize: 8, color: neutralMuted),
                    ),
                    pw.Text(
                      'Records: ${transactions.length}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: neutralDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border:
                  pw.Border(top: pw.BorderSide(color: borderGrey, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  AppConstants.reportStatementFooter,
                  style: const pw.TextStyle(fontSize: 8, color: neutralMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: neutralMuted,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // Totals summary cards
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGreyBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: borderGrey),
            ),
            child: pw.Row(
              children: [
                // Total Income
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TOTAL CASH IN',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: neutralMuted,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Rs. ${AppFormatters.number(totalIncome)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: incomeGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(height: 28, width: 1, color: borderGrey),
                pw.SizedBox(width: 12),
                // Total Expense
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TOTAL CASH OUT',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: neutralMuted,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Rs. ${AppFormatters.number(totalExpense)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: expenseRed,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(height: 28, width: 1, color: borderGrey),
                pw.SizedBox(width: 12),
                // Net Balance
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NET BALANCE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: neutralMuted,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${netBalance >= 0 ? '+' : ''}Rs. ${AppFormatters.number(netBalance)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: netBalance >= 0 ? incomeGreen : expenseRed,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(height: 28, width: 1, color: borderGrey),
                pw.SizedBox(width: 12),
                // Transaction count
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TRANSACTIONS',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: neutralMuted,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${transactions.length}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: neutralDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Category Breakdown Table (only if not grouped by category)
          if (sortedCategories.isNotEmpty && groupingMode != PdfGroupingMode.byCategory) ...[
            pw.Text(
              'EXPENSE BREAKDOWN BY CATEGORY',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: primaryColor,
              ),
              headerHeight: 20,
              cellHeight: 18,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
              headers: <dynamic>['Category', 'Amount', '% of Total Out'],
              data: sortedCategories.map((entry) {
                final catName = categoriesMap[entry.key]?.name ?? 'Other';
                final pct =
                    totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                return <dynamic>[
                  catName,
                  'Rs. ${AppFormatters.number(entry.value)}',
                  '${pct.toStringAsFixed(1)}%',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 14),
          ],

          // Transaction Record Section
          if (transactions.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderGrey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'No transactions recorded for this period.',
                style: const pw.TextStyle(fontSize: 9, color: neutralMuted),
              ),
            )
          else if (groupingMode == PdfGroupingMode.byDate) ...[
            ..._buildPdfDateGroupedSection(
              transactions: transactions,
              categoriesMap: categoriesMap,
              primaryColor: primaryColor,
              neutralDark: neutralDark,
              incomeGreen: incomeGreen,
              expenseRed: expenseRed,
              lightGreyBg: lightGreyBg,
            ),
          ] else if (groupingMode == PdfGroupingMode.byCategory) ...[
            ..._buildPdfCategoryGroupedSection(
              transactions: transactions,
              categoriesMap: categoriesMap,
              primaryColor: primaryColor,
              neutralDark: neutralDark,
              incomeGreen: incomeGreen,
              expenseRed: expenseRed,
              lightGreyBg: lightGreyBg,
            ),
          ] else ...[
            // Full chronological list (without grouping)
            pw.Text(
              'TRANSACTION RECORD (FULL LIST)',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: primaryColor,
              ),
              headerHeight: 22,
              cellHeight: 20,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
              },
              headers: <dynamic>[
                '#',
                'Date & Time',
                'Description',
                'Category',
                'Payment Mode',
                'Type',
                'Amount',
              ],
              data: List<List<dynamic>>.generate(transactions.length, (i) {
                final tx = transactions[i];
                final isIncome = tx.type == TransactionType.income;
                final catName =
                    categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
                final sign = isIncome ? '(+) ' : '(-) ';
                final typeStr = isIncome ? 'IN' : 'OUT';
                return [
                  '${i + 1}',
                  '${AppFormatters.date(tx.date)} ${AppFormatters.time(tx.date)}',
                  tx.title.isNotEmpty ? tx.title : '-',
                  catName,
                  tx.paymentMode,
                  typeStr,
                  '$sign Rs. ${AppFormatters.number(tx.amount)}',
                ];
              }),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Builds transactions grouped by Date for PDF
  static List<pw.Widget> _buildPdfDateGroupedSection({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
    required PdfColor primaryColor,
    required PdfColor neutralDark,
    required PdfColor incomeGreen,
    required PdfColor expenseRed,
    required PdfColor lightGreyBg,
  }) {
    final widgets = <pw.Widget>[];

    widgets.add(
      pw.Text(
        'TRANSACTION RECORD - GROUPED BY DATE',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // Group by formatted date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final key = AppFormatters.date(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    for (final entry in grouped.entries) {
      final dateStr = entry.key;
      final dayTxs = entry.value;
      final dayIn = dayTxs
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final dayOut = dayTxs
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      final dayNet = dayIn - dayOut;

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: lightGreyBg,
            border: pw.Border(
              left: pw.BorderSide(color: primaryColor, width: 3),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                dateStr,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: neutralDark,
                ),
              ),
              pw.Row(
                children: [
                  pw.Text(
                    'In: Rs. ${AppFormatters.number(dayIn)}',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: incomeGreen,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Out: Rs. ${AppFormatters.number(dayOut)}',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: expenseRed,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Net: ${dayNet >= 0 ? '+' : ''}Rs. ${AppFormatters.number(dayNet)}',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: dayNet >= 0 ? incomeGreen : expenseRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      widgets.add(
        pw.TableHelper.fromTextArray(
          headerStyle: const pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: primaryColor,
          ),
          headerHeight: 18,
          cellHeight: 16,
          cellStyle: const pw.TextStyle(fontSize: 7.5),
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.centerLeft,
            5: pw.Alignment.center,
            6: pw.Alignment.centerRight,
          },
          headers: <dynamic>[
            '#',
            'Time',
            'Description',
            'Category',
            'Payment Mode',
            'Type',
            'Amount',
          ],
          data: List<List<dynamic>>.generate(dayTxs.length, (i) {
            final tx = dayTxs[i];
            final isIncome = tx.type == TransactionType.income;
            final catName =
                categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
            final sign = isIncome ? '(+) ' : '(-) ';
            final typeStr = isIncome ? 'IN' : 'OUT';
            return [
              '${i + 1}',
              AppFormatters.time(tx.date),
              tx.title.isNotEmpty ? tx.title : '-',
              catName,
              tx.paymentMode,
              typeStr,
              '$sign Rs. ${AppFormatters.number(tx.amount)}',
            ];
          }),
        ),
      );
    }

    return widgets;
  }

  /// Builds transactions grouped by Category for PDF
  static List<pw.Widget> _buildPdfCategoryGroupedSection({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
    required PdfColor primaryColor,
    required PdfColor neutralDark,
    required PdfColor incomeGreen,
    required PdfColor expenseRed,
    required PdfColor lightGreyBg,
  }) {
    final widgets = <pw.Widget>[];

    widgets.add(
      pw.Text(
        'TRANSACTION RECORD - GROUPED BY CATEGORY',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // Group by categoryId
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      grouped.putIfAbsent(tx.categoryId, () => []).add(tx);
    }

    // Sort categories by total amount descending
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final sumA = a.value.fold(0.0, (s, t) => s + t.amount);
        final sumB = b.value.fold(0.0, (s, t) => s + t.amount);
        return sumB.compareTo(sumA);
      });

    for (final entry in sortedEntries) {
      final catId = entry.key;
      final catTxs = entry.value;
      final catModel = categoriesMap[catId];
      final catName = catModel?.name ?? 'Uncategorized';
      final isExpense = catTxs.any((t) => t.type == TransactionType.expense);
      final totalCatAmount = catTxs.fold(0.0, (s, t) => s + t.amount);

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: lightGreyBg,
            border: pw.Border(
              left: pw.BorderSide(
                color: isExpense ? expenseRed : incomeGreen,
                width: 3,
              ),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '$catName (${isExpense ? "EXPENSE" : "INCOME"})',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: neutralDark,
                ),
              ),
              pw.Text(
                'Total: Rs. ${AppFormatters.number(totalCatAmount)} (${catTxs.length} txns)',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: isExpense ? expenseRed : incomeGreen,
                ),
              ),
            ],
          ),
        ),
      );

      widgets.add(
        pw.TableHelper.fromTextArray(
          headerStyle: const pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: isExpense
                ? const PdfColor.fromInt(0xFF7F1D1D)
                : const PdfColor.fromInt(0xFF14532D),
          ),
          headerHeight: 18,
          cellHeight: 16,
          cellStyle: const pw.TextStyle(fontSize: 7.5),
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.center,
            5: pw.Alignment.centerRight,
          },
          headers: <dynamic>[
            '#',
            'Date & Time',
            'Description',
            'Payment Mode',
            'Type',
            'Amount',
          ],
          data: List<List<dynamic>>.generate(catTxs.length, (i) {
            final tx = catTxs[i];
            final isInc = tx.type == TransactionType.income;
            final sign = isInc ? '(+) ' : '(-) ';
            final typeStr = isInc ? 'IN' : 'OUT';
            return [
              '${i + 1}',
              '${AppFormatters.date(tx.date)} ${AppFormatters.time(tx.date)}',
              tx.title.isNotEmpty ? tx.title : '-',
              tx.paymentMode,
              typeStr,
              '$sign Rs. ${AppFormatters.number(tx.amount)}',
            ];
          }),
        ),
      );
    }

    return widgets;
  }

  /// Exports PDF by prompting user to choose a storage location (via Android SAF or platform picker)
  static Future<ReportExportResult> exportPdfWithLocationPicker({
    required String periodTitle,
    required String dateRangeLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
    PdfGroupingMode groupingMode = PdfGroupingMode.none,
  }) async {
    try {
      final pdfBytes = await generatePdf(
        periodTitle: periodTitle,
        dateRangeLabel: dateRangeLabel,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
        transactions: transactions,
        categoriesMap: categoriesMap,
        groupingMode: groupingMode,
      );

      final cleanPeriod =
          periodTitle.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final groupSlug = groupingMode == PdfGroupingMode.byCategory
          ? '_by_category'
          : (groupingMode == PdfGroupingMode.byDate ? '_by_date' : '');
      final dateSlug = DateTime.now().toIso8601String().substring(0, 10);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'cash_book_$cleanPeriod${groupSlug}_${dateSlug}_$timestamp.pdf';

      // 1. On Android, prompt system storage location picker (ACTION_CREATE_DOCUMENT)
      if (Platform.isAndroid) {
        try {
          final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
            'savePdfWithLocationPicker',
            {'bytes': pdfBytes, 'fileName': defaultFileName},
          );
          if (res != null) {
            final isCancelled = res['userCancelled'] == true;
            if (isCancelled) {
              return const ReportExportResult(
                isSuccess: false,
                isCancelled: true,
              );
            }
            return ReportExportResult(
              isSuccess: true,
              fileUri: res['uri']?.toString(),
              fileName: res['fileName']?.toString() ?? defaultFileName,
            );
          }
        } catch (_) {
          // If native picker not available yet, fall back to direct download
        }
      }

      // 2. Fallback to direct download
      return await downloadPdfReport(
        periodTitle: periodTitle,
        dateRangeLabel: dateRangeLabel,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
        transactions: transactions,
        categoriesMap: categoriesMap,
        groupingMode: groupingMode,
      );
    } catch (e) {
      return ReportExportResult(
        isSuccess: false,
        errorMessage: 'Failed to export PDF: $e',
      );
    }
  }

  /// Downloads and saves the PDF report to the device's Downloads directory
  static Future<ReportExportResult> downloadPdfReport({
    required String periodTitle,
    required String dateRangeLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
    PdfGroupingMode groupingMode = PdfGroupingMode.none,
  }) async {
    try {
      final pdfBytes = await generatePdf(
        periodTitle: periodTitle,
        dateRangeLabel: dateRangeLabel,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
        transactions: transactions,
        categoriesMap: categoriesMap,
        groupingMode: groupingMode,
      );

      final cleanPeriod =
          periodTitle.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final groupSlug = groupingMode == PdfGroupingMode.byCategory
          ? '_by_category'
          : (groupingMode == PdfGroupingMode.byDate ? '_by_date' : '');
      final dateSlug = DateTime.now().toIso8601String().substring(0, 10);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cash_book_$cleanPeriod${groupSlug}_${dateSlug}_$timestamp.pdf';

      // 1. On Android, first try native MethodChannel (MediaStore.Downloads)
      if (Platform.isAndroid) {
        try {
          final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
            'saveToDownloads',
            {'bytes': pdfBytes, 'fileName': fileName},
          );
          if (res != null) {
            return ReportExportResult(
              isSuccess: true,
              filePath: res['filePath']?.toString(),
              fileUri: res['uri']?.toString(),
              fileName: res['fileName']?.toString() ?? fileName,
            );
          }
        } catch (_) {
          // Native channel not available yet (prior to app rebuild) or failed, fallback to file system
        }
      }

      final targetDir = await _resolveDownloadDirectory();
      final filePath = '${targetDir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);

      await file.writeAsBytes(pdfBytes);

      return ReportExportResult(
        isSuccess: true,
        filePath: filePath,
        fileName: fileName,
      );
    } catch (e) {
      try {
        final pdfBytes = await generatePdf(
          periodTitle: periodTitle,
          dateRangeLabel: dateRangeLabel,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          netBalance: netBalance,
          transactions: transactions,
          categoriesMap: categoriesMap,
        );
        final fileName =
            'cash_book_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final fallbackDir = Directory.systemTemp;
        final fallbackPath =
            '${fallbackDir.path}${Platform.pathSeparator}$fileName';
        final file = File(fallbackPath);
        await file.writeAsBytes(pdfBytes);

        return ReportExportResult(
          isSuccess: true,
          filePath: fallbackPath,
          fileName: fileName,
        );
      } catch (fallbackError) {
        return ReportExportResult(
          isSuccess: false,
          errorMessage:
              'Failed to generate or save PDF report: $e (Fallback: $fallbackError)',
        );
      }
    }
  }

  /// Opens the PDF file using the native system viewer or platform handler
  static Future<bool> openPdf({String? filePath, String? fileUri}) async {
    // 1. Try Android MethodChannel
    if (Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('openPdf', {
          'uri': fileUri,
          'filePath': filePath,
        });
        if (res == true) return true;
      } catch (_) {}
    }

    // 2. Desktop platforms (Windows, macOS, Linux)
    if (filePath != null) {
      try {
        if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', '', filePath]);
          return true;
        } else if (Platform.isMacOS) {
          await Process.run('open', [filePath]);
          return true;
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [filePath]);
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// Generates well-formed CSV content for the report
  static String generateCsv({
    required String periodTitle,
    required String dateRangeLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
  }) {
    final buffer = StringBuffer();

    // Summary metadata comments
    buffer.writeln('# Cash Book Financial Report');
    buffer.writeln('# Period Type: $periodTitle');
    buffer.writeln('# Date Range: $dateRangeLabel');
    buffer.writeln('# Generated At: ${AppFormatters.date(DateTime.now())} ${AppFormatters.time(DateTime.now())}');
    buffer.writeln('# Total Cash In (Income): ${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('# Total Cash Out (Expense): ${totalExpense.toStringAsFixed(2)}');
    buffer.writeln('# Net Cash Flow: ${netBalance.toStringAsFixed(2)}');
    buffer.writeln('# Total Transactions: ${transactions.length}');
    buffer.writeln();

    // Table Header
    buffer.writeln('Date,Time,Type,Category,Amount,Payment Mode,Description');

    // Data rows
    for (final tx in transactions) {
      final dateStr = AppFormatters.date(tx.date);
      final timeStr = AppFormatters.time(tx.date);
      final typeStr = tx.type == TransactionType.income ? 'Income' : 'Expense';
      final categoryName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
      final amountStr = tx.amount.toStringAsFixed(2);
      final modeStr = _escapeCsv(tx.paymentMode);
      final titleStr = _escapeCsv(tx.title);

      buffer.writeln('$dateStr,$timeStr,$typeStr,"${_escapeCsv(categoryName)}",$amountStr,"$modeStr","$titleStr"');
    }

    return buffer.toString();
  }

  /// Generates a human-readable text report ready for sharing on messaging apps
  static String generateShareableText({
    required String periodTitle,
    required String dateRangeLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('📊 CASH BOOK REPORT — ${periodTitle.toUpperCase()}');
    buffer.writeln('─────────────────────────────');
    buffer.writeln('📅 Period: $dateRangeLabel');
    buffer.writeln('💵 Total Cash In (Income): ${AppFormatters.currency(totalIncome)}');
    buffer.writeln('💸 Total Cash Out (Expense): ${AppFormatters.currency(totalExpense)}');
    final netSign = netBalance >= 0 ? '+' : '';
    buffer.writeln('📈 Net Balance: $netSign${AppFormatters.currency(netBalance)}');
    buffer.writeln('📝 Transactions: ${transactions.length}');
    buffer.writeln();

    // Group expenses by category
    final expenseTransactions = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenseTransactions.isNotEmpty) {
      final Map<String, double> categorySums = {};
      for (final tx in expenseTransactions) {
        categorySums[tx.categoryId] = (categorySums[tx.categoryId] ?? 0.0) + tx.amount;
      }
      final sortedCats = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      buffer.writeln('📂 TOP EXPENSE CATEGORIES:');
      for (final entry in sortedCats.take(5)) {
        final catName = categoriesMap[entry.key]?.name ?? 'Other';
        final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
        buffer.writeln('• $catName: ${AppFormatters.currency(entry.value)} (${pct.toStringAsFixed(1)}%)');
      }
      buffer.writeln();
    }

    // List of transactions
    if (transactions.isNotEmpty) {
      buffer.writeln('📋 TRANSACTION LIST:');
      final displayList = transactions.take(25).toList();
      for (int i = 0; i < displayList.length; i++) {
        final tx = displayList[i];
        final typeIndicator = tx.type == TransactionType.income ? '(+) In' : '(-) Out';
        final catName = categoriesMap[tx.categoryId]?.name ?? 'Other';
        buffer.writeln('${i + 1}. ${AppFormatters.date(tx.date)} • ${tx.title}');
        buffer.writeln('   $typeIndicator: ${AppFormatters.currency(tx.amount)} via ${tx.paymentMode} [$catName]');
      }
      if (transactions.length > 25) {
        buffer.writeln('... and ${transactions.length - 25} more transactions.');
      }
    } else {
      buffer.writeln('No transactions recorded for this period.');
    }

    buffer.writeln('─────────────────────────────');
    buffer.writeln('Generated with Cash Book App');

    return buffer.toString();
  }

  /// Downloads and saves the CSV report to the device's Downloads directory
  static Future<ReportExportResult> downloadCsvReport({
    required String periodTitle,
    required String dateRangeLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categoriesMap,
  }) async {
    try {
      final csvData = generateCsv(
        periodTitle: periodTitle,
        dateRangeLabel: dateRangeLabel,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
        transactions: transactions,
        categoriesMap: categoriesMap,
      );

      final cleanPeriod = periodTitle.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final dateSlug = DateTime.now().toIso8601String().substring(0, 10);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${AppConstants.csvFilePrefix}${cleanPeriod}_${dateSlug}_$timestamp.csv';

      final targetDir = await _resolveDownloadDirectory();
      final filePath = '${targetDir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);

      await file.writeAsString(csvData);

      return ReportExportResult(
        isSuccess: true,
        filePath: filePath,
        fileName: fileName,
      );
    } catch (e) {
      // If primary download path fails, fallback to temporary directory
      try {
        final csvData = generateCsv(
          periodTitle: periodTitle,
          dateRangeLabel: dateRangeLabel,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          netBalance: netBalance,
          transactions: transactions,
          categoriesMap: categoriesMap,
        );
        final fileName = '${AppConstants.csvFilePrefix}report_${DateTime.now().millisecondsSinceEpoch}.csv';
        final fallbackDir = Directory.systemTemp;
        final fallbackPath = '${fallbackDir.path}${Platform.pathSeparator}$fileName';
        final file = File(fallbackPath);
        await file.writeAsString(csvData);

        return ReportExportResult(
          isSuccess: true,
          filePath: fallbackPath,
          fileName: fileName,
        );
      } catch (fallbackError) {
        return ReportExportResult(
          isSuccess: false,
          errorMessage: 'Failed to write CSV report: $e (Fallback: $fallbackError)',
        );
      }
    }
  }

  /// Resolves the most appropriate public Download directory based on OS
  static Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      // 1. Standard public Download directory (verify write access)
      final androidDownload = Directory('/storage/emulated/0/Download');
      try {
        if (await androidDownload.exists()) {
          final testFile = File('${androidDownload.path}/.access_test');
          await testFile.writeAsString('ok');
          await testFile.delete();
          return androidDownload;
        }
      } catch (_) {}

      // 2. Standard public Documents directory (verify write access)
      final androidDocs = Directory('/storage/emulated/0/Documents');
      try {
        if (await androidDocs.exists()) {
          final testFile = File('${androidDocs.path}/.access_test');
          await testFile.writeAsString('ok');
          await testFile.delete();
          return androidDocs;
        }
      } catch (_) {}

      // 3. App-specific external files Download directory
      final extAppDir = Directory('/storage/emulated/0/Android/data/com.example.cash_book/files/Download');
      try {
        if (!await extAppDir.exists()) {
          await extAppDir.create(recursive: true);
        }
        return extAppDir;
      } catch (_) {}
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final winDownloads = Directory('$userProfile\\Downloads');
        if (await winDownloads.exists()) {
          return winDownloads;
        }
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final macDownloads = Directory('$home/Downloads');
        if (await macDownloads.exists()) {
          return macDownloads;
        }
      }
    }

    // Default system temp fallback
    return Directory.systemTemp;
  }

  static String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }
}
