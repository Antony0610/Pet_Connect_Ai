import 'package:intl/intl.dart';

/// Extensions on [DateTime] for formatting and relative time.
extension DateTimeExtensions on DateTime {
  /// Formats as `MMM d, y` (e.g., "Jan 5, 2025").
  String get formattedDate => DateFormat.yMMMd().format(this);

  /// Formats as `h:mm a` (e.g., "3:45 PM").
  String get formattedTime => DateFormat.jm().format(this);

  /// Formats as `MMM d, y h:mm a` (e.g., "Jan 5, 2025 3:45 PM").
  String get formattedDateTime => DateFormat.yMMMd().add_jm().format(this);

  /// Relative time string ("just now", "5 min ago", "2 hours ago", etc.).
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    final years = (diff.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }

  /// Whether this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Whether this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}
