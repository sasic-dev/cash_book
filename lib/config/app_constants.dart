import 'package:flutter/material.dart';

/// Preset color options for app theming
class AppColorPreset {
  final String id;
  final String name;
  final Color primaryColor;
  final String description;

  const AppColorPreset({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.description,
  });
}

/// Preset currency definitions
class CurrencyOption {
  final String code;
  final String name;
  final String symbol;
  final bool defaultIndianGrouping;
  final int defaultDecimals;
  final double rateToInr;

  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
    this.defaultIndianGrouping = false,
    this.defaultDecimals = 2,
    this.rateToInr = 1.0,
  });
}

/// Preset date format definitions
class DateFormatPreset {
  final String pattern;
  final String label;

  const DateFormatPreset({
    required this.pattern,
    required this.label,
  });
}

/// Preset time format definitions
class TimeFormatPreset {
  final String pattern;
  final String label;
  final String description;

  const TimeFormatPreset({
    required this.pattern,
    required this.label,
    required this.description,
  });
}

/// Single central configuration and constants file for Cash Book.
/// All strings, numeric limits, database schemas, palettes, default settings,
/// semantic colors, and asset paths are maintained here.
class AppConstants {
  AppConstants._();

  // ==========================================
  // App Identity & Branding
  // ==========================================
  static const String appName = 'Cash Book';
  static const String appSubtitle = 'SMART LEDGER';
  static const String appTrustBadge = '100% Private • Local Storage';
  static const String appIconAsset = 'assets/icons/app_icon.png';
  static const double defaultLogoSize = 28.0;

  // ==========================================
  // Database Configuration
  // ==========================================
  static const String dbName = 'cash_book.db';
  static const int dbVersion = 3;

  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
  static const String tablePersons = 'persons';
  static const String tableGroups = 'split_groups';
  static const String tableGroupMembers = 'split_group_members';
  static const String tableSplitExpenses = 'split_expenses';
  static const String tableExpenseSplits = 'expense_splits';
  static const String tableSettlements = 'settlements';

  // ==========================================
  // Storage & SharedPreferences Keys
  // ==========================================
  static const String keySettings = 'app_settings_v1';
  static const String keyCategoriesLegacy = 'cash_book_categories_v1';
  static const String keyTransactionsLegacy = 'cash_book_transactions_v1';
  static const String keyAccountSetupCompleted = 'account_setup_completed_v1';
  static const String keyUserName = 'user_account_name';
  static const String keyUserPhone = 'user_account_phone';
  static const String keyUserUpiId = 'user_account_upi_id';
  static const bool defaultAccountSetupCompleted = false;

  // ==========================================
  // Default Settings & Formatting
  // ==========================================
  static const int defaultPrimaryColorValue = 0xFF1E40AF; // Sapphire Indigo
  static const String defaultFontFamily = 'Inter';
  static const double defaultFontScale = 1.0;
  static const double minFontScale = 0.80;
  static const double maxFontScale = 1.50;

  static const String defaultCurrencyCode = 'INR';
  static const String defaultCurrencySymbol = '₹';
  static const bool defaultSymbolBeforeAmount = true;
  static const int defaultDecimalDigits = 2;
  static const bool defaultIndianGrouping = true;

  static const String defaultDateFormat = 'dd MMM yyyy';
  static const String defaultTimeFormat = 'hh:mm a';
  static const String default24HourTimeFormat = 'HH:mm';
  static const bool defaultIs24HourTime = false;

  static const Duration defaultSplashDuration = Duration(milliseconds: 1000);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Exchange rates relative to INR
  static const double defaultUsdRate = 86.50;
  static const double defaultEurRate = 94.00;
  static const Map<String, double> defaultRatesToInr = {
    'INR': 1.0,
    'USD': defaultUsdRate,
    'EUR': defaultEurRate,
  };

  // Calculator defaults
  static const String defaultCalculatorAmount = '1000';

  // ==========================================
  // Split & Transactions Defaults
  // ==========================================
  static const String defaultPaymentMode = 'Cash';
  static const String defaultPaymentMethod = 'UPI';
  static const String defaultSplitType = 'equal';
  static const String defaultCurrentUserId = 'person_you';
  static const String defaultCurrentUserName = 'You';
  static const int defaultCurrentUserColor = 0xFF1E88E5;
  static final DateTime defaultCurrentUserCreatedAt = DateTime(2025, 1, 1);

  static const String fallbackIncomeCategoryId = 'inc_other';
  static const String fallbackExpenseCategoryId = 'exp_other';
  static const int defaultIncomeCategoryColor = 0xFF2E7D32;
  static const int defaultExpenseCategoryColor = 0xFFE65100;

  static const List<String> paymentModes = [
    'Cash',
    'Online / UPI',
    'Card',
    'Bank Transfer',
    'Cheque',
  ];

  static const List<String> settlementPaymentMethods = [
    'UPI',
    'Cash',
    'Bank Transfer',
    'Other',
  ];

  // ==========================================
  // Date Picker Bounds
  // ==========================================
  static const int datePickerStartYear = 2020;
  static const int datePickerEndYear = 2035;

  // ==========================================
  // Reporting & Export Configuration
  // ==========================================
  static const String pdfChannel = 'com.example.cash_book/pdf_export';
  static const String csvFilePrefix = 'cash_book_';
  static const String reportStatementTitle = 'CASH BOOK STATEMENT';
  static const String reportStatementFooter = 'Cash Book - Financial Records';

  // ==========================================
  // Theme & Design Colors
  // ==========================================
  // Light Palette
  static const Color lightScaffoldBg = Color(0xFFF8FAFC);
  static const Color lightCardBg = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightInputBorder = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightShadow = Color(0x1A0F172A);
  static const Color lightCardShadow = Color(0x140F172A);

  // Dark Palette
  static const Color darkScaffoldBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkInputBorder = Color(0xFF475569);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkShadow = Color(0x33000000);
  static const Color darkCardShadow = Color(0x40000000);

  // Semantic Financial Colors (Income / Cash In)
  static const Color incomeGreen = Color(0xFF16A34A);
  static const Color incomeGreenDark = Color(0xFF15803D);
  static const Color incomeLightBg = Color(0xFFF0FDF4);
  static const Color incomeLightBorder = Color(0xFFBBF7D0);
  static const Color incomeDarkBg = Color(0xFF14532D);
  static const Color incomeDarkText = Color(0xFF4ADE80);

  // Semantic Financial Colors (Expense / Cash Out)
  static const Color expenseRed = Color(0xFFDC2626);
  static const Color expenseRedDark = Color(0xFFB91C1C);
  static const Color expenseLightBg = Color(0xFFFEF2F2);
  static const Color expenseLightBorder = Color(0xFFFECACA);
  static const Color expenseDarkBg = Color(0xFF7F1D1D);
  static const Color expenseDarkText = Color(0xFFF87171);

  // Additional Semantic Accents
  static const Color warningAmber = Color(0xFFD97706);
  static const Color infoBlue = Color(0xFF2563EB);

  // ==========================================
  // Color Palettes
  // ==========================================
  static const List<int> groupColorPalette = [
    0xFF00897B, // Teal
    0xFF1E88E5, // Blue
    0xFF8E24AA, // Purple
    0xFFFF8F00, // Amber
    0xFFE53935, // Red
    0xFF43A047, // Green
    0xFF3949AB, // Indigo
    0xFF00ACC1, // Cyan
    0xFFD81B60, // Pink
    0xFFF4511E, // Deep Orange
    0xFF5E35B1, // Deep Purple
    0xFF546E7A, // Blue Grey
  ];

  static const List<int> personColorPalette = [
    0xFF1E88E5, // Blue
    0xFF43A047, // Green
    0xFF8E24AA, // Purple
    0xFFFF8F00, // Amber
    0xFFE53935, // Red
    0xFF00897B, // Teal
    0xFF3949AB, // Indigo
    0xFFD81B60, // Pink
  ];

  static const List<int> categoryColorPalette = [
    0xFF2E7D32, // Dark Green
    0xFF43A047, // Green
    0xFF00897B, // Teal
    0xFF00ACC1, // Cyan
    0xFF1976D2, // Blue
    0xFF3949AB, // Indigo
    0xFF5E35B1, // Deep Purple
    0xFF8E24AA, // Purple
    0xFFD81B60, // Pink
    0xFFE53935, // Red
    0xFFF4511E, // Deep Orange
    0xFFFB8C00, // Orange
    0xFFFFB300, // Amber
    0xFF6D4C41, // Brown
    0xFF546E7A, // Blue Grey
    0xFF424242, // Grey
  ];

  // ==========================================
  // Presets & Options
  // ==========================================
  static const List<AppColorPreset> colorPresets = [
    AppColorPreset(
      id: 'sapphire',
      name: 'Sapphire Indigo',
      primaryColor: Color(0xFF1E40AF),
      description: 'Modern corporate indigo blue',
    ),
    AppColorPreset(
      id: 'emerald',
      name: 'Emerald Green',
      primaryColor: Color(0xFF059669),
      description: 'Vibrant wealth & growth green',
    ),
    AppColorPreset(
      id: 'royal_violet',
      name: 'Royal Violet',
      primaryColor: Color(0xFF7C3AED),
      description: 'Fintech purple & royalty',
    ),
    AppColorPreset(
      id: 'crimson_rose',
      name: 'Crimson Rose',
      primaryColor: Color(0xFFE11D48),
      description: 'Bold expressive crimson rose',
    ),
    AppColorPreset(
      id: 'amber_sunset',
      name: 'Sunset Amber',
      primaryColor: Color(0xFFD97706),
      description: 'Warm gold & autumn amber',
    ),
    AppColorPreset(
      id: 'teal_ocean',
      name: 'Ocean Teal',
      primaryColor: Color(0xFF0D9488),
      description: 'Calm refreshing oceanic teal',
    ),
    AppColorPreset(
      id: 'slate_tech',
      name: 'Slate Tech',
      primaryColor: Color(0xFF334155),
      description: 'Minimal slate & obsidian',
    ),
    AppColorPreset(
      id: 'cyan_sky',
      name: 'Electric Cyan',
      primaryColor: Color(0xFF0284C7),
      description: 'Vivid futuristic sky cyan',
    ),
  ];

  static const List<String> fontPresets = [
    'Inter',
    'Roboto',
    'Poppins',
    'System',
  ];

  static const List<CurrencyOption> presetCurrencies = [
    CurrencyOption(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      defaultIndianGrouping: true,
      defaultDecimals: 2,
      rateToInr: 1.0,
    ),
    CurrencyOption(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
      rateToInr: defaultUsdRate,
    ),
    CurrencyOption(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
      rateToInr: defaultEurRate,
    ),
  ];

  static const List<DateFormatPreset> dateFormatPresets = [
    DateFormatPreset(pattern: 'dd MMM yyyy', label: '11 Oct 2026 (Default)'),
    DateFormatPreset(pattern: 'dd/MM/yyyy', label: '11/10/2026 (DD/MM/YYYY)'),
    DateFormatPreset(pattern: 'MM/dd/yyyy', label: '10/11/2026 (MM/DD/YYYY)'),
    DateFormatPreset(pattern: 'yyyy-MM-dd', label: '2026-10-11 (YYYY-MM-DD)'),
  ];

  static const List<TimeFormatPreset> timeFormatPresets = [
    TimeFormatPreset(
      pattern: 'hh:mm a',
      label: '12h',
      description: '12-Hour (AM/PM)',
    ),
    TimeFormatPreset(
      pattern: 'HH:mm',
      label: '24h',
      description: '24-Hour (Military)',
    ),
    TimeFormatPreset(
      pattern: 'hh:mm:ss a',
      label: '12h + Sec',
      description: '12-Hour with Seconds',
    ),
    TimeFormatPreset(
      pattern: 'HH:mm:ss',
      label: '24h + Sec',
      description: '24-Hour with Seconds',
    ),
  ];

  // ==========================================
  // Icon Catalogs
  // ==========================================
  static const List<IconData> categoryIcons = [
    // Finance & Work
    Icons.account_balance_wallet_rounded,
    Icons.account_balance_rounded,
    Icons.attach_money_rounded,
    Icons.currency_exchange_rounded,
    Icons.savings_rounded,
    Icons.credit_card_rounded,
    Icons.receipt_long_rounded,
    Icons.work_rounded,
    Icons.laptop_mac_rounded,
    Icons.storefront_rounded,
    Icons.trending_up_rounded,

    // Living & Home
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.build_rounded,
    Icons.electric_bolt_rounded,
    Icons.water_drop_rounded,
    Icons.wifi_rounded,
    Icons.phone_android_rounded,

    // Food & Dining
    Icons.restaurant_rounded,
    Icons.fastfood_rounded,
    Icons.local_cafe_rounded,
    Icons.local_bar_rounded,
    Icons.shopping_cart_rounded,
    Icons.local_grocery_store_rounded,

    // Transport & Travel
    Icons.directions_car_rounded,
    Icons.two_wheeler_rounded,
    Icons.directions_bus_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.beach_access_rounded,

    // Health & Family
    Icons.local_hospital_rounded,
    Icons.medication_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.child_care_rounded,
    Icons.school_rounded,

    // Shopping & Fun
    Icons.shopping_bag_rounded,
    Icons.local_mall_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.card_giftcard_rounded,
    Icons.celebration_rounded,
    Icons.more_horiz_rounded,
  ];

  static const List<IconData> groupIcons = [
    // Social & Friends
    Icons.groups_rounded,
    Icons.diversity_3_rounded,
    Icons.diversity_1_rounded,
    Icons.family_restroom_rounded,
    Icons.work_rounded,
    Icons.school_rounded,

    // Travel & Trips
    Icons.flight_takeoff_rounded,
    Icons.directions_car_rounded,
    Icons.hiking_rounded,
    Icons.beach_access_rounded,
    Icons.two_wheeler_rounded,
    Icons.train_rounded,
    Icons.hotel_rounded,
    Icons.luggage_rounded,

    // Living & Flatmates
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.king_bed_rounded,
    Icons.chair_rounded,
    Icons.wifi_rounded,
    Icons.electric_bolt_rounded,

    // Food, Drinks & Dining
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.local_bar_rounded,
    Icons.local_pizza_rounded,
    Icons.fastfood_rounded,

    // Fun, Entertainment & Sports
    Icons.celebration_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.sports_soccer_rounded,
    Icons.fitness_center_rounded,
    Icons.card_giftcard_rounded,

    // Shopping & Money
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.receipt_long_rounded,
    Icons.savings_rounded,
    Icons.account_balance_wallet_rounded,
  ];
}

/// Convenience alias so AppConfig and AppConstants can be used interchangeably
typedef AppConfig = AppConstants;
