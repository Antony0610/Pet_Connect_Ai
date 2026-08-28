import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// App-wide **Notification Service**
///
/// Dispatches local push notifications for:
/// - Community post likes and comments
/// - Smart Collar Geofence exit/breach warnings
/// - Medication & Vaccination reminders
/// - Clinic Appointment confirmations
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
        },
      );
      _initialized = true;
    } catch (_) {
      // Gracefully continue in test/mock environments
    }
  }

  /// Dispatches an immediate high-priority notification to the system tray.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isUrgent = false,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      isUrgent ? 'petconnect_urgent_channel' : 'petconnect_general_channel',
      isUrgent ? 'Urgent Pet Alerts' : 'General Notifications',
      channelDescription: isUrgent
          ? 'Critical geofence breach and emergency health alerts'
          : 'Community activity, appointments, and care reminders',
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.high : Priority.defaultPriority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (_) {}
  }

  /// Triggers a Community Like Notification
  Future<void> showCommunityLikeNotification({
    required String authorName,
    required String postTitle,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await showNotification(
      id: id,
      title: '❤️ New Like on your post',
      body: '$authorName liked "$postTitle"',
    );
  }

  /// Triggers a Community Comment Notification
  Future<void> showCommunityCommentNotification({
    required String commenterName,
    required String commentSnippet,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await showNotification(
      id: id,
      title: '💬 New Reply from $commenterName',
      body: commentSnippet,
    );
  }

  /// Triggers a Smart Collar Geofence Exit Alarm Notification
  Future<void> showGeofenceBreachAlarm({
    required String petName,
    required String zoneName,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await showNotification(
      id: id,
      title: '🚨 SAFE ZONE BREACH: $petName',
      body: '$petName has wandered outside $zoneName! Open live GPS radar to track.',
      isUrgent: true,
    );
  }

  /// Triggers a Medication / Vaccine Reminder
  Future<void> showCareReminder({
    required String petName,
    required String reminderTitle,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await showNotification(
      id: id,
      title: '💊 Care Reminder for $petName',
      body: reminderTitle,
    );
  }
}
