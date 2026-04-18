/// Date formatting utilities shared across screens.
class AppDateUtils {
  static const _months = [
    '',
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _shortMonths = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String monthName(int month) => _months[month];
  static String monthShort(int month) => _shortMonths[month];

  /// yyyy-MM-dd
  static String formatYMD(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// "Jan 5, 2025"
  static String formatMDY(DateTime d) => '${monthShort(d.month)} ${d.day}, ${d.year}';

  /// "5 Jan"
  static String formatDM(DateTime d) => '${d.day} ${monthShort(d.month)}';
}
