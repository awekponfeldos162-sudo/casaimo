import 'package:intl/intl.dart';

class AppUtils {
  static String formatPrice(double amount, {String currency = 'FCFA'}) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $currency';
  }

  static String formatPricePerNight(double amount, {String currency = 'FCFA'}) {
    return '${formatPrice(amount, currency: currency)}/nuit';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM', 'fr_FR').format(date);
  }

  static String formatDateRange(DateTime checkIn, DateTime checkOut) {
    return '${formatDateShort(checkIn)} - ${formatDateShort(checkOut)}';
  }

  static int nightsBetween(DateTime checkIn, DateTime checkOut) {
    return checkOut.difference(checkIn).inDays;
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return formatDate(date);
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone);
  }
}
