import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cash_book/data/models/category_model.dart';
import 'package:cash_book/data/models/person_model.dart';
import 'package:cash_book/data/models/transaction_model.dart';
import 'package:cash_book/data/models/transaction_type.dart';
import 'package:cash_book/data/services/report_export_service.dart';
import 'package:cash_book/ui/screens/reports_screen.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('ReportExportService Unit Tests', () {
    final now = DateTime(2026, 10, 4, 14, 30);
    final transactions = [
      TransactionModel(
        id: 'tx1',
        title: 'October Salary',
        amount: 50000.0,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        date: now,
        paymentMode: 'Bank Transfer',
      ),
      TransactionModel(
        id: 'tx2',
        title: 'Team Dinner',
        amount: 1500.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        date: now,
        paymentMode: 'UPI',
      ),
    ];

    final categoriesMap = {
      'cat_salary': const CategoryModel(
        id: 'cat_salary',
        name: 'Salary',
        iconCodePoint: 0xe84f,
        colorValue: 0xFF4CAF50,
        type: TransactionType.income,
      ),
      'cat_food': const CategoryModel(
        id: 'cat_food',
        name: 'Food & Dining',
        iconCodePoint: 0xe532,
        colorValue: 0xFFFF5722,
        type: TransactionType.expense,
      ),
    };

    test('generatePdf produces valid PDF byte stream with header', () async {
      final pdfBytes = await ReportExportService.generatePdf(
        periodTitle: 'Monthly Report',
        dateRangeLabel: 'October 2026',
        totalIncome: 50000.0,
        totalExpense: 1500.0,
        netBalance: 48500.0,
        transactions: transactions,
        categoriesMap: categoriesMap,
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF files start with %PDF-
      final headerString = String.fromCharCodes(pdfBytes.take(5));
      expect(headerString, equals('%PDF-'));
    });

    test('generatePdf with groupingMode byDate produces valid PDF byte stream', () async {
      final pdfBytes = await ReportExportService.generatePdf(
        periodTitle: 'Monthly Report',
        dateRangeLabel: 'October 2026',
        totalIncome: 50000.0,
        totalExpense: 1500.0,
        netBalance: 48500.0,
        transactions: transactions,
        categoriesMap: categoriesMap,
        groupingMode: PdfGroupingMode.byDate,
      );

      expect(pdfBytes, isNotEmpty);
      final headerString = String.fromCharCodes(pdfBytes.take(5));
      expect(headerString, equals('%PDF-'));
    });

    test('generatePdf with groupingMode byCategory produces valid PDF byte stream', () async {
      final pdfBytes = await ReportExportService.generatePdf(
        periodTitle: 'Monthly Report',
        dateRangeLabel: 'October 2026',
        totalIncome: 50000.0,
        totalExpense: 1500.0,
        netBalance: 48500.0,
        transactions: transactions,
        categoriesMap: categoriesMap,
        groupingMode: PdfGroupingMode.byCategory,
      );

      expect(pdfBytes, isNotEmpty);
      final headerString = String.fromCharCodes(pdfBytes.take(5));
      expect(headerString, equals('%PDF-'));
    });

    test('generateCsv generates structured CSV with headers and data', () {
      final csv = ReportExportService.generateCsv(
        periodTitle: 'Monthly Report',
        dateRangeLabel: 'October 2026',
        totalIncome: 50000.0,
        totalExpense: 1500.0,
        netBalance: 48500.0,
        transactions: transactions,
        categoriesMap: categoriesMap,
      );

      expect(csv, contains('# Cash Book Financial Report'));
      expect(csv, contains('# Period Type: Monthly Report'));
      expect(csv, contains('# Total Cash In (Income): 50000.00'));
      expect(csv, contains('# Total Cash Out (Expense): 1500.00'));
      expect(csv, contains('Date,Time,Type,Category,Amount,Payment Mode,Description'));
      expect(csv, contains('October Salary'));
      expect(csv, contains('Team Dinner'));
      expect(csv, contains('50000.00'));
      expect(csv, contains('1500.00'));
    });

    test('generateShareableText produces formatted summary for text export', () {
      final text = ReportExportService.generateShareableText(
        periodTitle: 'Monthly Report',
        dateRangeLabel: 'October 2026',
        totalIncome: 50000.0,
        totalExpense: 1500.0,
        netBalance: 48500.0,
        transactions: transactions,
        categoriesMap: categoriesMap,
      );

      expect(text, contains('CASH BOOK REPORT — MONTHLY REPORT'));
      expect(text, contains('October 2026'));
      expect(text, contains('Total Cash In'));
      expect(text, contains('Total Cash Out'));
      expect(text, contains('TOP EXPENSE CATEGORIES:'));
      expect(text, contains('Food & Dining'));
      expect(text, contains('October Salary'));
      expect(text, contains('Team Dinner'));
    });
  });

  group('ReportsScreen Widget Tests', () {
    testWidgets('Renders Daily, Weekly, Monthly segments and PDF download actions',
        (WidgetTester tester) async {
      final viewModel = CashBookViewModel();
      final now = DateTime.now();

      viewModel.seedTestData(
        categories: [
          const CategoryModel(
            id: 'cat_salary',
            name: 'Salary',
            iconCodePoint: 0xe84f,
            colorValue: 0xFF4CAF50,
            type: TransactionType.income,
          ),
          const CategoryModel(
            id: 'cat_food',
            name: 'Food & Dining',
            iconCodePoint: 0xe532,
            colorValue: 0xFFFF5722,
            type: TransactionType.expense,
          ),
        ],
        transactions: [
          TransactionModel(
            id: 'tx1',
            title: 'Freelance Project',
            amount: 25000.0,
            type: TransactionType.income,
            categoryId: 'cat_salary',
            date: now,
            paymentMode: 'Bank Transfer',
          ),
          TransactionModel(
            id: 'tx2',
            title: 'Groceries Market',
            amount: 2500.0,
            type: TransactionType.expense,
            categoryId: 'cat_food',
            date: now,
            paymentMode: 'UPI',
          ),
        ],
        people: [PersonModel.defaultCurrentUser],
      );

      await tester.pumpWidget(MaterialApp(
        home: ReportsScreen(viewModel: viewModel),
      ));
      await tester.pumpAndSettle();

      // Check App Bar and Period Segmented Controls
      expect(find.text('Reports & Statements'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Verify Share button is removed
      expect(find.byIcon(Icons.share_rounded), findsNothing);

      // Verify PDF Download button is present
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsAtLeastNWidgets(1));
      expect(find.text('Download PDF Statement'), findsOneWidget);

      // Check Total Cash In and Total Cash Out
      expect(find.text('Total Cash In'), findsOneWidget);
      expect(find.text('Total Cash Out'), findsOneWidget);

      // Verify Category Breakdown section is present with Expense & Income tabs
      expect(find.text('Category Breakdown'), findsOneWidget);
      expect(find.textContaining('Expenses (1)'), findsOneWidget);
      expect(find.textContaining('Income (1)'), findsOneWidget);

      // Verify Transactions tab selector is removed from reports page
      expect(find.textContaining('Transactions (2)'), findsNothing);

      // Under Expenses, Food & Dining should be listed
      await tester.ensureVisible(find.text('Food & Dining'));
      expect(find.text('Food & Dining'), findsOneWidget);

      // Tap on Food & Dining to drill down into its records
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();
      expect(find.text('Groceries Market'), findsOneWidget);

      // Switch to Income category breakdown tab
      await tester.ensureVisible(find.textContaining('Income (1)'));
      await tester.tap(find.textContaining('Income (1)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salary'));
      expect(find.text('Salary'), findsOneWidget);

      // Tap on Salary to drill down into its records
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();
      expect(find.text('Freelance Project'), findsOneWidget);

      // Switch to Daily
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      // Tap Download PDF Statement to open format picker sheet
      await tester.ensureVisible(find.text('Download PDF Statement'));
      await tester.tap(find.text('Download PDF Statement'));
      await tester.pumpAndSettle();

      // Verify format picker options are shown
      expect(find.text('Download Statement'), findsOneWidget);
      expect(find.text('Without Group (Full List)'), findsOneWidget);
      expect(find.text('Group by Date (Dates List)'), findsOneWidget);
      expect(find.text('Group by Category'), findsOneWidget);
    });
  });
}
