import 'package:intl/intl.dart';

class DateTimeHelper {
  /// Converts a UTC ISO string to a local DateTime object.
  static DateTime toLocalFromUtc(String utcIsoString) {
    if (utcIsoString.isEmpty) return DateTime.now();
    try {
      // Parse as UTC if it ends in Z, otherwise assume it might be UTC-ish
      // or just let DateTime.parse handle it, then force to local.
      final dateTime = DateTime.parse(utcIsoString);
      if (dateTime.isUtc) {
        return dateTime.toLocal();
      } else {
        // If it was parsed as local but we know backend sends UTC, we might need
        // validation. But standard ISO-8601 with 'Z' is parsed as UTC.
        // If no 'Z', logic depends on API contract. Assuming API sends 'Z'.
        return dateTime.toLocal();
      }
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Formats a DateTime (or ISO string) for UI display in Local time.
  /// Format: "dd MMM yyyy, hh:mm a" (e.g., 22 Jan 2026, 01:04 AM)
  static String formatForUI(dynamic dateOrString) {
    if (dateOrString == null) return '';

    DateTime localTime;
    if (dateOrString is String) {
      localTime = toLocalFromUtc(dateOrString);
    } else if (dateOrString is DateTime) {
      // If it's already a DateTime object, ensure it's converted to local
      localTime = dateOrString.toLocal();
    } else {
      return '';
    }

    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(localTime);
    } catch (e) {
      return '';
    }
  }
}
