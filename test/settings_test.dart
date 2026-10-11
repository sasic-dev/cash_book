import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cash_book/data/models/app_settings.dart';
import 'package:cash_book/ui/utils/formatters.dart';
import 'package:cash_book/ui/view_models/settings_view_model.dart';
import 'package:cash_book/ui/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
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
  });
}
