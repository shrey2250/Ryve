import 'package:intl/intl.dart';

/// RYVE Currency Formatter
///
/// All amounts are stored internally as integer paise (1 INR = 100 paise).
/// This utility handles all formatting concerns at the UI layer only.
///
/// Indian number system: 1,00,000 (lakh) — NOT 100,000
/// Example: ₹1,24,56,789 for 12,456,789 INR
abstract final class CurrencyFormatter {
  static const String _symbol = '₹';

  // Indian locale formatter (en_IN uses lakh/crore grouping)
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: _symbol,
    decimalDigits: 0,
  );

  static final NumberFormat _inrFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: _symbol,
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'en_IN',
  );

  /// Format paise as INR string with Indian number grouping.
  /// Automatically shows decimals if non-zero paise exists (e.g. ₹1,24,567.50),
  /// and hides paise when .00 unless showDecimal is true.
  static String format(
    int paise, {
    bool showSign = false,
    bool showDecimal = false,
  }) {
    final rupees = paise / 100.0;
    final absRupees = rupees.abs();
    final isNegative = paise < 0;

    String formatted;
    if (showDecimal || (paise.abs() % 100 != 0)) {
      formatted = _inrFormatDecimal.format(absRupees);
    } else {
      formatted = _inrFormat.format(absRupees.round());
    }

    if (showSign) {
      return isNegative ? '-$formatted' : '+$formatted';
    } else if (isNegative) {
      return '-$formatted';
    }

    return formatted;
  }

  /// Format paise with privacy mask support (e.g. for privacy mode)
  static String formatWithPrivacy(
    int paise, {
    bool isPrivate = false,
    bool showSign = false,
    bool showDecimal = false,
  }) {
    if (isPrivate) return '••••••';
    return format(paise, showSign: showSign, showDecimal: showDecimal);
  }

  /// Format paise as a compact string for tight spaces.
  /// e.g. 1,00,000 paise → ₹1K | 1,00,00,000 paise → ₹1L
  static String formatCompact(int paise) {
    final rupees = paise / 100.0;
    return '$_symbol${_compactFormat.format(rupees.abs())}';
  }

  /// Parse a user-entered string to paise.
  /// Strips ₹, commas, and handles decimals.
  /// Returns null if not parseable.
  static int? parseToPaise(String input) {
    final cleaned = input
        .replaceAll(_symbol, '')
        .replaceAll(',', '')
        .trim();

    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null) return null;

    // Round to nearest paise to avoid float imprecision
    return (value * 100).round();
  }

  /// Convert rupee double to paise integer safely.
  static int rupeesToPaise(double rupees) => (rupees * 100).round();

  /// Convert paise integer to rupee double.
  static double paiseToRupees(int paise) => paise / 100.0;

  /// Format paise as plain rupee string for input display (no symbol, no grouping).
  /// e.g. 85000 paise → "850" or "850.50"
  static String formatForInput(int paise) {
    if (paise % 100 == 0) {
      return (paise ~/ 100).toString();
    }
    return (paise / 100.0).toStringAsFixed(2);
  }
}
