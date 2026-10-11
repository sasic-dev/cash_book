import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cash_book/data/models/category_model.dart';
import 'package:cash_book/data/models/transaction_model.dart';
import 'package:cash_book/data/models/transaction_type.dart';
import 'package:cash_book/data/repositories/cash_book_repository.dart';
import 'package:cash_book/data/services/cash_book_database_service.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Category and Transaction Models', () {
    test('CategoryModel serialization, toSqliteMap and fromSqliteMap', () {
      final category = CategoryModel(
        id: 'test_cat',
        name: 'Freelancing',
        type: TransactionType.income,
        iconCodePoint: 12345,
        colorValue: 0xFF2E7D32,
      );

      final map = category.toMap();
      final fromMap = CategoryModel.fromMap(map);

      expect(fromMap.id, equals('test_cat'));
      expect(fromMap.name, equals('Freelancing'));
      expect(fromMap.type, equals(TransactionType.income));
      expect(fromMap.iconCodePoint, equals(12345));
      expect(fromMap.colorValue, equals(0xFF2E7D32));

      final sqliteMap = category.toSqliteMap();
      final fromSqlite = CategoryModel.fromSqliteMap(sqliteMap);
      expect(fromSqlite.id, equals('test_cat'));
      expect(fromSqlite.name, equals('Freelancing'));
      expect(fromSqlite.type, equals(TransactionType.income));
      expect(fromSqlite.iconCodePoint, equals(12345));
    });

    test('TransactionModel serialization, toSqliteMap and copyWith', () {
      final tx = TransactionModel(
        id: 'tx_1',
        amount: 2500.50,
        type: TransactionType.income,
        categoryId: 'inc_salary',
        date: DateTime(2026, 10, 4, 10, 30),
        title: 'October Salary',
        paymentMode: 'Bank Transfer',
      );

      final map = tx.toMap();
      final fromMap = TransactionModel.fromMap(map);

      expect(fromMap.id, equals('tx_1'));
      expect(fromMap.amount, equals(2500.50));
      expect(fromMap.type, equals(TransactionType.income));
      expect(fromMap.categoryId, equals('inc_salary'));
      expect(fromMap.title, equals('October Salary'));
      expect(fromMap.paymentMode, equals('Bank Transfer'));

      final sqliteMap = tx.toSqliteMap();
      final fromSqlite = TransactionModel.fromSqliteMap(sqliteMap);
      expect(fromSqlite.id, equals('tx_1'));
      expect(fromSqlite.amount, equals(2500.50));
      expect(fromSqlite.type, equals(TransactionType.income));

      final updated = tx.copyWith(amount: 3000.0);
      expect(updated.amount, equals(3000.0));
      expect(updated.title, equals('October Salary'));
    });
  });

  group('CashBookViewModel logic & category management with SQLite', () {
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

    test('Initializes SQLite tables and default categories', () {
      expect(viewModel.categories.isNotEmpty, isTrue);
      expect(viewModel.expenseCategories.isNotEmpty, isTrue);
      expect(viewModel.incomeCategories.isNotEmpty, isTrue);
    });

    test('Adds custom category and persists to SQLite database', () async {
      final newCat = CategoryModel(
        id: 'cat_custom_gym',
        name: 'Gym & Fitness',
        type: TransactionType.expense,
        iconCodePoint: 500,
        colorValue: 0xFFD81B60,
        isDefault: false,
      );

      await viewModel.addCategory(newCat);

      expect(viewModel.categories.any((c) => c.id == 'cat_custom_gym'), isTrue);
      expect(viewModel.expenseCategories.any((c) => c.name == 'Gym & Fitness'), isTrue);

      // Verify directly from database
      final fromDb = await repository.getCategories();
      expect(fromDb.any((c) => c.id == 'cat_custom_gym'), isTrue);
    });

    test('Deletes custom category and reassigns transactions in SQLite', () async {
      final customCat = CategoryModel(
        id: 'cat_custom_snacks',
        name: 'Evening Snacks',
        type: TransactionType.expense,
        iconCodePoint: 600,
        colorValue: 0xFFFB8C00,
        isDefault: false,
      );
      await viewModel.addCategory(customCat);

      final tx = TransactionModel(
        id: 'tx_snack_1',
        amount: 80.0,
        type: TransactionType.expense,
        categoryId: 'cat_custom_snacks',
        date: DateTime.now(),
        title: 'Tea & Samosa',
      );
      await viewModel.addTransaction(tx);

      expect(viewModel.transactions.first.categoryId, equals('cat_custom_snacks'));

      final deleted = await viewModel.deleteCategory('cat_custom_snacks');
      expect(deleted, isTrue);
      expect(viewModel.categories.any((c) => c.id == 'cat_custom_snacks'), isFalse);

      // Reassigned to fallback 'exp_other'
      expect(viewModel.transactions.first.categoryId, equals('exp_other'));

      // Verify in DB directly
      final dbTxList = await repository.getTransactions();
      expect(dbTxList.first.categoryId, equals('exp_other'));
    });

    test('Prevents deleting default category in SQLite', () async {
      final deleted = await viewModel.deleteCategory('exp_food');
      expect(deleted, isFalse);
      expect(viewModel.categories.any((c) => c.id == 'exp_food'), isTrue);
    });

    test('Calculates balance, income, expense accurately with SQLite records', () async {
      viewModel.setDateFilter(DateFilter.all);

      await viewModel.addTransaction(TransactionModel(
        id: 'tx_1',
        amount: 50000.0,
        type: TransactionType.income,
        categoryId: 'inc_salary',
        date: DateTime.now(),
        title: 'Salary credit',
      ));

      await viewModel.addTransaction(TransactionModel(
        id: 'tx_2',
        amount: 12000.0,
        type: TransactionType.expense,
        categoryId: 'exp_rent',
        date: DateTime.now(),
        title: 'House rent',
      ));

      await viewModel.addTransaction(TransactionModel(
        id: 'tx_3',
        amount: 3500.0,
        type: TransactionType.expense,
        categoryId: 'exp_groceries',
        date: DateTime.now(),
        title: 'Supermarket shopping',
      ));

      expect(viewModel.totalIncome, equals(50000.0));
      expect(viewModel.totalExpense, equals(15500.0));
      expect(viewModel.totalBalance, equals(34500.0));

      final fromDb = await repository.getTransactions();
      expect(fromDb.length, equals(3));
    });

    test('Filters by type correctly', () async {
      viewModel.setDateFilter(DateFilter.all);

      await viewModel.addTransaction(TransactionModel(
        id: 'tx_inc',
        amount: 1000.0,
        type: TransactionType.income,
        categoryId: 'inc_gifts',
        date: DateTime.now(),
        title: 'Gift',
      ));

      await viewModel.addTransaction(TransactionModel(
        id: 'tx_exp',
        amount: 500.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: DateTime.now(),
        title: 'Dinner',
      ));

      viewModel.setTypeFilter(TransactionType.income);
      expect(viewModel.filteredTransactions.length, equals(1));
      expect(viewModel.filteredTransactions.first.title, equals('Gift'));

      viewModel.setTypeFilter(TransactionType.expense);
      expect(viewModel.filteredTransactions.length, equals(1));
      expect(viewModel.filteredTransactions.first.title, equals('Dinner'));
    });

    test('Filters by search query', () async {
      viewModel.setDateFilter(DateFilter.all);

      await viewModel.addTransaction(TransactionModel(
        id: 'tx_1',
        amount: 300.0,
        type: TransactionType.expense,
        categoryId: 'exp_transport',
        date: DateTime.now(),
        title: 'Metro ticket',
        paymentMode: 'Online / UPI',
      ));

      await viewModel.addTransaction(TransactionModel(
        id: 'tx_2',
        amount: 400.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: DateTime.now(),
        title: 'Lunch with colleagues',
        paymentMode: 'Cash',
      ));

      viewModel.setSearchQuery('Metro');
      expect(viewModel.filteredTransactions.length, equals(1));
      expect(viewModel.filteredTransactions.first.title, equals('Metro ticket'));

      viewModel.setSearchQuery('Cash');
      expect(viewModel.filteredTransactions.length, equals(1));
      expect(viewModel.filteredTransactions.first.title, equals('Lunch with colleagues'));
    });
  });
}
