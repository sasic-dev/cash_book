import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cash_book/data/models/app_settings.dart';
import 'package:cash_book/data/models/category_model.dart';
import 'package:cash_book/data/models/person_model.dart';
import 'package:cash_book/data/models/settlement_model.dart';
import 'package:cash_book/data/models/split_expense_model.dart';
import 'package:cash_book/data/models/split_group_model.dart';
import 'package:cash_book/data/models/transaction_model.dart';
import 'package:cash_book/data/repositories/cash_book_repository.dart';
import 'package:cash_book/ui/utils/formatters.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';
import 'package:cash_book/ui/view_models/settings_view_model.dart';
import 'package:cash_book/ui/screens/settings_screen.dart';
import 'package:cash_book/ui/widgets/user_account_setup_dialog.dart';

class FakeCashBookRepository implements ICashBookRepository {
  List<PersonModel> people = [PersonModel.defaultCurrentUser];
  List<CategoryModel> categories = CategoryModel.defaultCategories;
  List<TransactionModel> transactions = [];
  List<SplitGroupModel> groups = [];
  List<SplitExpenseModel> splitExpenses = [];
  List<SettlementModel> settlements = [];

  @override
  Future<void> init() async {}
  @override
  Future<List<PersonModel>> getPersons() async => people;
  @override
  Future<void> updatePerson(PersonModel person) async {
    final idx = people.indexWhere((p) => p.id == person.id);
    if (idx != -1) people[idx] = person;
  }
  @override
  Future<void> addPerson(PersonModel person) async => people.add(person);
  @override
  Future<bool> deletePerson(String id) async {
    people.removeWhere((p) => p.id == id);
    return true;
  }
  @override
  Future<List<CategoryModel>> getCategories() async => categories;
  @override
  Future<void> addCategory(CategoryModel category) async => categories.add(category);
  @override
  Future<void> updateCategory(CategoryModel category) async {}
  @override
  Future<bool> deleteCategory(String id) async => true;
  @override
  Future<void> resetCategoriesToDefaults() async {}
  @override
  Future<List<TransactionModel>> getTransactions() async => transactions;
  @override
  Future<void> addTransaction(TransactionModel transaction) async => transactions.add(transaction);
  @override
  Future<void> updateTransaction(TransactionModel transaction) async {}
  @override
  Future<void> deleteTransaction(String id) async {}
  @override
  Future<void> convertAllCurrencyAmounts(double factor, {String? fromCurrency, String? toCurrency, Map<String, double>? ratesToInr}) async {}
  @override
  Future<List<SplitGroupModel>> getGroups() async => groups;
  @override
  Future<void> addGroup(SplitGroupModel group) async => groups.add(group);
  @override
  Future<void> updateGroup(SplitGroupModel group) async {}
  @override
  Future<void> deleteGroup(String id) async => groups.removeWhere((g) => g.id == id);
  @override
  Future<List<SplitExpenseModel>> getSplitExpenses({String? groupId, String? personId}) async => splitExpenses;
  @override
  Future<void> addSplitExpense(SplitExpenseModel expense) async => splitExpenses.add(expense);
  @override
  Future<void> updateSplitExpense(SplitExpenseModel expense) async {}
  @override
  Future<void> deleteSplitExpense(String id) async => splitExpenses.removeWhere((e) => e.id == id);
  @override
  Future<List<SettlementModel>> getSettlements({String? groupId, String? personId}) async => settlements;
  @override
  Future<void> addSettlement(SettlementModel settlement) async => settlements.add(settlement);
  @override
  Future<void> deleteSettlement(String id) async => settlements.removeWhere((s) => s.id == id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings Model Tests', () {
    test('Default values are correct', () {
      const settings = AppSettings();
      expect(settings.primaryColorValue, equals(0xFF1E40AF));
      expect(settings.themeMode, equals(ThemeMode.light));
      expect(settings.fontFamily, equals('Inter'));
      expect(settings.fontScale, equals(1.0));
      expect(settings.currencyCode, equals('INR'));
      expect(settings.currencySymbol, equals('₹'));
      expect(settings.symbolBeforeAmount, isTrue);
      expect(settings.decimalDigits, equals(2));
      expect(settings.useIndianGrouping, isTrue);
      expect(settings.dateFormatPattern, equals('dd MMM yyyy'));
      expect(settings.is24HourTime, isFalse);
    });

    test('Serialization toMap and fromMap works seamlessly', () {
      const original = AppSettings(
        primaryColorValue: 0xFF059669,
        themeMode: ThemeMode.dark,
        fontFamily: 'Poppins',
        fontScale: 1.15,
        currencyCode: 'USD',
        currencySymbol: '\$',
        symbolBeforeAmount: true,
        decimalDigits: 2,
        useIndianGrouping: false,
        dateFormatPattern: 'yyyy-MM-dd',
        is24HourTime: true,
      );

      final map = original.toMap();
      final restored = AppSettings.fromMap(map);

      expect(restored.primaryColorValue, equals(original.primaryColorValue));
      expect(restored.themeMode, equals(original.themeMode));
      expect(restored.fontFamily, equals(original.fontFamily));
      expect(restored.fontScale, equals(original.fontScale));
      expect(restored.currencyCode, equals(original.currencyCode));
      expect(restored.currencySymbol, equals(original.currencySymbol));
      expect(restored.symbolBeforeAmount, equals(original.symbolBeforeAmount));
      expect(restored.decimalDigits, equals(original.decimalDigits));
      expect(restored.useIndianGrouping, equals(original.useIndianGrouping));
      expect(restored.dateFormatPattern, equals('yyyy-MM-dd'));
      expect(restored.is24HourTime, isTrue);
    });

    test('fromMap with missing or null is24HourTime and dateFormatPattern falls back gracefully', () {
      final legacyMap = <String, dynamic>{
        'primaryColorValue': 0xFF1E40AF,
        'themeMode': 'light',
        'fontFamily': 'Inter',
        'fontScale': 1.0,
        'currencyCode': 'INR',
        'currencySymbol': '₹',
        'symbolBeforeAmount': true,
        'decimalDigits': 2,
        'useIndianGrouping': true,
        // is24HourTime and dateFormatPattern missing
      };

      final restored = AppSettings.fromMap(legacyMap);
      expect(restored.is24HourTime, isFalse);
      expect(restored.dateFormatPattern, equals('dd MMM yyyy'));
    });

    test('copyWith updates specified fields only', () {
      const original = AppSettings();
      final updated = original.copyWith(
        currencyCode: 'EUR',
        currencySymbol: '€',
        symbolBeforeAmount: false,
        dateFormatPattern: 'dd/MM/yyyy',
        is24HourTime: true,
      );

      expect(updated.currencyCode, equals('EUR'));
      expect(updated.currencySymbol, equals('€'));
      expect(updated.symbolBeforeAmount, isFalse);
      expect(updated.dateFormatPattern, equals('dd/MM/yyyy'));
      expect(updated.is24HourTime, isTrue);
      expect(updated.fontFamily, equals('Inter'));
      expect(updated.primaryColorValue, equals(original.primaryColorValue));
    });
  });

  group('AppFormatters Currency, Date & Time Tests', () {
    test('Formats with INR and Indian grouping', () {
      AppFormatters.updateCurrency(
        symbol: '₹',
        decimalDigits: 2,
        symbolBeforeAmount: true,
        useIndianGrouping: true,
      );

      expect(AppFormatters.currencySymbol, equals('₹'));
      expect(AppFormatters.currency(100000), contains('1,00,000.00'));
    });

    test('Formats with USD prefix and Western grouping', () {
      AppFormatters.updateCurrency(
        symbol: '\$',
        decimalDigits: 2,
        symbolBeforeAmount: true,
        useIndianGrouping: false,
      );

      expect(AppFormatters.currencySymbol, equals('\$'));
      final formatted = AppFormatters.currency(100000);
      expect(formatted, contains('\$'));
      expect(formatted, contains('100,000.00'));
    });

    test('Formats with EUR suffix and 2 decimals', () {
      AppFormatters.updateCurrency(
        symbol: '€',
        decimalDigits: 2,
        symbolBeforeAmount: false,
        useIndianGrouping: false,
      );

      final formatted = AppFormatters.currency(250.75);
      expect(formatted, equals('250.75 €'));
    });

    test('Formats with JPY whole numbers (0 decimals)', () {
      AppFormatters.updateCurrency(
        symbol: '¥',
        decimalDigits: 0,
        symbolBeforeAmount: true,
        useIndianGrouping: false,
      );

      final formatted = AppFormatters.currency(5000);
      expect(formatted, contains('5,000'));
      expect(formatted, isNot(contains('.00')));
    });

    test('Date formatting adapts to configured pattern', () {
      final sampleDate = DateTime(2026, 10, 6, 14, 30);

      AppFormatters.updateDateTimeFormat(
        dateFormatPattern: 'yyyy-MM-dd',
        is24Hour: false,
      );
      expect(AppFormatters.date(sampleDate), equals('2026-10-06'));

      AppFormatters.updateDateTimeFormat(
        dateFormatPattern: 'dd/MM/yyyy',
        is24Hour: false,
      );
      expect(AppFormatters.date(sampleDate), equals('06/10/2026'));
    });

    test('Time formatting adapts to 12-hour and 24-hour modes', () {
      final sampleTime = DateTime(2026, 10, 6, 14, 30);

      AppFormatters.updateDateTimeFormat(
        dateFormatPattern: 'dd MMM yyyy',
        is24Hour: false,
      );
      expect(AppFormatters.time(sampleTime), contains('02:30'));
      expect(AppFormatters.time(sampleTime), contains('PM'));

      AppFormatters.updateDateTimeFormat(
        dateFormatPattern: 'dd MMM yyyy',
        is24Hour: true,
      );
      expect(AppFormatters.time(sampleTime), equals('14:30'));
    });
  });

  group('SettingsViewModel Unit Tests', () {
    test('Modifying settings updates properties and notifies listeners', () async {
      final vm = SettingsViewModel();
      await vm.init();

      int notifications = 0;
      vm.addListener(() => notifications++);

      // Change Color
      await vm.setPrimaryColor(0xFF7C3AED);
      expect(vm.settings.primaryColorValue, equals(0xFF7C3AED));

      // Change Theme Mode
      await vm.setThemeMode(ThemeMode.dark);
      expect(vm.settings.themeMode, equals(ThemeMode.dark));

      // Change Font
      await vm.setFontFamily('Outfit');
      expect(vm.settings.fontFamily, equals('Outfit'));

      // Change Scale
      await vm.setFontScale(1.25);
      expect(vm.settings.fontScale, equals(1.25));

      // Change Currency
      await vm.setCurrency(
        code: 'GBP',
        symbol: '£',
        symbolBeforeAmount: true,
        decimalDigits: 2,
        useIndianGrouping: false,
      );
      expect(vm.settings.currencyCode, equals('GBP'));
      expect(vm.settings.currencySymbol, equals('£'));
      expect(AppFormatters.currencySymbol, equals('£'));

      // Change Date & Time formats
      await vm.setDateFormat('yyyy-MM-dd');
      expect(vm.settings.dateFormatPattern, equals('yyyy-MM-dd'));
      expect(AppFormatters.dateFormatPattern, equals('yyyy-MM-dd'));

      await vm.setTimeFormat(true);
      expect(vm.settings.is24HourTime, isTrue);
      expect(AppFormatters.is24Hour, isTrue);

      // Reset to defaults
      await vm.resetToDefaults();
      expect(vm.settings.currencyCode, equals('INR'));
      expect(vm.settings.currencySymbol, equals('₹'));
      expect(vm.settings.fontFamily, equals('Inter'));
      expect(vm.settings.fontScale, equals(1.0));
      expect(vm.settings.dateFormatPattern, equals('dd MMM yyyy'));
      expect(vm.settings.is24HourTime, isFalse);

      expect(notifications, greaterThanOrEqualTo(8));
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('Renders all settings sections with live preview removed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and sections
      expect(find.text('Settings'), findsOneWidget);
      // Live preview box must NOT exist
      expect(find.text('LIVE PREVIEW'), findsNothing);

      expect(find.text('Theme & Colors'), findsOneWidget);
      expect(find.text('Typography & Fonts'), findsOneWidget);
      expect(find.text('Font Size & Scale'), findsOneWidget);
      expect(find.text('Currency & Number Format'), findsOneWidget);
      expect(find.text('Date & Time Format'), findsOneWidget);
    });

    testWidgets('Tapping color preset updates primary color', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Find Emerald color option
      final emeraldFinder = find.text('Emerald');
      expect(emeraldFinder, findsOneWidget);

      await tester.tap(emeraldFinder);
      await tester.pumpAndSettle();

      expect(vm.settings.primaryColorValue, equals(0xFF059669));
    });

    testWidgets('Tapping font preset updates font family', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Find Poppins font option
      final poppinsFinder = find.text('Poppins');
      expect(poppinsFinder, findsOneWidget);

      await tester.tap(poppinsFinder);
      await tester.pumpAndSettle();

      expect(vm.settings.fontFamily, equals('Poppins'));
    });

    testWidgets('Tapping scale preset chip updates font scale', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Find Large (130%) chip
      final largeChipFinder = find.text('Large (130%)');
      expect(largeChipFinder, findsOneWidget);

      await tester.tap(largeChipFinder);
      await tester.pumpAndSettle();

      expect(vm.settings.fontScale, equals(1.30));
    });

    testWidgets('Tapping currency preset updates currency and formatter', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Tap USD currency option
      final usdFinder = find.text('\$ USD');
      expect(usdFinder, findsOneWidget);

      await tester.tap(usdFinder);
      await tester.pumpAndSettle();

      expect(vm.settings.currencyCode, equals('USD'));
      expect(vm.settings.currencySymbol, equals('\$'));
      expect(AppFormatters.currencySymbol, equals('\$'));
    });

    testWidgets('Selecting date format and time format updates settings and AppFormatters', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Select 'yyyy-MM-dd' option
      final isoPatternFinder = find.text('yyyy-MM-dd');
      expect(isoPatternFinder, findsOneWidget);
      await tester.tap(isoPatternFinder);
      await tester.pumpAndSettle();

      expect(vm.settings.dateFormatPattern, equals('yyyy-MM-dd'));
      expect(AppFormatters.dateFormatPattern, equals('yyyy-MM-dd'));

      // Select 24-hour time mode
      final time24Finder = find.text('24h');
      expect(time24Finder, findsOneWidget);
      await tester.tap(time24Finder);
      await tester.pumpAndSettle();

      expect(vm.settings.is24HourTime, isTrue);
      expect(AppFormatters.is24Hour, isTrue);
    });

    testWidgets('Reset to defaults confirmation dialog resets settings', (WidgetTester tester) async {
      final vm = SettingsViewModel();
      await vm.init();
      await vm.setFontScale(1.30);
      await vm.setCurrency(
        code: 'USD',
        symbol: '\$',
        symbolBeforeAmount: true,
        decimalDigits: 2,
        useIndianGrouping: false,
      );
      await vm.setDateFormat('yyyy-MM-dd');
      await vm.setTimeFormat(true);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reset icon in AppBar
      final resetBtnFinder = find.byIcon(Icons.restart_alt_rounded);
      expect(resetBtnFinder, findsOneWidget);
      await tester.tap(resetBtnFinder);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Reset Settings?'), findsOneWidget);

      // Tap Reset button in dialog
      final confirmResetBtn = find.widgetWithText(FilledButton, 'Reset');
      await tester.tap(confirmResetBtn);
      await tester.pumpAndSettle();

      expect(vm.settings.currencyCode, equals('INR'));
      expect(vm.settings.fontScale, equals(1.0));
      expect(vm.settings.dateFormatPattern, equals('dd MMM yyyy'));
      expect(vm.settings.is24HourTime, isFalse);
    });

    testWidgets('Displays exactly 4 necessary fonts in font picker', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(AppSettings.fontPresets.length, equals(4));
      expect(AppSettings.fontPresets, containsAll(['Inter', 'Roboto', 'Poppins', 'System']));
      expect(find.text('Inter'), findsWidgets);
      expect(find.text('Roboto'), findsWidgets);
      expect(find.text('Poppins'), findsWidgets);
      expect(find.text('System'), findsWidgets);
    });

    testWidgets('Displays exactly 3 currencies with conversion and INR as default', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(AppSettings.presetCurrencies.length, equals(3));
      final codes = AppSettings.presetCurrencies.map((c) => c.code).toList();
      expect(codes, equals(['INR', 'USD', 'EUR']));

      // INR is default
      expect(vm.settings.currencyCode, equals('INR'));
      expect(vm.settings.currencySymbol, equals('₹'));
      expect(find.text('₹ INR'), findsWidgets);
      expect(find.text('\$ USD'), findsWidgets);
      expect(find.text('€ EUR'), findsWidgets);

      // Verify Currency Converter is rendered
      expect(find.text('Currency Converter (INR Base)'), findsOneWidget);
    });

    testWidgets('Displays exactly 4 date formats and 4 time formats', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vm = SettingsViewModel();
      await vm.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(settingsViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(AppSettings.dateFormatPresets.length, equals(4));
      expect(AppSettings.timeFormatPresets.length, equals(4));

      final datePatterns = AppSettings.dateFormatPresets.map((d) => d.pattern).toList();
      expect(datePatterns, equals(['dd MMM yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd']));

      final timePatterns = AppSettings.timeFormatPresets.map((t) => t.pattern).toList();
      expect(timePatterns, equals(['hh:mm a', 'HH:mm', 'hh:mm:ss a', 'HH:mm:ss']));

      // Select 12h with seconds
      final sec12Finder = find.text('12h + Sec');
      expect(sec12Finder, findsOneWidget);
      await tester.tap(sec12Finder);
      await tester.pumpAndSettle();

      expect(vm.settings.timeFormatPattern, equals('hh:mm:ss a'));
      expect(AppFormatters.timeFormatPattern, equals('hh:mm:ss a'));
    });
  });

  group('Currency Conversion Helper Tests', () {
    test('Converts between INR, USD, and EUR accurately', () {
      // 1000 INR to USD at default rate (86.50)
      final usd = CurrencyConversionHelper.convert(1000, fromCode: 'INR', toCode: 'USD');
      expect(usd, closeTo(11.56, 0.01));

      // 100 USD to INR
      final inrFromUsd = CurrencyConversionHelper.convert(100, fromCode: 'USD', toCode: 'INR');
      expect(inrFromUsd, equals(8650.0));

      // 100 EUR to INR at default rate (94.00)
      final inrFromEur = CurrencyConversionHelper.convert(100, fromCode: 'EUR', toCode: 'INR');
      expect(inrFromEur, equals(9400.0));

      // 100 EUR to USD
      final usdFromEur = CurrencyConversionHelper.convert(100, fromCode: 'EUR', toCode: 'USD');
      expect(usdFromEur, closeTo(108.67, 0.01));
    });

    test('Conversion factor calculation matches', () {
      final factorInrToUsd = CurrencyConversionHelper.getFactor(fromCode: 'INR', toCode: 'USD');
      expect(factorInrToUsd, closeTo(1 / 86.50, 0.0001));

      final factorUsdToInr = CurrencyConversionHelper.getFactor(fromCode: 'USD', toCode: 'INR');
      expect(factorUsdToInr, equals(86.50));

      final factorSame = CurrencyConversionHelper.getFactor(fromCode: 'INR', toCode: 'INR');
      expect(factorSame, equals(1.0));
    });
  });

  group('User Account Profile Tests', () {
    test('AppSettings handles account setup properties and serialization', () {
      const defaultSettings = AppSettings();
      expect(defaultSettings.userName, equals('You'));
      expect(defaultSettings.userPhone, isNull);
      expect(defaultSettings.userUpiId, isNull);
      expect(defaultSettings.hasCompletedAccountSetup, isFalse);

      final updated = defaultSettings.copyWith(
        userName: 'Sasic',
        userPhone: '+91 9876543210',
        userUpiId: 'sasic@upi',
        hasCompletedAccountSetup: true,
      );

      expect(updated.userName, equals('Sasic'));
      expect(updated.userPhone, equals('+91 9876543210'));
      expect(updated.userUpiId, equals('sasic@upi'));
      expect(updated.hasCompletedAccountSetup, isTrue);

      final map = updated.toMap();
      final restored = AppSettings.fromMap(map);
      expect(restored.userName, equals('Sasic'));
      expect(restored.userPhone, equals('+91 9876543210'));
      expect(restored.userUpiId, equals('sasic@upi'));
      expect(restored.hasCompletedAccountSetup, isTrue);
    });

    test('SettingsViewModel.updateAccountProfile persists and notifies', () async {
      final vm = SettingsViewModel();
      await vm.init();

      await vm.updateAccountProfile(
        name: 'Arun Kumar',
        phone: '9840012345',
        upiId: 'arun@okaxis',
        completed: true,
      );

      expect(vm.settings.userName, equals('Arun Kumar'));
      expect(vm.settings.userPhone, equals('9840012345'));
      expect(vm.settings.userUpiId, equals('arun@okaxis'));
      expect(vm.settings.hasCompletedAccountSetup, isTrue);

      // Verify persistence across reload
      final reloadedVm = SettingsViewModel();
      await reloadedVm.init();
      expect(reloadedVm.settings.userName, equals('Arun Kumar'));
      expect(reloadedVm.settings.userPhone, equals('9840012345'));
      expect(reloadedVm.settings.userUpiId, equals('arun@okaxis'));
      expect(reloadedVm.settings.hasCompletedAccountSetup, isTrue);
    });

    testWidgets('UserAccountSetupDialog updates CashBookViewModel currentUser and SettingsViewModel', (tester) async {
      final repository = FakeCashBookRepository();
      final cashBookVm = CashBookViewModel(repository: repository);
      final settingsVm = SettingsViewModel();

      await cashBookVm.init();
      await settingsVm.init();

      expect(cashBookVm.currentUser.name, equals('You'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  UserAccountSetupDialog.show(
                    ctx,
                    cashBookViewModel: cashBookVm,
                    settingsViewModel: settingsVm,
                  );
                },
                child: const Text('Open Setup'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Setup'));
      await tester.pumpAndSettle();

      expect(find.text('User Account Setup'), findsOneWidget);

      // Find the name text field
      final nameField = find.widgetWithText(TextFormField, 'Your Full Name *');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Vikram');

      // Find phone field
      final phoneField = find.widgetWithText(TextFormField, 'Mobile Number (Optional)');
      await tester.enterText(phoneField, '9988776655');

      // Find UPI field
      final upiField = find.widgetWithText(TextFormField, 'UPI ID / Payment Handle (Optional)');
      await tester.enterText(upiField, 'vikram@okhdfc');

      await tester.pump();

      // Tap Save Changes
      final saveBtn = find.text('Save Changes');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify currentUser updated
      expect(cashBookVm.currentUser.name, equals('Vikram'));
      expect(cashBookVm.currentUser.phoneNumber, equals('9988776655'));
      expect(cashBookVm.currentUser.upiId, equals('vikram@okhdfc'));

      // Verify SettingsViewModel updated
      expect(settingsVm.settings.userName, equals('Vikram'));
      expect(settingsVm.settings.userPhone, equals('9988776655'));
      expect(settingsVm.settings.userUpiId, equals('vikram@okhdfc'));
      expect(settingsVm.settings.hasCompletedAccountSetup, isTrue);
    });
  });
}

