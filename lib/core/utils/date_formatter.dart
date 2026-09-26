import 'package:intl/intl.dart';

/// RYVE Date Formatter — consistent date display across the app
abstract final class DateFormatter {
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _fullDate = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonth = DateFormat('MMM yyyy');
  static final DateFormat _dateOnly = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthKey = DateFormat('yyyy-MM');

  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// "Today", "Yesterday", or "14 Sep" / "14 Sep 2024"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';

    // Show year only if different from current year
    if (date.year == now.year) return _dayMonth.format(date);
    return _dayMonthYear.format(date);
  }

  /// "Today", "Yesterday", or full date — used as section headers in transaction list
  static String formatSectionHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';

    if (date.year == now.year) return _dayMonth.format(date);
    return _dayMonthYear.format(date);
  }

  /// "14 Sep 2026"
  static String formatDate(DateTime date) => _dayMonthYear.format(date);

  /// "2026-09"
  static String formatMonthKey(DateTime date) => _monthKey.format(date);

  /// "Monday, 14 September 2024"
  static String formatFull(DateTime date) => _fullDate.format(date);

  /// "Monday, 14 September 2024"
  static String formatFullDate(DateTime date) => _fullDate.format(date);

  /// "02:30 PM"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// "September 2024"
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// "Sep 2024" — compact version for tight spaces
  static String formatShortMonth(DateTime date) => _shortMonth.format(date);

  /// "14 Sep" or "Sep 11" — short date for transaction rows and test
  static String formatShort(DateTime date) => DateFormat('MMM d').format(date);

  /// Store to ISO 8601 UTC string
  static String toIso(DateTime date) =>
      date.toUtc().toIso8601String();

  /// Parse ISO 8601 UTC string, return local DateTime
  static DateTime fromIso(String iso) =>
      DateTime.parse(iso).toLocal();

  /// "yyyy-MM-dd" — for date-only storage (budgets, goals)
  static String toDateOnly(DateTime date) => _dateOnly.format(date);

  /// Parse "yyyy-MM-dd" string
  static DateTime fromDateOnly(String date) => DateTime.parse(date);

  /// Check if two DateTimes represent the same calendar day
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Get start of month
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Get end of month (last millisecond)
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 1)
          .subtract(const Duration(milliseconds: 1));
}
