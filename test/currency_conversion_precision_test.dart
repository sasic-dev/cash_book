import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cash_book/data/models/app_settings.dart';
import 'package:cash_book/data/models/transaction_model.dart';
import 'package:cash_book/data/models/transaction_type.dart';
import 'package:cash_book/data/services/cash_book_database_service.dart';
import 'package:cash_book/data/repositories/cash_book_repository.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';
import 'package:cash_book/ui/utils/formatters.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppFormatters.updateCurrency(
      symbol: '₹',
      decimalDigits: 2,
      symbolBeforeAmount: true,
      useIndianGrouping: true,
      currencyCode: 'INR',
    );
  });

  group('CurrencyConversionHelper - Drift Recovery Tests', () {
    test('Recovers exact integer INR values from USD conversion drift', () {
      // 1000 INR -> 11.56 USD -> 999.94 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(999.94), equals(1000.0));

      // 500 INR -> 5.78 USD -> 499.97 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(499.97), equals(500.0));

      // 100 INR -> 1.16 USD -> 100.34 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(100.34), equals(100.0));

      // 250 INR -> 2.89 USD -> 249.99 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(249.99), equals(250.0));

      // 1500 INR -> 17.34 USD -> 1499.91 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(1499.91), equals(1500.0));

      // 2000 INR -> 23.12 USD -> 1999.88 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(1999.88), equals(2000.0));

      // 50 INR -> 0.58 USD -> 50.17 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(50.17), equals(50.0));

      // 300 INR -> 3.47 USD -> 300.16 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(300.16), equals(300.0));
    });

    test('Recovers exact integer INR values from EUR conversion drift', () {
      // 1000 INR -> 10.64 EUR -> 1000.16 INR
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(1000.16), equals(1000.0));
    });

    test('Preserves clean numbers and real non-drift decimal amounts', () {
      // Clean integers
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(1000.0), equals(1000.0));
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(500.0), equals(500.0));

      // Real user decimals not originating from foreign conversion drift
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(10.50), equals(10.50));
      expect(CurrencyConversionHelper.recoverDriftedInrAmount(99.99), equals(99.99));
    });
  });

  group('Display-Only Currency Conversion Tests', () {
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

    test('Display-Only Conversion: Database records are NEVER mutated when switching currency', () async {
      final now = DateTime.now();

      final tx1 = TransactionModel(
        id: 'tx_display_1000',
        amount: 1000.0,
        baseInrAmount: 1000.0,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        date: now,
        title: 'Dinner',
      );
      final tx2 = TransactionModel(
        id: 'tx_display_500',
        amount: 500.0,
        baseInrAmount: 500.0,
        type: TransactionType.expense,
        categoryId: 'exp_shopping',
        date: now,
        title: 'Shopping',
      );

      await viewModel.addTransaction(tx1);
      await viewModel.addTransaction(tx2);

      // Verify initial INR formatting
      expect(AppFormatters.currency(tx1.amount), contains('1,000.00'));
      expect(AppFormatters.currency(tx1.amount), contains('₹'));

      // Switch to USD: display-only conversion
      AppFormatters.updateCurrency(
        symbol: '\$',
        decimalDigits: 2,
        symbolBeforeAmount: true,
        useIndianGrouping: false,
        currencyCode: 'USD',
      );

      // Formatter formats on-the-fly to USD
      expect(AppFormatters.currency(tx1.amount), equals('\$11.56'));
      expect(AppFormatters.currency(tx2.amount), equals('\$5.78'));

      // CRITICAL: Database records MUST still be exactly 1000.0 and 500.0 (NO DB MUTATION)
      final db = await dbService.database;
      final rawRows = await db.query(CashBookDatabaseService.tableTransactions);
      final dbRow1 = rawRows.firstWhere((r) => r['id'] == 'tx_display_1000');
      final dbRow2 = rawRows.firstWhere((r) => r['id'] == 'tx_display_500');
      expect((dbRow1['amount'] as num).toDouble(), equals(1000.0));
      expect((dbRow2['amount'] as num).toDouble(), equals(500.0));

      // Switch to EUR: display-only conversion
      AppFormatters.updateCurrency(
        symbol: '€',
        decimalDigits: 2,
        symbolBeforeAmount: false,
        useIndianGrouping: false,
        currencyCode: 'EUR',
      );
      expect(AppFormatters.currency(tx1.amount), equals('10.64 €'));

      // Switch back to INR: exact pristine values restored with 0 drift
      AppFormatters.updateCurrency(
        symbol: '₹',
        decimalDigits: 2,
        symbolBeforeAmount: true,
        useIndianGrouping: true,
        currencyCode: 'INR',
      );
      expect(AppFormatters.currency(tx1.amount), contains('1,000.00'));
      expect(AppFormatters.currency(tx1.amount), contains('₹'));
      expect(AppFormatters.currency(tx2.amount), contains('500.00'));
      expect(AppFormatters.currency(tx2.amount), contains('₹'));
    });

    test('Adding and editing amounts in USD display mode persists base INR correctly', () {
      AppFormatters.updateCurrency(
        symbol: '\$',
        decimalDigits: 2,
        symbolBeforeAmount: true,
        useIndianGrouping: false,
        currencyCode: 'USD',
      );

      // User enters $10.00 in the UI
      const enteredDisplayAmount = 10.0;
      final savedBaseInr = AppFormatters.fromDisplayAmount(enteredDisplayAmount);
      expect(savedBaseInr, equals(865.0)); // 10 * 86.50

      // When formatted back in USD
      expect(AppFormatters.currency(savedBaseInr), equals('\$10.00'));

      // When presented for editing in USD
      final forEdit = AppFormatters.toDisplayAmount(savedBaseInr);
      expect(forEdit, equals(10.0));

      // When switched back to INR
      AppFormatters.updateCurrency(
        symbol: '₹',
        decimalDigits: 2,
        symbolBeforeAmount: true,
        useIndianGrouping: true,
        currencyCode: 'INR',
      );
      expect(AppFormatters.currency(savedBaseInr), contains('865.00'));
      expect(AppFormatters.currency(savedBaseInr), contains('₹'));
    });

    test('Custom exchange rates apply immediately to display formatting', () {
      AppFormatters.updateCurrency(
        symbol: '\$',
        decimalDigits: 2,
        symbolBeforeAmount: true,
        useIndianGrouping: false,
        currencyCode: 'USD',
        ratesToInr: {'USD': 100.0, 'EUR': 110.0}, // Custom easy rate
      );

      // 1000 INR / 100.0 = 10.00 USD
      expect(AppFormatters.currency(1000.0), equals('\$10.00'));
      expect(AppFormatters.fromDisplayAmount(10.0), equals(1000.0));
    });

    test('Heals existing legacy drifted amounts in database on open', () async {
      final db = await dbService.database;

      // Case 1: Record had amount stored in USD (11.56) with base_inr_amount (1000.0)
      await db.rawInsert('''
        INSERT INTO ${CashBookDatabaseService.tableTransactions}
        (id, amount, base_inr_amount, type, category_id, date, title, payment_mode)
        VALUES ('tx_legacy_usd_saved', 11.56, 1000.0, 'expense', 'exp_food', '${DateTime.now().toIso8601String()}', 'Legacy USD', 'Cash')
      ''');

      // Trigger healing
      await dbService.onDatabaseOpenForTest(db);

      final healedRow = (await db.query(
        CashBookDatabaseService.tableTransactions,
        where: 'id = ?',
        whereArgs: ['tx_legacy_usd_saved'],
      )).first;

      // amount in DB must now be restored to canonical base INR (1000.0)!
      expect((healedRow['amount'] as num).toDouble(), equals(1000.0));
      expect((healedRow['base_inr_amount'] as num).toDouble(), equals(1000.0));
    });
  });
}
