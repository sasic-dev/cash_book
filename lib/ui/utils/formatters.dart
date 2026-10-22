import 'package:intl/intl.dart';
import '../../config/app_constants.dart';
import '../../data/models/app_settings.dart';

class AppFormatters {
  static String _currencyCode = AppConstants.defaultCurrencyCode;
  static String _currencySymbol = AppConstants.defaultCurrencySymbol;
  static int _decimalDigits = AppConstants.defaultDecimalDigits;
  static bool _symbolBeforeAmount = AppConstants.defaultSymbolBeforeAmount;
  static bool _useIndianGrouping = AppConstants.defaultIndianGrouping;
  static Map<String, double> _ratesToInr = AppConstants.defaultRatesToInr;

  static String _dateFormatPattern = AppConstants.defaultDateFormat;
  static String _timeFormatPattern = AppConstants.defaultTimeFormat;
  static bool _is24Hour = AppConstants.defaultIs24HourTime;

  static NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: AppConstants.defaultDecimalDigits,
    locale: 'en_IN',
  );

  static NumberFormat _numberFormat = NumberFormat('#,##,##0.00', 'en_IN');

  static DateFormat _dateFormat = DateFormat(AppConstants.defaultDateFormat);
  static DateFormat _timeFormat = DateFormat(AppConstants.defaultTimeFormat);
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  /// Configures currency formatting dynamically across the app
  static void updateCurrency({
    required String symbol,
    required int decimalDigits,
    required bool symbolBeforeAmount,
    required bool useIndianGrouping,
    String currencyCode = AppConstants.defaultCurrencyCode,
    Map<String, double>? ratesToInr,
  }) {
    _currencyCode = currencyCode;
    _currencySymbol = symbol;
    _decimalDigits = decimalDigits;
    _symbolBeforeAmount = symbolBeforeAmount;
    _useIndianGrouping = useIndianGrouping;
    if (ratesToInr != null && ratesToInr.isNotEmpty) {
      _ratesToInr = Map<String, double>.from(ratesToInr);
    }

    final locale = useIndianGrouping ? 'en_IN' : 'en_US';
    final decimalPattern = decimalDigits > 0 ? '.${'0' * decimalDigits}' : '';
    final pattern = useIndianGrouping
        ? '#,##,##0$decimalPattern'
        : '#,##0$decimalPattern';

    _numberFormat = NumberFormat(pattern, locale);
    _currencyFormat = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      locale: locale,
    );
  }

  /// Converts an amount stored in canonical base INR to the current display currency.
  static double toDisplayAmount(double baseInrAmount) {
    if (_currencyCode == 'INR') return baseInrAmount;
    final rate = _ratesToInr[_currencyCode] ??
        CurrencyConversionHelper.defaultRatesToInr[_currencyCode] ??
        1.0;
    if (rate <= 0) return baseInrAmount;
    return baseInrAmount / rate;
  }

  /// Converts an amount entered in the current display currency back to canonical base INR.
  static double fromDisplayAmount(double displayAmount) {
    if (_currencyCode == 'INR') return displayAmount;
    final rate = _ratesToInr[_currencyCode] ??
        CurrencyConversionHelper.defaultRatesToInr[_currencyCode] ??
        1.0;
    if (rate <= 0) return displayAmount;
    return displayAmount * rate;
  }

  /// Returns current exchange rates map
  static Map<String, double> get ratesToInr => Map.unmodifiable(_ratesToInr);

  /// Configures date and time formatting dynamically across the app
  static void updateDateTimeFormat({
    required String dateFormatPattern,
    required bool is24Hour,
    String? timeFormatPattern,
  }) {
    _dateFormatPattern = dateFormatPattern;
    _is24Hour = is24Hour;
    _timeFormatPattern = timeFormatPattern ?? (is24Hour ? 'HH:mm' : 'hh:mm a');
    _dateFormat = DateFormat(dateFormatPattern);
    _timeFormat = DateFormat(_timeFormatPattern);
  }

  static String get currencyCode => _currencyCode;
  static String get currencySymbol => _currencySymbol;
  static int get decimalDigits => _decimalDigits;
  static bool get symbolBeforeAmount => _symbolBeforeAmount;
  static bool get useIndianGrouping => _useIndianGrouping;

  static String get dateFormatPattern => _dateFormatPattern;
  static String get timeFormatPattern => _timeFormatPattern;
  static bool get is24Hour => _is24Hour;

  static String currency(double amount, {bool convertFromBase = true}) {
    final displayValue = convertFromBase ? toDisplayAmount(amount) : amount;
    if (_symbolBeforeAmount) {
      return _currencyFormat.format(displayValue);
    } else {
      final sign = displayValue < 0 ? '-' : '';
      return '$sign${_numberFormat.format(displayValue.abs())} $_currencySymbol';
    }
  }

  static String number(double amount, {bool convertFromBase = true}) {
    final displayValue = convertFromBase ? toDisplayAmount(amount) : amount;
    return _numberFormat.format(displayValue);
  }

  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String time(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static String monthYear(DateTime dateTime) {
    return _monthYearFormat.format(dateTime);
  }

  static String relativeDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return 'Today, ${_dateFormat.format(date)}';
    } else if (compareDate == yesterday) {
      return 'Yesterday, ${_dateFormat.format(date)}';
    } else {
      return _dateFormat.format(date);
    }
  }

  static bool isCurrentMonth(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year && dateTime.month == now.month;
  }
}
