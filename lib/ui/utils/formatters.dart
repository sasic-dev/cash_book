import 'package:intl/intl.dart';

class AppFormatters {
  static String _currencySymbol = '₹';
  static int _decimalDigits = 2;
  static bool _symbolBeforeAmount = true;
  static bool _useIndianGrouping = true;

  static String _dateFormatPattern = 'dd MMM yyyy';
  static bool _is24Hour = false;

  static NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static NumberFormat _numberFormat = NumberFormat('#,##,##0.00', 'en_IN');

  static DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  /// Configures currency formatting dynamically across the app
  static void updateCurrency({
    required String symbol,
    required int decimalDigits,
    required bool symbolBeforeAmount,
    required bool useIndianGrouping,
  }) {
    _currencySymbol = symbol;
    _decimalDigits = decimalDigits;
    _symbolBeforeAmount = symbolBeforeAmount;
    _useIndianGrouping = useIndianGrouping;

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

  /// Configures date and time formatting dynamically across the app
  static void updateDateTimeFormat({
    required String dateFormatPattern,
    required bool is24Hour,
  }) {
    _dateFormatPattern = dateFormatPattern;
    _is24Hour = is24Hour;
    _dateFormat = DateFormat(dateFormatPattern);
    _timeFormat = DateFormat(is24Hour ? 'HH:mm' : 'hh:mm a');
  }

  static String get currencySymbol => _currencySymbol;
  static int get decimalDigits => _decimalDigits;
  static bool get symbolBeforeAmount => _symbolBeforeAmount;
  static bool get useIndianGrouping => _useIndianGrouping;

  static String get dateFormatPattern => _dateFormatPattern;
  static bool get is24Hour => _is24Hour;

  static String currency(double amount) {
    if (_symbolBeforeAmount) {
      return _currencyFormat.format(amount);
    } else {
      final sign = amount < 0 ? '-' : '';
      return '$sign${_numberFormat.format(amount.abs())} $_currencySymbol';
    }
  }

  static String number(double amount) {
    return _numberFormat.format(amount);
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
}
