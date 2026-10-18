import 'package:intl/intl.dart';

class AppUtils {
  static String formatCurrency(double amount, {String symbol = 'KSh'}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol ${formatter.format(amount)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  static String generateTransactionId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'TXN-${timestamp.toString().substring(7)}';
  }

  static String generateReceiptNumber() {
    final now = DateTime.now();
    return 'RCP-${DateFormat('yyyyMMdd').format(now)}-${(1000 + DateTime.now().millisecond).toString()}';
  }

  static double calculateTax(double amount, double taxRate) {
    return amount * (taxRate / 100);
  }

  static double calculateDiscount(double amount, double discountPercent) {
    return amount * (discountPercent / 100);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return formatDate(dateTime);
  }

  static bool isLowStock(int quantity, {int threshold = 10}) {
    return quantity <= threshold;
  }

  static String getStockStatus(int quantity) {
    if (quantity == 0) return 'Out of Stock';
    if (quantity <= 5) return 'Critical';
    if (quantity <= 10) return 'Low Stock';
    return 'In Stock';
  }
}
