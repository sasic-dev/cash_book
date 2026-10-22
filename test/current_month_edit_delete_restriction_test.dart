import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cash_book/data/models/split_expense_model.dart';
import 'package:cash_book/data/models/transaction_model.dart';
import 'package:cash_book/data/models/transaction_type.dart';
import 'package:cash_book/data/repositories/cash_book_repository.dart';
import 'package:cash_book/data/services/cash_book_database_service.dart';
import 'package:cash_book/ui/screens/add_edit_split_expense_screen.dart';
import 'package:cash_book/ui/screens/add_edit_transaction_screen.dart';
import 'package:cash_book/ui/utils/formatters.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';
import 'package:cash_book/ui/widgets/transaction_list_tile.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Current Month Verification and Edit/Delete Restriction Logic', () {
    late CashBookDatabaseService dbService;
    late CashBookRepository repository;
    late CashBookViewModel viewModel;

    setUp(() async {
      dbService = CashBookDatabaseService(customDbPath: inMemoryDatabasePath);
      repository = CashBookRepository(dbService: dbService);
      viewModel = CashBookViewModel(repository: repository);
      await viewModel.init();
    });

    tearDown(() async {
      await dbService.close();
    });

    test('AppFormatters.isCurrentMonth accurately identifies current and other months', () {
      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 15);
      final pastMonthDate = DateTime(now.year, now.month - 1, 15);
      final pastYearDate = DateTime(now.year - 1, now.month, 15);
      final nextMonthDate = DateTime(now.year, now.month + 1, 15);

      expect(AppFormatters.isCurrentMonth(currentMonthDate), isTrue);
      expect(AppFormatters.isCurrentMonth(pastMonthDate), isFalse);
      expect(AppFormatters.isCurrentMonth(pastYearDate), isFalse);
      expect(AppFormatters.isCurrentMonth(nextMonthDate), isFalse);
    });

    test('CashBookViewModel allows edit and delete for current month transactions only', () async {
      final now = DateTime.now();
      final currentMonthTx = TransactionModel(
        id: 'tx_current_month',
        amount: 500.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: DateTime(now.year, now.month, 5),
        title: 'Current Month Lunch',
        paymentMode: 'Cash',
      );

      final pastMonthTx = TransactionModel(
        id: 'tx_past_month',
        amount: 800.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: DateTime(now.year, now.month - 1, 10),
        title: 'Last Month Grocery',
        paymentMode: 'Cash',
      );

      await viewModel.addTransaction(currentMonthTx);
      await viewModel.addTransaction(pastMonthTx);

      expect(viewModel.transactions.length, equals(2));

      // 1. Edit current month transaction -> permitted
      final updatedCurrent = currentMonthTx.copyWith(amount: 550.0);
      final updateSuccess = await viewModel.updateTransaction(updatedCurrent);
      expect(updateSuccess, isTrue);
      expect(viewModel.transactions.firstWhere((t) => t.id == 'tx_current_month').amount, equals(550.0));

      // 2. Edit past month transaction -> blocked
      final updatedPast = pastMonthTx.copyWith(amount: 900.0);
      final pastUpdateSuccess = await viewModel.updateTransaction(updatedPast);
      expect(pastUpdateSuccess, isFalse);
      expect(viewModel.transactions.firstWhere((t) => t.id == 'tx_past_month').amount, equals(800.0));

      // 3. Move current month transaction into a past month -> blocked
      final moveCurrentToPast = currentMonthTx.copyWith(date: DateTime(now.year, now.month - 1, 5));
      final moveSuccess = await viewModel.updateTransaction(moveCurrentToPast);
      expect(moveSuccess, isFalse);

      // 4. Delete past month transaction -> blocked
      final pastDeleteSuccess = await viewModel.deleteTransaction(pastMonthTx.id);
      expect(pastDeleteSuccess, isFalse);
      expect(viewModel.transactions.any((t) => t.id == 'tx_past_month'), isTrue);

      // 5. Delete current month transaction -> permitted
      final currentDeleteSuccess = await viewModel.deleteTransaction(currentMonthTx.id);
      expect(currentDeleteSuccess, isTrue);
      expect(viewModel.transactions.any((t) => t.id == 'tx_current_month'), isFalse);
    });

    test('CashBookViewModel allows edit and delete for current month split expenses only', () async {
      final now = DateTime.now();
      final currentMonthExp = SplitExpenseModel(
        id: 'exp_current_month',
        title: 'Team Outing Current Month',
        totalAmount: 1200.0,
        date: DateTime(now.year, now.month, 8),
        paidByPersonId: viewModel.currentUser.id,
        splitType: 'equal',
        splits: [ExpenseSplitItem(personId: viewModel.currentUser.id, amount: 1200.0)],
        createdAt: DateTime.now(),
      );

      final pastMonthExp = SplitExpenseModel(
        id: 'exp_past_month',
        title: 'Team Outing Past Month',
        totalAmount: 1500.0,
        date: DateTime(now.year, now.month - 1, 8),
        paidByPersonId: viewModel.currentUser.id,
        splitType: 'equal',
        splits: [ExpenseSplitItem(personId: viewModel.currentUser.id, amount: 1500.0)],
        createdAt: DateTime.now(),
      );

      final initialCount = viewModel.splitExpenses.length;
      await viewModel.addSplitExpense(currentMonthExp);
      await viewModel.addSplitExpense(pastMonthExp);

      expect(viewModel.splitExpenses.length, equals(initialCount + 2));

      // 1. Edit current month split expense -> permitted
      final updatedCurrent = currentMonthExp.copyWith(totalAmount: 1300.0);
      final updateSuccess = await viewModel.updateSplitExpense(updatedCurrent);
      expect(updateSuccess, isTrue);
      expect(viewModel.splitExpenses.firstWhere((e) => e.id == 'exp_current_month').totalAmount, equals(1300.0));

      // 2. Edit past month split expense -> blocked
      final updatedPast = pastMonthExp.copyWith(totalAmount: 2000.0);
      final pastUpdateSuccess = await viewModel.updateSplitExpense(updatedPast);
      expect(pastUpdateSuccess, isFalse);
      expect(viewModel.splitExpenses.firstWhere((e) => e.id == 'exp_past_month').totalAmount, equals(1500.0));

      // 3. Delete past month split expense -> blocked
      final pastDeleteSuccess = await viewModel.deleteSplitExpense(pastMonthExp.id);
      expect(pastDeleteSuccess, isFalse);
      expect(viewModel.splitExpenses.any((e) => e.id == 'exp_past_month'), isTrue);

      // 4. Delete current month split expense -> permitted
      final currentDeleteSuccess = await viewModel.deleteSplitExpense(currentMonthExp.id);
      expect(currentDeleteSuccess, isTrue);
      expect(viewModel.splitExpenses.any((e) => e.id == 'exp_current_month'), isFalse);
    });
  });

  group('UI Screens and Widgets Current Month Edit/Delete Prevention', () {
    late CashBookDatabaseService dbService;
    late CashBookRepository repository;
    late CashBookViewModel viewModel;

    setUp(() async {
      dbService = CashBookDatabaseService(customDbPath: inMemoryDatabasePath);
      repository = CashBookRepository(dbService: dbService);
      viewModel = CashBookViewModel(repository: repository);
      await viewModel.init();
    });

    tearDown(() async {
      await dbService.close();
    });

    testWidgets('TransactionListTile disables swipe to delete and shows badge for past month', (tester) async {
      final now = DateTime.now();
      final pastMonthTx = TransactionModel(
        id: 'tx_tile_past',
        amount: 250.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: DateTime(now.year, now.month - 1, 15),
        title: 'Past Dinner',
        paymentMode: 'Cash',
      );

      final currentMonthTx = TransactionModel(
        id: 'tx_tile_current',
        amount: 300.0,
        type: TransactionType.income,
        categoryId: 'inc_salary',
        date: DateTime(now.year, now.month, 15),
        title: 'Current Salary',
        paymentMode: 'Bank Transfer',
      );

      // Render past month tile
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: pastMonthTx,
              category: viewModel.getCategoryById(pastMonthTx.categoryId),
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Past Month'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, equals(DismissDirection.none));

      // Render current month tile
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: currentMonthTx,
              category: viewModel.getCategoryById(currentMonthTx.categoryId),
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Past Month'), findsNothing);
      final currentDismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(currentDismissible.direction, equals(DismissDirection.endToStart));
    });

    testWidgets('AddEditTransactionScreen locks form and disables delete when viewing past month entry', (tester) async {
      final now = DateTime.now();
      final pastMonthTx = TransactionModel(
        id: 'tx_screen_past',
        amount: 450.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: DateTime(now.year, now.month - 1, 12),
        title: 'Old Entry',
        paymentMode: 'Cash',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AddEditTransactionScreen(
            viewModel: viewModel,
            initialTransaction: pastMonthTx,
          ),
        ),
      );

      // Header should show locked view title
      expect(find.text('View Entry (Locked)'), findsOneWidget);

      // Delete icon button should NOT be present in AppBar actions
      expect(find.byIcon(Icons.delete_rounded), findsNothing);

      // Past month read-only banner should be present
      expect(find.text('Past Month Record (Read-Only)'), findsOneWidget);

      // Locked button should be shown at bottom
      expect(find.text('Locked — Past Month Record'), findsOneWidget);

      // Save / Update button should NOT be active
      expect(find.text('Update Entry'), findsNothing);
    });

    testWidgets('AddEditTransactionScreen allows editing and deleting for current month entry', (tester) async {
      final now = DateTime.now();
      final currentMonthTx = TransactionModel(
        id: 'tx_screen_current',
        amount: 700.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: DateTime(now.year, now.month, 10),
        title: 'Current Entry',
        paymentMode: 'Cash',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AddEditTransactionScreen(
            viewModel: viewModel,
            initialTransaction: currentMonthTx,
          ),
        ),
      );

      // Header should show Edit Entry
      expect(find.text('Edit Entry'), findsOneWidget);

      // Delete button is present in AppBar
      expect(find.byIcon(Icons.delete_rounded), findsOneWidget);

      // Past month banner should NOT be present
      expect(find.text('Past Month Record (Read-Only)'), findsNothing);

      // Update button is present and active
      expect(find.text('Update Entry'), findsOneWidget);
    });

    testWidgets('AddEditSplitExpenseScreen locks form and disables delete when viewing past month split expense', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final pastMonthExp = SplitExpenseModel(
        id: 'exp_screen_past',
        title: 'Past Cafe Split',
        totalAmount: 600.0,
        date: DateTime(now.year, now.month - 1, 14),
        paidByPersonId: viewModel.currentUser.id,
        splitType: 'equal',
        splits: [ExpenseSplitItem(personId: viewModel.currentUser.id, amount: 600.0)],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AddEditSplitExpenseScreen(
            viewModel: viewModel,
            initialExpense: pastMonthExp,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header should show locked title
      expect(find.text('View Split Expense (Locked)'), findsOneWidget);

      // Delete icon button should NOT be present
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // Past month read-only banner should be present
      expect(find.text('Past Month Record (Read-Only)'), findsOneWidget);

      // Locked button shown at bottom
      expect(find.text('Locked — Past Month Record'), findsOneWidget);

      // Update button should NOT be present
      expect(find.text('Update Split Expense'), findsNothing);
    });
  });
}
